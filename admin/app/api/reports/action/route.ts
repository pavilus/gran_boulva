import { NextResponse } from "next/server";
import { requireAdmin } from "@/lib/auth/admin";
import { createAdminClient } from "@/lib/supabase/admin";

export async function POST(req: Request) {
  const forbidden = await requireAdmin();
  if (forbidden) return forbidden;

  const { id, action } = await req.json();
  if (!id || !action) return NextResponse.json({ error: "id and action required" }, { status: 400 });

  const supabase = createAdminClient();
  const status = action === "resolve" ? "resolved" : action === "dismiss" ? "dismissed" : null;

  if (!status) return NextResponse.json({ error: "Unknown action" }, { status: 400 });

  const { error } = await supabase.from("reports").update({ status }).eq("id", id);
  if (error) return NextResponse.json({ error: error.message }, { status: 500 });

  return NextResponse.json({ ok: true });
}
