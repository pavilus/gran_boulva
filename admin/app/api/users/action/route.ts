import { NextResponse } from "next/server";
import { requireAdmin } from "@/lib/auth/admin";
import { createAdminClient } from "@/lib/supabase/admin";

export async function POST(req: Request) {
  const forbidden = await requireAdmin();
  if (forbidden) return forbidden;

  const { id, action } = await req.json();
  if (!id || !action) return NextResponse.json({ error: "id and action required" }, { status: 400 });

  const supabase = createAdminClient();
  let update: Record<string, string> | null = null;

  if (action === "suspend") update = { role: "suspended" };
  else if (action === "unsuspend") update = { role: "user" };
  else if (action === "make_moderator") update = { role: "moderator" };
  else if (action === "remove_moderator") update = { role: "user" };
  else return NextResponse.json({ error: "Unknown action" }, { status: 400 });

  const { error } = await supabase.from("users").update(update).eq("id", id);
  if (error) return NextResponse.json({ error: error.message }, { status: 500 });

  return NextResponse.json({ ok: true });
}
