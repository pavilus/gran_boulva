import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

type PurchaseBody = {
  coin_amount?: number;
  usd_amount?: number;
  usd_cents?: number;
};

type CoinPack = {
  coins?: number;
  price?: number;
};

const defaultCoinPacks = [
  { coins: 100, price: 99 },
  { coins: 250, price: 299 },
  { coins: 550, price: 499 },
  { coins: 1200, price: 999 },
  { coins: 2500, price: 1999 },
  { coins: 5000, price: 3499 },
  { coins: 10000, price: 6499 },
  { coins: 25000, price: 14999 },
];

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

async function getValidCoinPack(
  admin: ReturnType<typeof createClient> | null,
  coinAmount: number,
  usdCents: number,
) {
  let packs = defaultCoinPacks;

  if (admin) {
    const { data } = await admin
      .from("app_settings")
      .select("value")
      .eq("key", "coin_economy")
      .maybeSingle();

    const configuredPacks = data?.value?.coinPacks;
    if (Array.isArray(configuredPacks) && configuredPacks.length > 0) {
      packs = configuredPacks
        .map((pack: CoinPack) => ({
          coins: Number(pack?.coins ?? 0),
          price: Number(pack?.price ?? 0),
        }))
        .filter((pack) =>
          Number.isInteger(pack.coins) &&
          Number.isInteger(pack.price) &&
          pack.coins > 0 &&
          pack.price > 0
        );
    }
  }

  return packs.find((pack) =>
    pack.coins === coinAmount && pack.price === usdCents
  );
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    if (!supabaseUrl || !anonKey || !serviceRoleKey) {
      return Response.json(
        { error: "Missing Supabase function secrets" },
        { status: 500, headers: corsHeaders },
      );
    }

    // Create admin client early so we can fall back to the DB-stored Stripe key
    // if the STRIPE_SECRET_KEY env secret hasn't been set in Supabase Dashboard.
    const admin = createClient(supabaseUrl, serviceRoleKey);

    let stripeSecretKey = Deno.env.get("STRIPE_SECRET_KEY") ?? "";
    if (!stripeSecretKey) {
      const { data: stripeSettings } = await admin
        .from("app_settings")
        .select("value")
        .eq("key", "stripe_keys")
        .maybeSingle();
      stripeSecretKey = stripeSettings?.value?.secretKey ?? "";
    }

    if (!stripeSecretKey) {
      return Response.json(
        { error: "Stripe not configured — add key in Admin → Settings → Stripe" },
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

    const body = (await req.json()) as PurchaseBody;
    const coinAmount = Number(body.coin_amount ?? 0);
    const usdCents = Number(
      body.usd_cents ?? Math.round((body.usd_amount ?? 0) * 100),
    );

    if (!Number.isInteger(coinAmount) || coinAmount <= 0) {
      return Response.json(
        { error: "Invalid coin amount" },
        { status: 400, headers: corsHeaders },
      );
    }
    if (!Number.isInteger(usdCents) || usdCents < 50) {
      return Response.json(
        { error: "Invalid payment amount" },
        { status: 400, headers: corsHeaders },
      );
    }
    const validPack = await getValidCoinPack(admin, coinAmount, usdCents);
    if (!validPack) {
      return Response.json(
        { error: "Invalid coin package" },
        { status: 400, headers: corsHeaders },
      );
    }

    const params = new URLSearchParams({
      amount: usdCents.toString(),
      currency: "usd",
      "payment_method_types[]": "card",
      "metadata[user_id]": user.id,
      "metadata[coin_amount]": coinAmount.toString(),
      "metadata[usd_cents]": usdCents.toString(),
    });

    const stripeRes = await fetch("https://api.stripe.com/v1/payment_intents", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${stripeSecretKey}`,
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: params,
    });

    const paymentIntent = await stripeRes.json();
    if (!stripeRes.ok) {
      return Response.json(
        { error: paymentIntent?.error?.message ?? "Stripe payment failed" },
        { status: 400, headers: corsHeaders },
      );
    }

    await admin.from("coin_purchases").insert({
      user_id: user.id,
      coin_amount: coinAmount,
      usd_cents: usdCents,
      stripe_payment_id: paymentIntent.id,
      status: "pending",
    });

    return Response.json(
      {
        client_secret: paymentIntent.client_secret,
        payment_intent_id: paymentIntent.id,
      },
      { headers: corsHeaders },
    );
  } catch (error) {
    return Response.json(
      { error: error instanceof Error ? error.message : "Unknown error" },
      { status: 500, headers: corsHeaders },
    );
  }
});
