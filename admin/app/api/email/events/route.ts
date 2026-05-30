import { NextResponse } from "next/server";
import { requireAdmin } from "@/lib/auth/admin";
import { createAdminClient } from "@/lib/supabase/admin";

export async function GET() {
  const forbidden = await requireAdmin();
  if (forbidden) return forbidden;

  const supabase = createAdminClient();
  const { data, error } = await supabase
    .from("email_event_mappings")
    .select("event_slug, enabled, label_ht, description_ht, category, template_id, email_templates(id, name, subject)")
    .order("category")
    .order("event_slug");

  if (error) return NextResponse.json({ error: error.message }, { status: 500 });
  return NextResponse.json(data ?? []);
}

export async function PATCH(req: Request) {
  const forbidden = await requireAdmin();
  if (forbidden) return forbidden;

  const body = await req.json();
  const { event_slug, template_id, enabled } = body;
  if (!event_slug) return NextResponse.json({ error: "event_slug required" }, { status: 400 });

  const update: Record<string, unknown> = {};
  if (template_id !== undefined) update.template_id = template_id || null;
  if (enabled !== undefined) update.enabled = enabled;

  const supabase = createAdminClient();
  const { error } = await supabase
    .from("email_event_mappings")
    .update(update)
    .eq("event_slug", event_slug);

  if (error) return NextResponse.json({ error: error.message }, { status: 500 });
  return NextResponse.json({ ok: true });
}
