import { NextResponse } from "next/server";
import { requireAdmin } from "@/lib/auth/admin";
import { createAdminClient } from "@/lib/supabase/admin";

export async function POST(req: Request) {
  const forbidden = await requireAdmin();
  if (forbidden) return forbidden;

  const { id, action } = await req.json();
  if (!id || !action) return NextResponse.json({ error: "id and action required" }, { status: 400 });

  const supabase = createAdminClient();
  const STATUS: Record<string, string> = { flag: "flagged", remove: "removed", restore: "active" };
  const status = STATUS[action];

  if (!status) return NextResponse.json({ error: "Unknown action" }, { status: 400 });

  const { error } = await supabase.from("arguments").update({ status }).eq("id", id);
  if (error) return NextResponse.json({ error: error.message }, { status: 500 });

  return NextResponse.json({ ok: true });
}
