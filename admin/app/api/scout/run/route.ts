import { NextResponse } from "next/server";
import { requireAdmin } from "@/lib/auth/admin";

export async function POST() {
  const forbidden = await requireAdmin();
  if (forbidden) return forbidden;

  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
  const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;

  const res = await fetch(`${supabaseUrl}/functions/v1/run-scout`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${serviceKey}`,
      "Content-Type": "application/json",
      apikey: process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    },
  });

  const data = await res.json();
  return NextResponse.json(data, { status: res.ok ? 200 : 500 });
}
