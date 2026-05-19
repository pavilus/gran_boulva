import { NextResponse } from "next/server";
import { requireAdmin } from "@/lib/auth/admin";
import { createAdminClient } from "@/lib/supabase/admin";

export async function POST(req: Request) {
  const forbidden = await requireAdmin();
  if (forbidden) return forbidden;

  const { action, id, name_ht, name_en, icon } = await req.json();
  const supabase = createAdminClient();

  if (action === "create") {
    if (!name_ht) return NextResponse.json({ error: "name_ht required" }, { status: 400 });
    const { data, error } = await supabase
      .from("categories")
      .insert({ name_ht, name_en: name_en ?? "", icon: icon ?? null })
      .select()
      .single();
    if (error) return NextResponse.json({ error: error.message }, { status: 500 });
    return NextResponse.json(data);
  }

  if (action === "update") {
    if (!id) return NextResponse.json({ error: "id required" }, { status: 400 });
    const { error } = await supabase
      .from("categories")
      .update({ name_ht, name_en, icon })
      .eq("id", id);
    if (error) return NextResponse.json({ error: error.message }, { status: 500 });
    return NextResponse.json({ ok: true });
  }

  if (action === "delete") {
    if (!id) return NextResponse.json({ error: "id required" }, { status: 400 });
    const { error } = await supabase.from("categories").delete().eq("id", id);
    if (error) return NextResponse.json({ error: error.message }, { status: 500 });
    return NextResponse.json({ ok: true });
  }

  return NextResponse.json({ error: "Unknown action" }, { status: 400 });
}
