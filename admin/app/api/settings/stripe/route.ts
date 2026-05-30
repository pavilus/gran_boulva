import { NextResponse } from "next/server";
import { requireAdmin } from "@/lib/auth/admin";
import { createAdminClient } from "@/lib/supabase/admin";

const SETTINGS_KEY = "stripe_keys";

function hint(key: string) {
  return key.slice(0, 8) + "..." + key.slice(-4);
}

export async function GET() {
  const unauthorized = await requireAdmin();
  if (unauthorized) return unauthorized;

  const supabase = createAdminClient();
  const { data } = await supabase
    .from("app_settings")
    .select("value")
    .eq("key", SETTINGS_KEY)
    .maybeSingle();

  const secretKey: string     = data?.value?.secretKey     ?? "";
  const webhookSecret: string = data?.value?.webhookSecret ?? "";

  return NextResponse.json({
    configured:       secretKey.length > 0,
    hint:             secretKey.length > 0 ? hint(secretKey) : "",
    webhookConfigured: webhookSecret.length > 0,
    webhookHint:      webhookSecret.length > 0 ? hint(webhookSecret) : "",
  });
}

export async function POST(req: Request) {
  const unauthorized = await requireAdmin();
  if (unauthorized) return unauthorized;

  const body = await req.json() as { secretKey?: string; webhookSecret?: string };

  // Fetch existing values so a partial update doesn't wipe the other field
  const supabase = createAdminClient();
  const { data: existing } = await supabase
    .from("app_settings")
    .select("value")
    .eq("key", SETTINGS_KEY)
    .maybeSingle();

  const current = existing?.value ?? {};

  if (body.secretKey !== undefined) {
    const key = body.secretKey.trim();
    if (!key) return NextResponse.json({ error: "secretKey is required" }, { status: 400 });
    if (!key.startsWith("sk_")) return NextResponse.json({ error: "Key must start with sk_" }, { status: 400 });
    current.secretKey = key;
  }

  if (body.webhookSecret !== undefined) {
    const secret = body.webhookSecret.trim();
    if (!secret) return NextResponse.json({ error: "webhookSecret is required" }, { status: 400 });
    if (!secret.startsWith("whsec_")) return NextResponse.json({ error: "Webhook secret must start with whsec_" }, { status: 400 });
    current.webhookSecret = secret;
  }

  const { error } = await supabase.from("app_settings").upsert(
    { key: SETTINGS_KEY, value: current, updated_at: new Date().toISOString() },
    { onConflict: "key" }
  );

  if (error) return NextResponse.json({ error: error.message }, { status: 500 });

  return NextResponse.json({
    ok: true,
    hint:             current.secretKey    ? hint(current.secretKey)    : "",
    webhookHint:      current.webhookSecret ? hint(current.webhookSecret) : "",
    configured:       !!current.secretKey,
    webhookConfigured: !!current.webhookSecret,
  });
}
