import { NextResponse } from "next/server";
import Stripe from "stripe";
import { createAdminClient } from "@/lib/supabase/admin";

export const runtime = "nodejs";

function fallbackName(email: string) {
  return email.split("@")[0]?.replace(/[._-]+/g, " ").trim() || "Stripe customer";
}

async function resolveStripeSecrets(): Promise<{ secretKey: string; webhookSecret: string } | null> {
  const envKey    = process.env.STRIPE_SECRET_KEY;
  const envSecret = process.env.STRIPE_WEBHOOK_SECRET;
  if (envKey && envSecret) return { secretKey: envKey, webhookSecret: envSecret };

  const supabase = createAdminClient();
  const { data } = await supabase
    .from("app_settings")
    .select("value")
    .eq("key", "stripe_keys")
    .maybeSingle();

  const secretKey    = envKey    ?? data?.value?.secretKey    ?? null;
  const webhookSecret = envSecret ?? data?.value?.webhookSecret ?? null;
  if (!secretKey || !webhookSecret) return null;
  return { secretKey, webhookSecret };
}

async function handleCheckoutCompleted(session: Stripe.Checkout.Session) {
  const email = session.customer_details?.email?.trim().toLowerCase();
  if (!email) return;

  const tier = typeof session.metadata?.tier === "string"
    ? session.metadata.tier
    : null;
  const name = session.customer_details?.name?.trim() || fallbackName(email);

  const supabase = createAdminClient();
  const { error } = await supabase
    .from("waitlist")
    .upsert(
      {
        name,
        email,
        is_supporter: true,
        tier,
        source: "stripe_checkout",
      },
      { onConflict: "email" },
    );

  if (error) throw error;
}

export async function POST(req: Request) {
  const secrets = await resolveStripeSecrets();
  if (!secrets) {
    return NextResponse.json(
      { error: "Stripe webhook secrets are not configured" },
      { status: 500 },
    );
  }

  const signature = req.headers.get("stripe-signature");
  if (!signature) {
    return NextResponse.json({ error: "Missing Stripe signature" }, { status: 400 });
  }

  let event: Stripe.Event;
  const body = await req.text();
  const stripe = new Stripe(secrets.secretKey, {
    apiVersion: "2026-04-22.dahlia",
  });

  try {
    event = await stripe.webhooks.constructEventAsync(
      body,
      signature,
      secrets.webhookSecret,
    );
  } catch (error) {
    const message = error instanceof Error ? error.message : "Invalid webhook";
    return NextResponse.json({ error: message }, { status: 400 });
  }

  try {
    if (event.type === "checkout.session.completed") {
      await handleCheckoutCompleted(event.data.object as Stripe.Checkout.Session);
    }
  } catch (error) {
    const message = error instanceof Error ? error.message : "Webhook handler failed";
    return NextResponse.json({ error: message }, { status: 500 });
  }

  return NextResponse.json({ received: true });
}
