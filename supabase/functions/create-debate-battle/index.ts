// ============================================================
// create-debate-battle
// ============================================================
// Called by the challenger to initiate a debate battle.
//
// Validates:
//   - Challenger is authenticated
//   - Mode is valid ('rapid_fire' | 'full_debate')
//   - Challenger has the required creator tier
//       rapid_fire  → tier >= 1
//       full_debate → tier >= 2
//   - Opponent exists and is not the challenger
//   - Opponent has the required creator tier (early feedback)
//   - Challenger has enough coins for the entry fee
//
// On success:
//   - Deducts entry fee from challenger's coin_balance (locked)
//   - Creates a coin_transaction row (type: 'battle_entry_lock')
//   - Inserts debate_battles row (status: 'pending')
//   - Inserts a notification for the opponent
//   - Returns { battle_id, agora_channel, status: 'pending' }
// ============================================================

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

type CreateBattleBody = {
  opponent_id?: string;    // internal users.id of the opponent
  mode?: string;           // 'rapid_fire' | 'full_debate'
  topic?: string;          // debate topic
  entry_fee_coins?: number; // coins each side locks in (0 = free)
};

const TIER_GATE: Record<string, number> = {
  rapid_fire: 1,
  full_debate: 2,
};

// Resolve the Supabase auth user to an internal users row + creator_profile.
async function getInternalUser(
  admin: ReturnType<typeof createClient>,
  authUserId: string,
) {
  const { data, error } = await admin
    .from("users")
    .select(`
      id,
      username,
      full_name,
      coin_balance,
      creator_profiles ( creator_tier )
    `)
    .eq("auth_user_id", authUserId)
    .single();

  if (error) throw new Error(`User lookup failed: ${error.message}`);
  return data;
}

