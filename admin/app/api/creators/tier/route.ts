import { NextRequest, NextResponse } from "next/server";
import { createAdminClient } from "@/lib/supabase/admin";

export async function POST(req: NextRequest) {
  const supabase = createAdminClient();
  const body = await req.json();
  const now = new Date().toISOString();

  // ── Set creator tier ────────────────────────────────────────────────────────
  if (body.userId !== undefined && body.tier !== undefined) {
    const tier: number = body.tier;
    const userId: string = body.userId;

    const rateMap: Record<number, number> = { 0: 0, 1: 0, 2: 0.7, 3: 0.8, 4: 0.9 };
    const rate = rateMap[tier] ?? 0;
    const monetized = tier >= 2;

    const { error } = await supabase
      .from("creator_profiles")
      .upsert(
        {
          user_id: userId,
          creator_tier: tier,
          revenue_share_rate: rate,
          is_monetization_enabled: monetized,
          monetization_suspended: false,
          tier_updated_at: now,
          updated_at: now,
        },
        { onConflict: "user_id" }
      );

    if (error) return NextResponse.json({ error: error.message }, { status: 500 });

    // Notify user of tier change
    const tierNames: Record<number, string> = {
      1: "Kreyatè Monte",
      2: "Kreyatè Verifye",
      3: "Kreyatè Elit",
      4: "Ikòn Kiltirèl",
    };
    if (tierNames[tier]) {
      await supabase.from("notifications").insert({
        user_id: userId,
        type: "system",
        title: `Ou tounen ${tierNames[tier]}!`,
        body:
          tier >= 2
            ? `Felisitasyon! Ou kounye a ka touche ${Math.round(rate * 100)}% revni sou Gran Boulva.`
            : `Ou kounye a nan Nivo ${tier} — ${tierNames[tier]}. Kontinye grandi!`,
      });
    }

    return NextResponse.json({ ok: true });
  }

  // ── Suspend / un-suspend monetization ───────────────────────────────────────
  if (body.userId !== undefined && body.suspend !== undefined) {
    const { error } = await supabase
      .from("creator_profiles")
      .update({
        monetization_suspended: body.suspend,
        is_monetization_enabled: !body.suspend,
        updated_at: now,
      })
      .eq("user_id", body.userId);

    if (error) return NextResponse.json({ error: error.message }, { status: 500 });

    if (body.suspend) {
      await supabase.from("notifications").insert({
        user_id: body.userId,
        type: "system",
        title: "Monetizasyon sispann",
        body: "Aksè ou nan monetizasyon Gran Boulva sispann pou kounye a. Kontakte ekip la pou plis enfòmasyon.",
      });
    }

    return NextResponse.json({ ok: true });
  }

  // ── Process payout ───────────────────────────────────────────────────────────
  if (body.payoutId && body.payoutAction) {
    const status = body.payoutAction === "complete" ? "completed" : "failed";

    const { data: payout, error: fetchErr } = await supabase
      .from("creator_payouts")
      .select("creator_user_id, coins_amount")
      .eq("id", body.payoutId)
      .single();

    if (fetchErr) return NextResponse.json({ error: fetchErr.message }, { status: 500 });

    await supabase
      .from("creator_payouts")
      .update({ status, processed_at: now })
      .eq("id", body.payoutId);

    if (status === "completed" && payout) {
      // Deduct from pending_payout_coins
      const { data: profile } = await supabase
        .from("creator_profiles")
        .select("pending_payout_coins, total_paid_out_coins")
        .eq("user_id", payout.creator_user_id)
        .single();

      if (profile) {
        await supabase
          .from("creator_profiles")
          .update({
            pending_payout_coins: Math.max(0, (profile.pending_payout_coins ?? 0) - payout.coins_amount),
            total_paid_out_coins: (profile.total_paid_out_coins ?? 0) + payout.coins_amount,
            updated_at: now,
          })
          .eq("user_id", payout.creator_user_id);
      }

      await supabase.from("notifications").insert({
        user_id: payout.creator_user_id,
        type: "system",
        title: "Peman trete!",
        body: `${payout.coins_amount} monè ou te reklame a trete avèk siksè.`,
      });
    }

    return NextResponse.json({ ok: true });
  }

  return NextResponse.json({ error: "Unknown action" }, { status: 400 });
}
