import { NextRequest, NextResponse } from "next/server";
import { requireAdmin } from "@/lib/auth/admin";
import { createAdminClient } from "@/lib/supabase/admin";

type ScoutActionBody = {
  draft_id?: string;
  action?: "approve" | "reject";
  edits?: {
    title_ht?: string;
    option_a?: string;
    option_b?: string;
    description_ht?: string | null;
  };
  notes?: string;
};

export async function POST(req: NextRequest) {
  const forbidden = await requireAdmin();
  if (forbidden) return forbidden;

  const { draft_id, action, edits, notes } = (await req.json()) as ScoutActionBody;
  if (!draft_id || !action) {
    return NextResponse.json({ error: "draft_id and action required" }, { status: 400 });
  }

  const supabase = createAdminClient();

  if (action === "reject") {
    const { error } = await supabase
      .from("ai_generated_drafts")
      .update({ status: "rejected", ...(notes ? { rejection_notes: notes } : {}) })
      .eq("id", draft_id);

    if (error) return NextResponse.json({ error: error.message }, { status: 500 });
    return NextResponse.json({ ok: true });
  }

  if (action !== "approve") {
    return NextResponse.json({ error: "Invalid action. Use 'approve' or 'reject'" }, { status: 400 });
  }

  const { data: draft, error: draftErr } = await supabase
    .from("ai_generated_drafts")
    .select("*")
    .eq("id", draft_id)
    .single();

  if (draftErr || !draft) {
    return NextResponse.json({ error: "Draft not found" }, { status: 404 });
  }

  const titleHt = edits?.title_ht ?? draft.title_ht;
  const optionA = edits?.option_a ?? draft.option_a;
  const optionB = edits?.option_b ?? draft.option_b;
  const descHt = edits?.description_ht ?? draft.description_ht;

  if (draft.type === "prediction") {
    const { data: prediction, error: predErr } = await supabase
      .from("predictions")
      .insert({
        category_id: draft.category_id,
        title_ht: titleHt,
        title_en: draft.title_en ?? null,
        option_a: optionA,
        option_b: optionB,
        deadline_at: draft.deadline_at ?? null,
        status: "active",
        total_votes: 0,
      })
      .select()
      .single();

    if (predErr || !prediction) {
      return NextResponse.json(
        { error: predErr?.message ?? "Failed to create prediction" },
        { status: 500 }
      );
    }

    await supabase.from("ai_generated_drafts").update({ status: "approved" }).eq("id", draft_id);
    return NextResponse.json({ prediction_id: prediction.id });
  }

  const now = new Date().toISOString();
  const { data: matchup, error: matchupErr } = await supabase
    .from("matchups")
    .insert({
      category_id: draft.category_id,
      title_ht: titleHt,
      title_en: draft.title_en ?? null,
      description_ht: descHt ?? null,
      status: "published",
      published_at: now,
      total_votes: 0,
      engagement_score: 0,
    })
    .select()
    .single();

  if (matchupErr || !matchup) {
    return NextResponse.json(
      { error: matchupErr?.message ?? "Failed to create matchup" },
      { status: 500 }
    );
  }

  const { error: optsErr } = await supabase.from("matchup_options").insert([
    {
      matchup_id: matchup.id,
      option_label: "A",
      option_name: optionA,
      vote_count: 0,
      image_url: draft.image_url_a ?? null,
    },
    {
      matchup_id: matchup.id,
      option_label: "B",
      option_name: optionB,
      vote_count: 0,
      image_url: draft.image_url_b ?? null,
    },
  ]);

  if (optsErr) {
    await supabase.from("matchups").delete().eq("id", matchup.id);
    return NextResponse.json({ error: optsErr.message }, { status: 500 });
  }

  await supabase.from("ai_generated_drafts").update({ status: "approved" }).eq("id", draft_id);
  return NextResponse.json({ matchup_id: matchup.id });
}
