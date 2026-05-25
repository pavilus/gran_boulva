import { NextResponse } from "next/server";
import { requireAdmin } from "@/lib/auth/admin";
import { createAdminClient } from "@/lib/supabase/admin";

export async function POST(req: Request) {
  const forbidden = await requireAdmin();
  if (forbidden) return forbidden;

  const body = await req.json();
  const { action } = body;
  const supabase = createAdminClient();

  // ── Update badge metadata ──────────────────────────────────────────────────
  if (action === "update_badge") {
    const { id, name_ht, name_en, description_ht, description_en, color_hex, is_active } = body;
    if (!id) return NextResponse.json({ error: "id required" }, { status: 400 });
    const { error } = await supabase
      .from("badges")
      .update({ name_ht, name_en, description_ht, description_en, color_hex, is_active })
      .eq("id", id);
    if (error) return NextResponse.json({ error: error.message }, { status: 500 });
    return NextResponse.json({ ok: true });
  }

  // ── Update badge level threshold ───────────────────────────────────────────
  if (action === "update_level") {
    const { id, required_xp, title_ht, title_en, influence_reward } = body;
    if (!id) return NextResponse.json({ error: "id required" }, { status: 400 });
    const { error } = await supabase
      .from("badge_levels")
      .update({ required_xp, title_ht, title_en, influence_reward })
      .eq("id", id);
    if (error) return NextResponse.json({ error: error.message }, { status: 500 });
    return NextResponse.json({ ok: true });
  }

  return NextResponse.json({ error: "Unknown action" }, { status: 400 });
}
