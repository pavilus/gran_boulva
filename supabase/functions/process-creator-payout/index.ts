// process-creator-payout
// Called by the admin when approving a creator payout.
// Behaviour:
//   - payoutMode = "manual"        → marks payout processed=false, returns { manual: true }
//   - payoutMode = "moncash_auto"  → calls MonCash Transfer API, updates status automatically
//
// Expected request body: { payoutId: string }
// Requires service-role call (admin only).

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const MONCASH_CLIENT_ID = Deno.env.get("MONCASH_CLIENT_ID") ?? "";
const MONCASH_CLIENT_SECRET = Deno.env.get("MONCASH_CLIENT_SECRET") ?? "";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// MonCash base URLs
function moncashBase(env: string) {
  return env === "live"
    ? "https://moncashbutton.digicelgroup.com"
    : "https://sandbox.moncashbutton.digicelgroup.com";
}

async function getMoncashToken(env: string): Promise<string> {
  const base = moncashBase(env);
  const credentials = btoa(`${MONCASH_CLIENT_ID}:${MONCASH_CLIENT_SECRET}`);

  const res = await fetch(`${base}/Api/oauth/token`, {
    method: "POST",
    headers: {
      "Authorization": `Basic ${credentials}`,
      "Content-Type": "application/x-www-form-urlencoded",
      "Accept": "application/json",
    },
    body: "grant_type=client_credentials&scope=read,write",
  });

  if (!res.ok) {
    const text = await res.text();
    throw new Error(`MonCash auth failed: ${res.status} — ${text}`);
  }

  const data = await res.json();
  return data.access_token;
}

async function moncashTransfer(
  env: string,
  token: string,
  phone: string,
  amount: number,   // in USD
  description: string,
  transactionId: string,
): Promise<string> {
  const base = moncashBase(env);

  const res = await fetch(`${base}/Api/v1/TransferWithReferenceID`, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${token}`,
      "Content-Type": "application/json",
      "Accept": "application/json",
    },
    body: JSON.stringify({
      amount,
      receiver: phone,
      desc: description,
      transactionId,
    }),
  });

  if (!res.ok) {
    const text = await res.text();
    throw new Error(`MonCash transfer failed: ${res.status} — ${text}`);
  }

  const data = await res.json();
  // MonCash returns { transfer: { transactionId, ... } }
  return data?.transfer?.transactionId ?? data?.transactionId ?? transactionId;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);
  const now = new Date().toISOString();

  try {
    const { payoutId } = await req.json();
    if (!payoutId) throw new Error("payoutId required");

    // ── Load payout row ──────────────────────────────────────
    const { data: payout, error: payoutErr } = await supabase
      .from("creator_payouts")
      .select("*")
      .eq("id", payoutId)
      .single();

    if (payoutErr || !payout) throw new Error("Payout not found");
    if (payout.status !== "pending") {
      return new Response(JSON.stringify({ ok: false, reason: "not_pending" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // ── Load payout settings ─────────────────────────────────
    const { data: settingsRow } = await supabase
      .from("app_settings")
      .select("value")
      .eq("key", "payout_settings")
      .single();

    const settings = settingsRow?.value ?? {};
    const payoutMode: string = settings.payoutMode ?? "manual";
    const moncashEnv: string = settings.moncashEnvironment ?? "sandbox";
    const moncashEnabled: boolean = settings.moncashEnabled ?? false;
    const coinToUsdRate: number = settings.coinToUsdRate ?? 0.001;

    // ── Manual mode ──────────────────────────────────────────
    if (payoutMode === "manual" || !moncashEnabled) {
      return new Response(
        JSON.stringify({ ok: true, manual: true, message: "Manual mode — process outside the app." }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // ── MonCash auto mode ────────────────────────────────────
    if (!MONCASH_CLIENT_ID || !MONCASH_CLIENT_SECRET) {
      throw new Error("MonCash credentials not configured in Supabase secrets.");
    }

    const phone = payout.payout_phone;
    if (!phone) throw new Error("No phone number on payout request.");

    const usdAmount = payout.estimated_usd ?? (payout.coins_amount * coinToUsdRate);
    const description = `Gran Boulva kreye revni peman — ${payout.coins_amount} monè`;
    const transactionId = `gbpayout_${payoutId}`;

    // Get MonCash token
    const token = await getMoncashToken(moncashEnv);

    // Execute transfer
    const moncashRef = await moncashTransfer(
      moncashEnv,
      token,
      phone,
      usdAmount,
      description,
      transactionId,
    );

    // ── Update payout as completed ───────────────────────────
    await supabase
      .from("creator_payouts")
      .update({
        status: "completed",
        moncash_reference: moncashRef,
        auto_processed: true,
        processed_at: now,
      })
      .eq("id", payoutId);

    // ── Deduct from creator pending balance ──────────────────
    const { data: profile } = await supabase
      .from("creator_profiles")
      .select("pending_payout_coins, total_paid_out_coins")
      .eq("user_id", payout.creator_user_id)
      .single();

    if (profile) {
      await supabase
        .from("creator_profiles")
        .update({
          pending_payout_coins: Math.max(0, (profile.pending_payout_coins ?? 0) - payout.coins_amount),
          total_paid_out_coins: (profile.total_paid_out_coins ?? 0) + payout.coins_amount,
          updated_at: now,
        })
        .eq("user_id", payout.creator_user_id);
    }

    // ── Notify creator ───────────────────────────────────────
    await supabase.from("notifications").insert({
      user_id: payout.creator_user_id,
      type: "system",
      title: "Peman voye!",
      body: `$${usdAmount.toFixed(2)} USD voye bay ${phone} via MonCash. Ref: ${moncashRef}`,
    });

    return new Response(
      JSON.stringify({ ok: true, moncashRef, usdAmount }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    console.error("process-creator-payout error:", message);

    return new Response(
      JSON.stringify({ ok: false, error: message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});
