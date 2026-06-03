import { NextResponse } from "next/server";
import Stripe from "stripe";
import { createAdminClient } from "@/lib/supabase/admin";

const TIER_CONFIG: Record<string, { name: string; amount: number; description: string }> = {
  supporter:        { name: "Gran Boulva Supporter",        amount:   900, description: "Founding Supporter — one-time contribution" },
  ambassador:       { name: "Gran Boulva Ambassador",       amount:  4900, description: "Founding Ambassador — one-time contribution" },
  founding_creator: { name: "Gran Boulva Founding Creator", amount: 14900, description: "Founding Creator — one-time contribution" },
  founding_partner: { name: "Gran Boulva Founding Partner", amount: 49900, description: "Founding Partner — one-time contribution" },
};

// Resolve Stripe secret key: env var takes priority, falls back to app_settings
async function resolveStripeKey(): Promise<string | null> {
  if (process.env.STRIPE_SECRET_KEY) return process.env.STRIPE_SECRET_KEY;

  const supabase = createAdminClient();
  const { data } = await supabase
    .from("app_settings")
    .select("value")
    .eq("key", "stripe_keys")
    .maybeSingle();

  return data?.value?.secretKey ?? null;
}

export async function POST(req: Request) {
  try {
    const stripeKey = await resolveStripeKey();
    if (!stripeKey) {
      return NextResponse.json(
        { error: "Stripe is not configured yet. Add your secret key in Admin → Settings." },
        { status: 503 },
      );
    }

    const { tier } = await req.json() as { tier?: string };
    const config = tier ? TIER_CONFIG[tier] : null;
    if (!config) {
      return NextResponse.json({ error: "Invalid tier" }, { status: 400 });
    }

    const stripe = new Stripe(stripeKey, { apiVersion: "2026-04-22.dahlia" });
    const origin = req.headers.get("origin") ?? "https://granboulva.com";

    const session = await stripe.checkout.sessions.create({
      mode: "payment",
      line_items: [
        {
          quantity: 1,
          price_data: {
            currency: "usd",
            unit_amount: config.amount,
            product_data: {
              name: config.name,
              description: config.description,
              images: origin.startsWith("https") ? [`${origin}/logo.png`] : [],
            },
          },
        },
      ],
      metadata: { tier: tier as string },
      success_url: `${origin}/checkout/success?tier=${tier}&session_id={CHECKOUT_SESSION_ID}`,
      cancel_url:  `${origin}/supporters`,
      allow_promotion_codes: true,
    });

    return NextResponse.json({ url: session.url });
  } catch (err) {
    const message = err instanceof Error ? err.message : "Server error";
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
