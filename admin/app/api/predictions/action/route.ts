import { NextResponse } from "next/server";
import { requireAdmin } from "@/lib/auth/admin";
import { createAdminClient } from "@/lib/supabase/admin";

export async function POST(req: Request) {
  const forbidden = await requireAdmin();
  if (forbidden) return forbidden;

  const body = await req.json();
  const { id, action, winner } = body;

  const supabase = createAdminClient();

  // ── Create new prediction ─────────────────────────────────────────────────
  if (action === "create") {
    const { title_ht, title_en, option_a, option_b, deadline_at, category_id, status } = body;
    if (!title_ht || !option_a || !option_b) {
      return NextResponse.json({ error: "title_ht, option_a, option_b required" }, { status: 400 });
    }
    const { data, error } = await supabase.from("predictions").insert({
      title_ht,
      title_en: title_en || null,
      option_a,
      option_b,
      deadline_at: deadline_at || null,
      category_id: category_id || null,
      status: status || "active",
      total_votes: 0,
    }).select().single();
    if (error) return NextResponse.json({ error: error.message }, { status: 500 });
    return NextResponse.json({ ok: true, prediction: data });
  }

  // All other actions require id
  if (!id || !action) return NextResponse.json({ error: "id and action required" }, { status: 400 });

  // ── Update / edit prediction ──────────────────────────────────────────────
  if (action === "update") {
    const { title_ht, title_en, option_a, option_b, deadline_at, category_id, status } = body;
    const updates: Record<string, unknown> = {};
    if (title_ht !== undefined) updates.title_ht = title_ht;
    if (title_en !== undefined) updates.title_en = title_en || null;
    if (option_a !== undefined) updates.option_a = option_a;
    if (option_b !== undefined) updates.option_b = option_b;
    if (deadline_at !== undefined) updates.deadline_at = deadline_at || null;
    if (category_id !== undefined) updates.category_id = category_id || null;
    if (status !== undefined) updates.status = status;
    const { error } = await supabase.from("predictions").update(updates).eq("id", id);
    if (error) return NextResponse.json({ error: error.message }, { status: 500 });
    return NextResponse.json({ ok: true });
  }

  // ── Resolve prediction ────────────────────────────────────────────────────
  if (action === "resolve") {
    if (!winner) return NextResponse.json({ error: "winner required (A or B)" }, { status: 400 });
    const { error } = await supabase
      .from("predictions")
      .update({ status: "resolved", winning_option: winner })
      .eq("id", id);
    if (error) return NextResponse.json({ error: error.message }, { status: 500 });
    return NextResponse.json({ ok: true });
  }

  // ── Close prediction ──────────────────────────────────────────────────────
  if (action === "close") {
    const { error } = await supabase.from("predictions").update({ status: "closed" }).eq("id", id);
    if (error) return NextResponse.json({ error: error.message }, { status: 500 });
    return NextResponse.json({ ok: true });
  }

  return NextResponse.json({ error: "Unknown action" }, { status: 400 });
}
