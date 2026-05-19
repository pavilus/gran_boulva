import { NextRequest, NextResponse } from "next/server";
import { requireAdmin } from "@/lib/auth/admin";
import { createAdminClient } from "@/lib/supabase/admin";

export async function POST(req: NextRequest) {
  const forbidden = await requireAdmin();
  if (forbidden) return forbidden;

  const { draft_id, ...updates } = await req.json();
  if (!draft_id) return NextResponse.json({ error: "draft_id required" }, { status: 400 });

  const supabase = createAdminClient();
  const { error } = await supabase
    .from("ai_generated_drafts")
    .update(updates)
    .eq("id", draft_id);

  if (error) return NextResponse.json({ error: error.message }, { status: 500 });
  return NextResponse.json({ ok: true });
}
