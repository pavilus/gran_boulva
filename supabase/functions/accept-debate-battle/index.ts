// ============================================================
// accept-debate-battle
// ============================================================
// Called by the opponent after receiving a battle challenge.
// Can also be used to decline (action: 'decline').
//
// On accept:
//   - Re-validates opponent's creator tier (server-side enforcement)
//   - Deducts entry fee from opponent's coin_balance (if > 0)
//   - Updates prize_pool_coins to entry_fee * 2
//   - Generates Agora RTC tokens for both debaters (UID 1 = challenger, UID 2 = opponent)
//   - Updates battle status to 'lobby'
//   - Notifies challenger
//
// On decline:
//   - Updates battle status to 'cancelled' (reason: 'opponent_declined')
//   - Refunds challenger entry fee (if > 0)
//   - Notifies challenger
//
// Agora token generation uses HMAC-SHA256 per the Agora Access Token 2 spec.
// Required secrets: AGORA_APP_ID, AGORA_APP_CERTIFICATE
// ============================================================

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { createHmac } from "https://deno.land/std@0.224.0/crypto/mod.ts";
import { encodeBase64 } from "https://deno.land/std@0.224.0/encoding/base64.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

type AcceptBody = {
  battle_id?: string;
  action?: "accept" | "decline";
};

const TIER_GATE: Record<string, number> = {
  rapid_fire: 1,
  full_debate: 2,
};

// ── Agora Access Token 2 (RTC) ────────────────────────────
// Docs: https://docs.agora.io/en/video-calling/get-started/authentication-workflow
// Privilege: ROLE_PUBLISHER = 1 (can publish + subscribe)
// Token expires in 1 hour; battle max duration is ~12 min + buffer.
const PRIVILEGE_PUBLISHER   = 1;
const PRIVILEGE_SUBSCRIBER  = 2;
const TOKEN_EXPIRY_SECONDS  = 3600; // 1 hour

function packUint16LE(v: number): Uint8Array {
  const buf = new Uint8Array(2);
  buf[0] = v & 0xff;
  buf[1] = (v >> 8) & 0xff;
  return buf;
}
function packUint32LE(v: number): Uint8Array {
  const buf = new Uint8Array(4);
  buf[0] = v & 0xff;
  buf[1] = (v >> 8) & 0xff;
  buf[2] = (v >> 16) & 0xff;
  buf[3] = (v >> 24) & 0xff;
  return buf;
}
function concat(...arrays: Uint8Array[]): Uint8Array {
  const total = arrays.reduce((s, a) => s + a.length, 0);
  const out   = new Uint8Array(total);
  let offset  = 0;
  for (const a of arrays) { out.set(a, offset); offset += a.length; }
  return out;
}
function packString(s: string): Uint8Array {
  const enc = new TextEncoder().encode(s);
  return concat(packUint16LE(enc.length), enc);
}

async function generateAgoraToken(
  appId: string,
  appCertificate: string,
  channelName: string,
  uid: number,         // 1 = challenger, 2 = opponent
  role: number,        // PRIVILEGE_PUBLISHER | PRIVILEGE_SUBSCRIBER
): Promise<string> {
  const nowSeconds      = Math.floor(Date.now() / 1000);
  const expireSeconds   = nowSeconds + TOKEN_EXPIRY_SECONDS;
  const salt            = Math.floor(Math.random() * 0xffffffff);

  // Privileges map: privilege → expiry
  const privileges: [number, number][] = [
    [role,                 expireSeconds],
    [PRIVILEGE_SUBSCRIBER, expireSeconds],
  ];
  // Deduplicate (publisher role already includes subscribe)
  const privMap = new Map<number, number>();
  privMap.set(PRIVILEGE_PUBLISHER,  expireSeconds);
  privMap.set(PRIVILEGE_SUBSCRIBER, expireSeconds);

  // Pack privilege map
  let privBytes = packUint16LE(privMap.size);
  for (const [key, val] of privMap.entries()) {
    privBytes = concat(privBytes, packUint16LE(key), packUint32LE(val));
  }

  // Build message content
  const content = concat(
    packUint16LE(1),           // version = 1
    packString(appId),
    packString(channelName),
    packUint32LE(uid),
    packUint32LE(salt),
    packUint32LE(nowSeconds),
    privBytes,
  );

  // HMAC-SHA256 signature
  const key   = new TextEncoder().encode(appCertificate);
  const hmac  = createHmac("sha256", key);
  hmac.update(content);
  const sig = await hmac.arrayBuffer();

  const token = concat(
    content,
    packUint16LE(32),          // signature length (SHA256 = 32 bytes)
    new Uint8Array(sig),
  );

  return "006" + appId + encodeBase64(token);
}

