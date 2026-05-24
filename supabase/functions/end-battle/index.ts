// ============================================================
// end-battle
// ============================================================
// Called when the battle timer expires OR an admin force-ends a battle.
// Intended to be called server-side (by pg_cron or a trusted client).
// The calling client must supply a valid JWT; admin/service_role bypasses tier checks.
//
// Flow:
//   1. Stop Agora Cloud Recording → get S3 recording URL
//   2. Open 30-second audience winner vote (status: 'voting')
//   3. Broadcast Realtime event: 'audience_vote_open'
//   [ 30 seconds pass — handled by another pg_cron tick or client callback ]
//   4. Tally audience votes → determine winner
//   5. Distribute prize pool (winner 90% | platform 10%)
//   6. Record badge events for both debaters (victory / participation)
//   7. Call refresh_creator_tier() for both
//   8. Save recording URL + expiry (24 h), mark status 'completed'
//   9. Post a feed notification card
//  10. Notify both debaters
//
// The vote tallying step (4–10) is triggered by calling end-battle a second time
// with action: 'tally' after the 30-second window closes.
// First call (action: 'stop'): stops recording, opens vote window.
// Second call (action: 'tally'): tallies votes, distributes rewards.
// ============================================================

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

type EndBattleBody = {
  battle_id?: string;
  action?: "stop" | "tally";  // "stop" ends recording + opens vote; "tally" finalizes
};

const AGORA_API = "https://api.agora.io/v1/apps";
const PLATFORM_CUT = 0.10;   // 10% platform fee
const WINNER_SHARE  = 0.90;  // 90% to winner

// Auth helper — allows service_role calls (no Authorization header needed)
async function getAuthUser(
  req: Request,
  supabaseUrl: string,
  anonKey: string,
) {
  const authorization = req.headers.get("Authorization") ?? "";
  if (!authorization) return null;
  const res = await fetch(`${supabaseUrl}/auth/v1/user`, {
    headers: { apikey: anonKey, Authorization: authorization },
  });
  if (!res.ok) return null;
  return await res.json();
}

// ── Stop Agora recording ──────────────────────────────────
async function stopAgoraRecording(
  agoraAppId: string,
  agoraAuth: string,
  channel: string,
  resourceSid: string,   // "resourceId:sid" packed from recording_url placeholder
): Promise<string | null> {
  const [resourceId, sid] = resourceSid.split(":");
  if (!resourceId || !sid) return null;

  const stopRes = await fetch(
    `${AGORA_API}/${agoraAppId}/cloud_recording/resourceid/${resourceId}/sid/${sid}/mode/mix/stop`,
    {
      method: "POST",
      headers: {
        Authorization: agoraAuth,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        cname:         channel,
        uid:           "0",
        clientRequest: {},
      }),
    },
  );

  if (!stopRes.ok) {
    console.error(`[end-battle] Agora stop failed (${stopRes.status}):`, await stopRes.text());
    return null;
  }

  // Agora returns the S3 key prefix; we construct the .m3u8 URL
  const result      = await stopRes.json();
  const fileList    = result?.serverResponse?.fileList ?? [];
  const m3u8File    = fileList.find((f: { fileName?: string }) => f.fileName?.endsWith(".m3u8"));
  if (!m3u8File?.fileName) return null;

  const s3Bucket = Deno.env.get("AWS_S3_BUCKET") ?? "gran-boulva-battle-recordings";
  const s3Region = Deno.env.get("AWS_S3_REGION") ?? "us-east-1";
  return `https://${s3Bucket}.s3.${s3Region}.amazonaws.com/${m3u8File.fileName}`;
}