// Fetch the auth user from the Authorization header.
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

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // ── Env ───────────────────────────────────────────────
    const supabaseUrl      = Deno.env.get("SUPABASE_URL")           ?? "";
    const anonKey          = Deno.env.get("SUPABASE_ANON_KEY")      ?? "";
    const serviceRoleKey   = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    if (!supabaseUrl || !anonKey || !serviceRoleKey) {
      return Response.json(
        { error: "Missing Supabase secrets" },
        { status: 500, headers: corsHeaders },
      );
    }

    // ── Auth ──────────────────────────────────────────────
    const authUser = await getAuthUser(req, supabaseUrl, anonKey);
    if (!authUser?.id) {
      return Response.json(
        { error: "Not authenticated" },
        { status: 401, headers: corsHeaders },
      );
    }

    const admin = createClient(supabaseUrl, serviceRoleKey);

    // ── Parse body ────────────────────────────────────────
    const body = (await req.json()) as CreateBattleBody;
    const { opponent_id, mode, topic, entry_fee_coins: rawFee } = body;
    const entryFee = Number(rawFee ?? 0);

    if (!mode || !TIER_GATE[mode]) {
      return Response.json(
        { error: "mode must be 'rapid_fire' or 'full_debate'" },
        { status: 400, headers: corsHeaders },
      );
    }
    if (!topic || topic.trim().length === 0) {
      return Response.json(
        { error: "topic is required" },
        { status: 400, headers: corsHeaders },
      );
    }
    if (topic.trim().length > 200) {
      return Response.json(
        { error: "topic must be 200 characters or fewer" },
        { status: 400, headers: corsHeaders },
      );
    }
    if (!Number.isInteger(entryFee) || entryFee < 0) {
      return Response.json(
        { error: "entry_fee_coins must be a non-negative integer" },
        { status: 400, headers: corsHeaders },
      );
    }
    if (entryFee > 10000) {
      return Response.json(
        { error: "entry_fee_coins cannot exceed 10,000" },
        { status: 400, headers: corsHeaders },
      );
    }
    if (!opponent_id) {
      return Response.json(
        { error: "opponent_id is required" },
        { status: 400, headers: corsHeaders },
      );
    }

    // ── Fetch challenger ──────────────────────────────────
    const challenger = await getInternalUser(admin, authUser.id);
    const requiredTier = TIER_GATE[mode];

    // Tier gate — challenger side
    // creator_profiles is a 1-to-1 join; Supabase returns it as an object.
    const challengerTier =
      // deno-lint-ignore no-explicit-any
      (challenger.creator_profiles as any)?.creator_tier ?? 0;

    if (challengerTier < requiredTier) {
      const tierName = requiredTier === 1 ? "Kreyatè Entèmedyè (Tier 1)" : "Kreyatè Verifye (Tier 2)";
      return Response.json(
        {
          error: `${mode === "rapid_fire" ? "Rapid Fire" : "Full Debate"} requires ${tierName}. Your current tier is ${challengerTier}.`,
          required_tier: requiredTier,
          current_tier: challengerTier,
        },
        { status: 403, headers: corsHeaders },
      );
    }

    // ── Validate opponent ─────────────────────────────────
    if (opponent_id === challenger.id) {
      return Response.json(
        { error: "You cannot challenge yourself" },
        { status: 400, headers: corsHeaders },
      );
    }

    const { data: opponent, error: opponentError } = await admin
      .from("users")
      .select(`
        id,
        username,
        full_name,
        creator_profiles ( creator_tier )
      `)
      .eq("id", opponent_id)
      .single();

    if (opponentError || !opponent) {
      return Response.json(
        { error: "Opponent not found" },
        { status: 404, headers: corsHeaders },
      );
    }

    // Tier gate — opponent side (early feedback; enforced again at accept)
    // deno-lint-ignore no-explicit-any
    const opponentTier = (opponent.creator_profiles as any)?.creator_tier ?? 0;
    if (opponentTier < requiredTier) {
      const tierName = requiredTier === 1 ? "Kreyatè Entèmedyè (Tier 1)" : "Kreyatè Verifye (Tier 2)";
      return Response.json(
        {
          error: `Opponent does not meet the required creator tier for this mode. They need ${tierName}.`,
          required_tier: requiredTier,
          opponent_tier: opponentTier,
        },
        { status: 403, headers: corsHeaders },
      );
    }

    // ── Entry fee — deduct from challenger (atomic) ───────
    if (entryFee > 0) {
      const { data: locked, error: lockErr } = await admin
        .rpc("lock_coins_for_battle", { p_user_id: challenger.id, p_amount: entryFee });
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
        from_user_id: challenger.id,
        amount: entryFee,
        fee: 0,
        transaction_type: "battle_entry_lock",
        status: "completed",
      });
    }

    // ── Create battle ─────────────────────────────────────
    const battleId     = crypto.randomUUID();
    const agoraChannel = `battle-${battleId}`;

    const { error: insertError } = await admin
      .from("debate_battles")
      .insert({
        id:              battleId,
        challenger_id:   challenger.id,
        opponent_id:     opponent.id,
        mode,
        topic:           topic.trim(),
        entry_fee_coins: entryFee,
        prize_pool_coins: entryFee,   // opponent's share added at accept-debate-battle
        status:          "pending",
        agora_channel:   agoraChannel,
      });

    if (insertError) {
      // Refund challenger if battle insert fails after deduction
      if (entryFee > 0) {
        await admin.rpc("credit_coins", { p_user_id: challenger.id, p_amount: entryFee });
      }
      throw new Error(`Battle insert failed: ${insertError.message}`);
    }

    // ── Notify opponent ───────────────────────────────────
    const challengerName = challenger.full_name || challenger.username || "Yon moun";
    const modeLabel      = mode === "rapid_fire" ? "⚡ Rapid Fire" : "🎙️ Full Debate";
    await admin.from("notifications").insert({
      user_id:       opponent.id,
      type:          "battle_challenge",
      message:       `${challengerName} defye ou pou yon ${modeLabel} batay debat! Sijè: "${topic.trim()}"`,
      related_table: "debate_battles",
      related_id:    battleId,
    });

    // ── Response ──────────────────────────────────────────
    return Response.json(
      {
        battle_id:     battleId,
        agora_channel: agoraChannel,
        status:        "pending",
        entry_fee_locked: entryFee,
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
