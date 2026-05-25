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
    const { id, name_ht, name_en, description_ht, description_en, color_hex, is_active, icon_asset } = body;
    if (!id) return NextResponse.json({ error: "id required" }, { status: 400 });
    // Only include fields that were provided
    const updates: Record<string, unknown> = {};
    if (name_ht !== undefined) updates.name_ht = name_ht;
    if (name_en !== undefined) updates.name_en = name_en;
    if (description_ht !== undefined) updates.description_ht = description_ht;
    if (description_en !== undefined) updates.description_en = description_en;
    if (color_hex !== undefined) updates.color_hex = color_hex;
    if (is_active !== undefined) updates.is_active = is_active;
    if (icon_asset !== undefined) updates.icon_asset = icon_asset;
    const { error } = await supabase
      .from("badges")
      .update(updates)
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
