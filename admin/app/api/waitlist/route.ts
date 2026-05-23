import { NextResponse } from "next/server";
import { createAdminClient } from "@/lib/supabase/admin";

export async function POST(req: Request) {
  try {
    const { name, email, is_creator, is_supporter, tier } = await req.json();

    if (!name?.trim() || !email?.trim()) {
      return NextResponse.json({ error: "Name and email are required" }, { status: 400 });
    }
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      return NextResponse.json({ error: "Invalid email address" }, { status: 400 });
    }

    const supabase = createAdminClient();
    const { error } = await supabase.from("waitlist").upsert(
      {
        name: name.trim(),
        email: email.trim().toLowerCase(),
        is_creator: !!is_creator,
        is_supporter: !!is_supporter,
        tier: tier ?? null,
      },
      { onConflict: "email", ignoreDuplicates: false }
    );

    if (error) {
      // Unique violation = already on list — treat as success
      if (error.code === "23505") {
        return NextResponse.json({ ok: true, already: true });
      }
      return NextResponse.json({ error: error.message }, { status: 500 });
    }

    return NextResponse.json({ ok: true });
  } catch {
    return NextResponse.json({ error: "Server error" }, { status: 500 });
  }
}
