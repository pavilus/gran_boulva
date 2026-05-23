import { NextResponse } from "next/server";
import { requireAdmin } from "@/lib/auth/admin";
import { createAdminClient } from "@/lib/supabase/admin";

export async function PATCH(req: Request) {
  const forbidden = await requireAdmin();
  if (forbidden) return forbidden;

  const { from_email, reply_to, default_signature_html } = await req.json();

  const supabase = createAdminClient();
  const { error } = await supabase
    .from("email_settings")
    .update({ from_email, reply_to, default_signature_html, updated_at: new Date().toISOString() })
    .eq("id", true);

  if (error) return NextResponse.json({ error: error.message }, { status: 500 });
  return NextResponse.json({ ok: true });
}
