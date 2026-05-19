import { NextResponse } from "next/server";
import { requireAdmin } from "@/lib/auth/admin";
import { createAdminClient } from "@/lib/supabase/admin";

export async function POST(req: Request) {
  const forbidden = await requireAdmin();
  if (forbidden) return forbidden;

  const { id, action } = await req.json();
  if (!id || !action) return NextResponse.json({ error: "id and action required" }, { status: 400 });

  const supabase = createAdminClient();

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
