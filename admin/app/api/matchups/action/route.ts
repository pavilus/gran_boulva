import { NextResponse } from "next/server";
import { requireAdmin } from "@/lib/auth/admin";
import { createAdminClient } from "@/lib/supabase/admin";

export async function POST(req: Request) {
  const forbidden = await requireAdmin();
  if (forbidden) return forbidden;

  const body = await req.json();
  const { action } = body;
  if (!action) return NextResponse.json({ error: "action required" }, { status: 400 });

  const supabase = createAdminClient();

  if (action === "create") {
    const { title_ht, title_en, description_ht, category_id, option_a_name, option_b_name } = body;
    if (!title_ht || !category_id || !option_a_name || !option_b_name)
      return NextResponse.json({ error: "title_ht, category_id, option_a_name, option_b_name required" }, { status: 400 });

    const { data: matchup, error: mErr } = await supabase
      .from("matchups")
      .insert({ title_ht, title_en: title_en || null, description_ht: description_ht || null, category_id, status: "draft", total_votes: 0, engagement_score: 0 })
      .select()
      .single();
    if (mErr) return NextResponse.json({ error: mErr.message }, { status: 500 });

    const { error: oErr } = await supabase.from("matchup_options").insert([
      { matchup_id: matchup.id, option_label: "A", option_name: option_a_name, vote_count: 0 },
      { matchup_id: matchup.id, option_label: "B", option_name: option_b_name, vote_count: 0 },
    ]);
    if (oErr) return NextResponse.json({ error: oErr.message }, { status: 500 });

    return NextResponse.json({ ok: true, matchup });
  }

  const { id } = body;
  if (!id) return NextResponse.json({ error: "id required" }, { status: 400 });

  if (action === "update") {
    const { title_ht, title_en, description_ht, category_id, status, expires_at, option_a_name, option_b_name } = body;
    if (!title_ht) return NextResponse.json({ error: "title_ht required" }, { status: 400 });

    const { error: mErr } = await supabase.from("matchups").update({
      title_ht,
      title_en: title_en || null,
      description_ht: description_ht || null,
      category_id: category_id || null,
      status: status || undefined,
      expires_at: expires_at || null,
    }).eq("id", id);
    if (mErr) return NextResponse.json({ error: mErr.message }, { status: 500 });

    // Update option names if provided
    if (option_a_name) {
      await supabase.from("matchup_options").update({ option_name: option_a_name })
        .eq("matchup_id", id).eq("option_label", "A");
    }
    if (option_b_name) {
      await supabase.from("matchup_options").update({ option_name: option_b_name })
        .eq("matchup_id", id).eq("option_label", "B");
    }

    return NextResponse.json({ ok: true });
  }

  if (action === "publish") {
    const { error } = await supabase.from("matchups").update({ status: "published", published_at: new Date().toISOString() }).eq("id", id);
    if (error) return NextResponse.json({ error: error.message }, { status: 500 });
  } else if (action === "close") {
    const { error } = await supabase.from("matchups").update({ status: "closed" }).eq("id", id);
    if (error) return NextResponse.json({ error: error.message }, { status: 500 });
  } else if (action === "archive") {
    const { error } = await supabase.from("matchups").update({ status: "archived" }).eq("id", id);
    if (error) return NextResponse.json({ error: error.message }, { status: 500 });
  } else if (action === "delete") {
    const { error } = await supabase.from("matchups").delete().eq("id", id);
    if (error) return NextResponse.json({ error: error.message }, { status: 500 });
  } else {
    return NextResponse.json({ error: "Unknown action" }, { status: 400 });
  }

  return NextResponse.json({ ok: true });
}
