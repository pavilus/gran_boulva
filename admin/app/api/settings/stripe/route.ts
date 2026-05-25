import { NextResponse } from "next/server";
import { requireAdmin } from "@/lib/auth/admin";
import { createAdminClient } from "@/lib/supabase/admin";

const SETTINGS_KEY = "stripe_keys";

export async function GET() {
  const unauthorized = await requireAdmin();
  if (unauthorized) return unauthorized;

  const supabase = createAdminClient();
  const { data } = await supabase
    .from("app_settings")
    .select("value")
    .eq("key", SETTINGS_KEY)
    .maybeSingle();

  const secretKey: string = data?.value?.secretKey ?? "";
  const configured = secretKey.length > 0;

  // Return a hint only — never the full key
  const hint = configured
    ? secretKey.slice(0, 8) + "..." + secretKey.slice(-4)
    : "";

  return NextResponse.json({ configured, hint });
}

export async function POST(req: Request) {
  const unauthorized = await requireAdmin();
  if (unauthorized) return unauthorized;

  const { secretKey } = await req.json() as { secretKey?: string };

  if (!secretKey?.trim()) {
    return NextResponse.json({ error: "secretKey is required" }, { status: 400 });
  }
  if (!secretKey.startsWith("sk_")) {
    return NextResponse.json({ error: "Key must start with sk_" }, { status: 400 });
  }

  const supabase = createAdminClient();
  const { error } = await supabase.from("app_settings").upsert(
    { key: SETTINGS_KEY, value: { secretKey: secretKey.trim() }, updated_at: new Date().toISOString() },
    { onConflict: "key" }
  );

  if (error) return NextResponse.json({ error: error.message }, { status: 500 });

  const hint = secretKey.slice(0, 8) + "..." + secretKey.slice(-4);
  return NextResponse.json({ ok: true, hint, configured: true });
}
