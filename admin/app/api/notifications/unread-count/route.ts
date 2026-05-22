import { NextResponse } from "next/server";
import { requireAdmin } from "@/lib/auth/admin";
import { createAdminClient } from "@/lib/supabase/admin";

// Returns the total number of unread notifications across all users.
// Uses the service-role client so RLS does not filter to a single user.
export async function GET() {
  const forbidden = await requireAdmin();
  if (forbidden) return forbidden;

  const supabase = createAdminClient();
  const { count, error } = await supabase
    .from("notifications")
    .select("*", { count: "exact", head: true })
    .eq("is_read", false);

  if (error) return NextResponse.json({ count: 0 });
  return NextResponse.json({ count: count ?? 0 });
}