// ── Auth helper ───────────────────────────────────────────
async function getAuthUser(
  req: Request,
  supabaseUrl: string,
  anonKey: string,
) {
  const authorization = req.headers.get("Authorization") ?? "";
  const res = await fetch(`${supabaseUrl}/auth/v1/user`, {
    headers: { apikey: anonKey, Authorization: authorization },
  });
  if (!res.ok) return null;
  return await res.json();
}

// ── Refund helper (atomic) ────────────────────────────────
async function refundEntryFee(
  admin: ReturnType<typeof createClient>,
  userId: string,
  coins: number,
) {
  if (coins <= 0) return;
  await admin.rpc("credit_coins", { p_user_id: userId, p_amount: coins });
  await admin.from("coin_transactions").insert({
    to_user_id:       userId,
    amount:           coins,
    fee:              0,
    transaction_type: "battle_entry_refund",
    status:           "completed",
  });
}

// ─────────────────────────────────────────────────────────
serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // ── Env ─────────────────────────────────────────────
    const supabaseUrl    = Deno.env.get("SUPABASE_URL")              ?? "";
    const anonKey        = Deno.env.get("SUPABASE_ANON_KEY")         ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const agoraAppId     = Deno.env.get("AGORA_APP_ID")              ?? "";
    const agoraCert      = Deno.env.get("AGORA_APP_CERTIFICATE")     ?? "";

    if (!supabaseUrl || !anonKey || !serviceRoleKey) {
      return Response.json(
        { error: "Missing Supabase secrets" },
        { status: 500, headers: corsHeaders },
      );
    }

    // ── Auth ─────────────────────────────────────────────
    const authUser = await getAuthUser(req, supabaseUrl, anonKey);
    if (!authUser?.id) {
      return Response.json(
        { error: "Not authenticated" },
        { status: 401, headers: corsHeaders },
      );
    }

    const admin = createClient(supabaseUrl, serviceRoleKey);

    // ── Resolve internal user ─────────────────────────────
    const { data: opponentUser, error: opErr } = await admin
      .from("users")
      .select(`
        id,
        username,
        full_name,
        coin_balance,
        creator_profiles ( creator_tier )
      `)
      .eq("auth_user_id", authUser.id)
      .single();

    if (opErr || !opponentUser) {
      return Response.json(
        { error: "User not found" },
        { status: 404, headers: corsHeaders },
      );
    }

    // ── Parse body ────────────────────────────────────────
    const body = (await req.json()) as AcceptBody;
    const { battle_id, action = "accept" } = body;

    if (!battle_id) {
      return Response.json(
        { error: "battle_id is required" },
        { status: 400, headers: corsHeaders },
      );
    }
    if (action !== "accept" && action !== "decline") {
      return Response.json(
        { error: "action must be 'accept' or 'decline'" },
        { status: 400, headers: corsHeaders },
      );
    }

    // ── Fetch battle ──────────────────────────────────────
    const { data: battle, error: battleErr } = await admin
      .from("debate_battles")
      .select(`
        id, challenger_id, opponent_id, mode, topic,
        entry_fee_coins, prize_pool_coins, status, agora_channel
      `)
      .eq("id", battle_id)
      .single();

    if (battleErr || !battle) {
      return Response.json(
        { error: "Battle not found" },
        { status: 404, headers: corsHeaders },
      );
    }
    if (battle.opponent_id !== opponentUser.id) {
      return Response.json(
        { error: "You are not the opponent for this battle" },
        { status: 403, headers: corsHeaders },
      );
    }
    if (battle.status !== "pending") {
      return Response.json(
        { error: `Battle is already ${battle.status}` },
        { status: 409, headers: corsHeaders },
      );
    }

    // ── Fetch challenger info (for notifications) ─────────
    const { data: challengerUser } = await admin
      .from("users")
      .select("id, username, full_name")
      .eq("id", battle.challenger_id)
      .single();

    // ──────────────────────────────────────────────────────
    // DECLINE
    // ──────────────────────────────────────────────────────
    if (action === "decline") {
      await admin
        .from("debate_battles")
        .update({
          status:           "cancelled",
          cancelled_reason: "opponent_declined",
          ended_at:         new Date().toISOString(),
        })
        .eq("id", battle_id);

      // Refund challenger entry fee
      await refundEntryFee(admin, battle.challenger_id, Number(battle.entry_fee_coins ?? 0));

      // Notify challenger
      const opName = opponentUser.full_name || opponentUser.username || "Adversè ou";
      await admin.from("notifications").insert({
        user_id:       battle.challenger_id,
        type:          "battle_declined",
        message:       `${opName} refize batay debat la sou sijè: "${battle.topic}".`,
        related_table: "debate_battles",
        related_id:    battle_id,
      });

      return Response.json(
        { battle_id, status: "cancelled", reason: "opponent_declined" },
        { headers: corsHeaders },
      );
    }

    // ──────────────────────────────────────────────────────
    // ACCEPT
    // ──────────────────────────────────────────────────────

    // Re-validate opponent tier (server-side gate)
    const requiredTier  = battle.mode === "full_debate" ? 2 : 1;
    // deno-lint-ignore no-explicit-any
    const opponentTier  = (opponentUser.creator_profiles as any)?.creator_tier ?? 0;
    if (opponentTier < requiredTier) {
      const tierName = requiredTier === 1 ? "Kreyatè Monte (Tier 1)" : "Kreyatè Verifye (Tier 2)";
      return Response.json(
        {
          error: `You need ${tierName} to participate in this battle. Your current tier is ${opponentTier}.`,
          required_tier: requiredTier,
          current_tier:  opponentTier,
        },
        { status: 403, headers: corsHeaders },
      );
    }

    // Deduct opponent entry fee (atomic — prevents race condition)
    const entryFee = Number(battle.entry_fee_coins ?? 0);
    if (entryFee > 0) {
      const { data: locked, error: lockErr } = await admin
        .rpc("lock_coins_for_battle", { p_user_id: opponentUser.id, p_amount: entryFee });
      if (lockErr) throw new Error(`Coin lock failed: ${lockErr.message}`);
      if (!locked) {
        return Response.json(
          {
            error: "Insufficient coins for entry fee",
            required: entryFee,
          },
          { status: 402, headers: corsHeaders },
        );
      }

      await admin.from("coin_transactions").insert({
        from_user_id:     opponentUser.id,
        amount:           entryFee,
        fee:              0,
        transaction_type: "battle_entry_lock",
        status:           "completed",
      });
    }

    // Generate Agora tokens (only if Agora creds are available)
    let challengerToken: string | null = null;
    let opponentToken:   string | null = null;

    if (agoraAppId && agoraCert && battle.agora_channel) {
      challengerToken = await generateAgoraToken(
        agoraAppId,
        agoraCert,
        battle.agora_channel,
        1,  // UID 1 = challenger
        PRIVILEGE_PUBLISHER,
      );
      opponentToken = await generateAgoraToken(
        agoraAppId,
        agoraCert,
        battle.agora_channel,
        2,  // UID 2 = opponent
        PRIVILEGE_PUBLISHER,
      );
    }

    // Update battle: status → 'lobby', add tokens, update prize pool
    const { error: updateErr } = await admin
      .from("debate_battles")
      .update({
        status:                 "lobby",
        prize_pool_coins:       entryFee > 0 ? entryFee * 2 : 0,
        agora_challenger_token: challengerToken,
        agora_opponent_token:   opponentToken,
      })
      .eq("id", battle_id);

    if (updateErr) {
      // Refund opponent if update fails
      await refundEntryFee(admin, opponentUser.id, entryFee);
      throw new Error(`Battle update failed: ${updateErr.message}`);
    }

    // Notify challenger
    const opName = opponentUser.full_name || opponentUser.username || "Adversè ou";
    const modeLabel = battle.mode === "rapid_fire" ? "⚡ Rapid Fire" : "🎙️ Full Debate";
    await admin.from("notifications").insert({
      user_id:       battle.challenger_id,
      type:          "battle_accepted",
      message:       `${opName} aksepte defi ${modeLabel} ou a! Sujet: "${battle.topic}". Ale nan lobby a.`,
      related_table: "debate_battles",
      related_id:    battle_id,
    });

    return Response.json(
      {
        battle_id,
        agora_channel:     battle.agora_channel,
        challenger_token:  challengerToken,
        opponent_token:    opponentToken,
        status:            "lobby",
        prize_pool_coins:  entryFee > 0 ? entryFee * 2 : 0,
      },
      { headers: corsHeaders },
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