// ─────────────────────────────────────────────────────────
serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // ── Env ─────────────────────────────────────────────
    const supabaseUrl      = Deno.env.get("SUPABASE_URL")              ?? "";
    const anonKey          = Deno.env.get("SUPABASE_ANON_KEY")         ?? "";
    const serviceRoleKey   = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const agoraAppId       = Deno.env.get("AGORA_APP_ID")              ?? "";
    const agoraCustomerKey = Deno.env.get("AGORA_CUSTOMER_KEY")        ?? "";
    const agoraCustomerSec = Deno.env.get("AGORA_CUSTOMER_SECRET")     ?? "";

    if (!supabaseUrl || !serviceRoleKey) {
      return Response.json(
        { error: "Missing Supabase secrets" },
        { status: 500, headers: corsHeaders },
      );
    }

    // ── Auth — require authenticated user OR service_role key ─
    // pg_cron / internal calls pass serviceRoleKey as Bearer token.
    // Anonymous callers (no valid token) are rejected.
    const authUser    = await getAuthUser(req, supabaseUrl, anonKey);
    const callerToken = req.headers.get("Authorization")?.replace(/^Bearer\s+/i, "") ?? "";
    const isServiceRole = callerToken === serviceRoleKey;

    if (!authUser && !isServiceRole) {
      return Response.json(
        { error: "Unauthorized" },
        { status: 401, headers: corsHeaders },
      );
    }

    const admin = createClient(supabaseUrl, serviceRoleKey);

    // ── Parse body ────────────────────────────────────────
    const body = (await req.json()) as EndBattleBody;
    const { battle_id, action = "stop" } = body;

    if (!battle_id) {
      return Response.json(
        { error: "battle_id is required" },
        { status: 400, headers: corsHeaders },
      );
    }

    // ── Fetch battle ──────────────────────────────────────
    const { data: battle, error: battleErr } = await admin
      .from("debate_battles")
      .select(`
        id, challenger_id, opponent_id, mode,
        status, agora_channel, recording_url,
        entry_fee_coins, prize_pool_coins, audience_vote_open
      `)
      .eq("id", battle_id)
      .single();

    if (battleErr || !battle) {
      return Response.json(
        { error: "Battle not found" },
        { status: 404, headers: corsHeaders },
      );
    }

    // ══════════════════════════════════════════════════════
    // ACTION: stop — end recording + open audience vote
    // ══════════════════════════════════════════════════════
    if (action === "stop") {
      if (battle.status !== "live") {
        return Response.json(
          { error: `Cannot stop battle from status '${battle.status}'` },
          { status: 409, headers: corsHeaders },
        );
      }

      // Stop Agora recording
      let recordingUrl: string | null = null;
      if (
        agoraAppId && agoraCustomerKey && agoraCustomerSec &&
        battle.agora_channel && battle.recording_url?.startsWith("agora:")
      ) {
        const agoraAuth  = "Basic " + btoa(`${agoraCustomerKey}:${agoraCustomerSec}`);
        const resourceSid = battle.recording_url.replace("agora:", "");
        recordingUrl = await stopAgoraRecording(
          agoraAppId,
          agoraAuth,
          battle.agora_channel,
          resourceSid,
        );
      }

      const recordingExpiry = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString();

      // Open audience vote window
      await admin
        .from("debate_battles")
        .update({
          status:               "voting",
          audience_vote_open:   true,
          recording_url:        recordingUrl,
          recording_expires_at: recordingExpiry,
          ended_at:             new Date().toISOString(),
        })
        .eq("id", battle_id);

      return Response.json(
        {
          battle_id,
          status:         "voting",
          recording_url:  recordingUrl,
          recording_expires_at: recordingExpiry,
          message:        "30-second audience vote is open. Call end-battle with action:'tally' to finalize.",
        },
        { headers: corsHeaders },
      );
    }

    // ══════════════════════════════════════════════════════
    // ACTION: tally — count votes, pay out, award badges
    // ══════════════════════════════════════════════════════
    if (action === "tally") {
      if (battle.status !== "voting") {
        return Response.json(
          { error: `Cannot tally from status '${battle.status}'` },
          { status: 409, headers: corsHeaders },
        );
      }

      // Count audience votes
      const { data: votes } = await admin
        .from("battle_audience_votes")
        .select("vote_for")
        .eq("battle_id", battle_id);

      const votesArr = votes ?? [];
      const challengerVotes = votesArr.filter((v) => v.vote_for === "challenger").length;
      const opponentVotes   = votesArr.filter((v) => v.vote_for === "opponent").length;

      // Winner = most votes; tie → challenger wins (first mover advantage)
      const winnerRole  = opponentVotes > challengerVotes ? "opponent" : "challenger";
      const winnerId    = winnerRole === "challenger" ? battle.challenger_id : battle.opponent_id;
      const loserId     = winnerRole === "challenger" ? battle.opponent_id  : battle.challenger_id;

      // Distribute prize pool
      const pool          = Number(battle.prize_pool_coins ?? 0);
      const winnerCoins   = Math.floor(pool * WINNER_SHARE);
      const platformCoins = pool - winnerCoins;

      if (winnerCoins > 0) {
        // Credit winner (atomic — prevents read-modify-write race)
        await admin.rpc("credit_coins", { p_user_id: winnerId, p_amount: winnerCoins });

        await admin.from("coin_transactions").insert({
          to_user_id:       winnerId,
          amount:           winnerCoins,
          fee:              platformCoins,
          transaction_type: "battle_prize",
          status:           "completed",
        });
      }

      // Update victory / participation counters on users table
      await admin
        .from("users")
        .update({ victory_count:      admin.rpc("users.victory_count + 1") })  // direct increment via RPC
        .eq("id", winnerId);
      // Fallback: raw increment via select+update
      const { data: wData } = await admin.from("users").select("victory_count, participation_count").eq("id", winnerId).single();
      const { data: lData } = await admin.from("users").select("participation_count").eq("id", loserId).single();

      await admin.from("users").update({
        victory_count:       (Number(wData?.victory_count ?? 0) + 1),
        participation_count: (Number(wData?.participation_count ?? 0) + 1),
      }).eq("id", winnerId);

      await admin.from("users").update({
        participation_count: (Number(lData?.participation_count ?? 0) + 1),
      }).eq("id", loserId);

      // Award badge events
      await admin.rpc("record_badge_event", { p_user_id: winnerId, p_event_type: "debate_victory" });
      await admin.rpc("record_badge_event", { p_user_id: loserId,  p_event_type: "debate_participation" });

      // Refresh creator tiers for both
      await admin.rpc("refresh_creator_tier", { p_user_id: winnerId });
      await admin.rpc("refresh_creator_tier", { p_user_id: loserId });

      // Mark battle completed
      await admin
        .from("debate_battles")
        .update({
          status:             "completed",
          winner_id:          winnerId,
          audience_vote_open: false,
        })
        .eq("id", battle_id);

      // Notify both debaters
      const [winnerInfo, loserInfo] = await Promise.all([
        admin.from("users").select("full_name, username").eq("id", winnerId).single(),
        admin.from("users").select("full_name, username").eq("id", loserId).single(),
      ]);
      const winnerName = winnerInfo.data?.full_name || winnerInfo.data?.username || "Gayan an";
      const loserName  = loserInfo.data?.full_name  || loserInfo.data?.username  || "Pèdan an";

      await Promise.all([
        admin.from("notifications").insert({
          user_id:       winnerId,
          type:          "battle_victory",
          message:       `🏆 Ou genyen batay debat la! Ou resevwa ${winnerCoins.toLocaleString()} pyès.`,
          related_table: "debate_battles",
          related_id:    battle_id,
        }),
        admin.from("notifications").insert({
          user_id:       loserId,
          type:          "battle_defeat",
          message:       `${winnerName} genyen batay debat la. Kenbe la — patisipasyon ou konte toujou!`,
          related_table: "debate_battles",
          related_id:    battle_id,
        }),
      ]);

      return Response.json(
        {
          battle_id,
          status:          "completed",
          winner_id:       winnerId,
          winner_role:     winnerRole,
          challenger_votes: challengerVotes,
          opponent_votes:   opponentVotes,
          prize_distributed: winnerCoins,
          platform_cut:     platformCoins,
        },
        { headers: corsHeaders },
      );
    }

    return Response.json(
      { error: "action must be 'stop' or 'tally'" },
      { status: 400, headers: corsHeaders },
    );
  } catch (error) {
    const message = error instanceof Error
      ? error.message
      : JSON.stringify(error);
    return Response.json(
      { error: message },
      { status: 500, headers: corsHeaders },
    );
  }
});
