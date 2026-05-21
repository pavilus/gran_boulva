import { NextRequest, NextResponse } from "next/server";
import { createAdminClient } from "@/lib/supabase/admin";

function badgeStyleForType(type: string) {
  switch (type) {
    case "organization":    return "business";
    case "public_figure":   return "gold";
    case "trusted_creator": return "silver";
    case "admin":           return "verified";
    default:                return "standard";
  }
}

export async function POST(req: NextRequest) {
  const supabase = createAdminClient();
  const body = await req.json();
  const { action, requestId, userId, verificationType, adminNotes, rejectionReason } = body;

  const now = new Date().toISOString();

  if (action === "approve") {
    const badgeStyle = badgeStyleForType(verificationType);

    await supabase.from("user_verifications").upsert(
      {
        user_id: userId,
        verification_type: verificationType,
        badge_style: badgeStyle,
        status: "approved",
        granted_at: now,
        updated_at: now,
      },
      { onConflict: "user_id,verification_type" }
    );

    await supabase
      .from("users")
      .update({
        verification_type: verificationType,
        verification_badge_style: badgeStyle,
        verification_status: "approved",
      })
      .eq("id", userId);

    await supabase
      .from("verification_requests")
      .update({
        status: "approved",
        admin_notes: adminNotes ?? null,
        reviewed_at: now,
        updated_at: now,
      })
      .eq("id", requestId);

    // Notify the user
    await supabase.from("notifications").insert({
      user_id: userId,
      type: "system",
      title: "Kont ou verifye",
      body: "Demann verifikasyon ou a apwouve.",
      related_table: "verification_requests",
      related_id: requestId,
    });

    return NextResponse.json({ ok: true });
  }

  if (action === "reject") {
    await supabase
      .from("verification_requests")
      .update({
        status: "rejected",
        rejection_reason: rejectionReason ?? null,
        admin_notes: adminNotes ?? null,
        reviewed_at: now,
        updated_at: now,
      })
      .eq("id", requestId);

    await supabase
      .from("users")
      .update({ verification_status: "rejected" })
      .eq("id", userId)
      .neq("verification_status", "approved");

    await supabase.from("notifications").insert({
      user_id: userId,
      type: "system",
      title: "Verifikasyon pa apwouve",
      body: rejectionReason?.trim()
        ? rejectionReason
        : "Demann verifikasyon ou a pa apwouve pou kounye a.",
      related_table: "verification_requests",
      related_id: requestId,
    });

    return NextResponse.json({ ok: true });
  }

  if (action === "under_review") {
    await supabase
      .from("verification_requests")
      .update({ status: "under_review", updated_at: now })
      .eq("id", requestId);
    return NextResponse.json({ ok: true });
  }

  return NextResponse.json({ error: "Unknown action" }, { status: 400 });
}
