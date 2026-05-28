import { NextResponse } from "next/server";
import { requireAdmin } from "@/lib/auth/admin";
import { createClient } from "@/lib/supabase/server";

export async function POST() {
  const forbidden = await requireAdmin();
  if (forbidden) return forbidden;

  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
  const supabase = await createClient();
  const {
    data: { session },
  } = await supabase.auth.getSession();

  if (!session?.access_token) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  // Fire-and-forget — Scout takes 2-3 min, don't wait or the request times out
  fetch(`${supabaseUrl}/functions/v1/run-scout`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${session.access_token}`,
      "Content-Type": "application/json",
      apikey: process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    },
  }).catch(() => {}); // silently ignore — result goes straight to DB

  return NextResponse.json({ started: true, message: "Scout k ap kouri… Retounen nan 2-3 minit." });
}
