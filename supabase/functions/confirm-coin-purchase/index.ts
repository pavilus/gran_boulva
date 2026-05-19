import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

type ConfirmBody = {
  payment_intent_id?: string;
  client_secret?: string;
};

function paymentIntentIdFromSecret(secret: string) {
  const match = secret.match(/^(pi_[^_]+)_secret_/);
  return match?.[1] ?? "";
}

async function getUser(req: Request, supabaseUrl: string, anonKey: string) {
  const authorization = req.headers.get("Authorization") ?? "";
  const res = await fetch(`${supabaseUrl}/auth/v1/user`, {
    headers: {
      apikey: anonKey,
      Authorization: authorization,
    },
  });

  if (!res.ok) return null;
  return await res.json();
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const stripeSecretKey = Deno.env.get("STRIPE_SECRET_KEY") ?? "";

    if (!supabaseUrl || !anonKey || !serviceRoleKey || !stripeSecretKey) {
      return Response.json(
        { error: "Missing Supabase or Stripe function secrets" },
        { status: 500, headers: corsHeaders },
      );
    }

    const user = await getUser(req, supabaseUrl, anonKey);
    if (!user?.id) {
      return Response.json(
        { error: "Not authenticated" },
        { status: 401, headers: corsHeaders },
      );
    }

    const body = (await req.json()) as ConfirmBody;
    const paymentIntentId =
      body.payment_intent_id ?? paymentIntentIdFromSecret(body.client_secret ?? "");
    if (!paymentIntentId) {
      return Response.json(
        { error: "Missing payment intent id" },
        { status: 400, headers: corsHeaders },
      );
    }

    const stripeRes = await fetch(
      `https://api.stripe.com/v1/payment_intents/${paymentIntentId}`,
      {
        headers: { Authorization: `Bearer ${stripeSecretKey}` },
      },
    );
    const paymentIntent = await stripeRes.json();
    if (!stripeRes.ok) {
      return Response.json(
        { error: paymentIntent?.error?.message ?? "Stripe lookup failed" },
        { status: 400, headers: corsHeaders },
      );
    }

    if (paymentIntent.status !== "succeeded") {
      return Response.json(
        { error: `Payment is ${paymentIntent.status}` },
        { status: 400, headers: corsHeaders },
      );
    }

    const metadata = paymentIntent.metadata ?? {};
    if (metadata.user_id !== user.id) {
      return Response.json(
        { error: "Payment does not belong to this user" },
        { status: 403, headers: corsHeaders },
      );
    }

    const coinAmount = Number(metadata.coin_amount ?? 0);
    const usdCents = Number(metadata.usd_cents ?? paymentIntent.amount ?? 0);
    if (!Number.isInteger(coinAmount) || coinAmount <= 0) {
      return Response.json(
        { error: "Payment is missing coin metadata" },
        { status: 400, headers: corsHeaders },
      );
    }

    // Service role client for coin_purchases / coin_transactions
    const admin = createClient(supabaseUrl, serviceRoleKey);
    const { data: existing } = await admin
      .from("coin_purchases")
      .select("status")
      .eq("stripe_payment_id", paymentIntentId)
      .maybeSingle();

    if (existing?.status === "completed") {
      return Response.json(
        { success: true, credited: false, coin_amount: coinAmount },
        { headers: corsHeaders },
      );
    }

    const { data: profile, error: profileError } = await admin
      .from("users")
      .select("id, coin_balance")
      .eq("auth_user_id", user.id)
      .single();
    if (profileError) throw profileError;

    const internalUserId = profile.id;
    const currentBalance = Number(profile?.coin_balance ?? 0);
    const newBalance = currentBalance + coinAmount;

    const { error: updateError } = await admin
      .from("users")
      .update({ coin_balance: newBalance })
      .eq("auth_user_id", user.id);
    if (updateError) throw updateError;

    await admin.from("coin_transactions").insert({
      to_user_id: internalUserId,
      amount: coinAmount,
      fee: 0,
      transaction_type: "purchase",
      status: "completed",
    });

    await admin.from("coin_purchases").upsert(
      {
        user_id: user.id,
        coin_amount: coinAmount,
        usd_cents: usdCents,
        stripe_payment_id: paymentIntentId,
        status: "completed",
      },
      { onConflict: "stripe_payment_id" },
    );

    return Response.json(
      {
        success: true,
        credited: true,
        coin_amount: coinAmount,
        coin_balance: newBalance,
      },
      { headers: corsHeaders },
    );
  } catch (error) {
    const message = error instanceof Error
      ? error.message
      : (error && typeof error === "object" && "message" in error)
      ? String((error as Record<string, unknown>).message)
      : JSON.stringify(error);
    return Response.json(
      { error: message },
      { status: 500, headers: corsHeaders },
    );
  }
});
