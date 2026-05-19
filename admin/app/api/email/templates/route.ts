import { NextResponse } from "next/server";
import { requireAdmin } from "@/lib/auth/admin";
import { createAdminClient } from "@/lib/supabase/admin";

export async function POST(req: Request) {
  const forbidden = await requireAdmin();
  if (forbidden) return forbidden;

  const { id, name, subject, body_html, body_text, signature_html } = await req.json();
  if (!name || !subject) {
    return NextResponse.json({ error: "name and subject are required" }, { status: 400 });
  }

  const supabase = createAdminClient();
  const payload = { name, subject, body_html, body_text, signature_html };
  const query = id
    ? supabase.from("email_templates").update(payload).eq("id", id).select().single()
    : supabase.from("email_templates").insert(payload).select().single();

  const { data, error } = await query;
  if (error) return NextResponse.json({ error: error.message }, { status: 500 });
  return NextResponse.json(data);
}
