import { NextRequest, NextResponse } from "next/server";
import { createAdminClient } from "@/lib/supabase/admin";

const KEY = "payout_settings";

const DEFAULTS = {
  coinToUsdRate: 0.001,
  minPayoutCoins: 1000,
  payoutMode: "manual",          // "manual" | "moncash_auto"
  moncashEnvironment: "sandbox", // "sandbox" | "live"
  moncashEnabled: false,
};

export async function GET() {
  const supabase = createAdminClient();
  const { data, error } = await supabase
    .from("app_settings")
    .select("value")
    .eq("key", KEY)
    .single();

  if (error && error.code !== "PGRST116") {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json({ ...DEFAULTS, ...(data?.value ?? {}) });
}

export async function POST(req: NextRequest) {
  const supabase = createAdminClient();
  const body = await req.json();

  // Validate + sanitise
  const value = {
    coinToUsdRate:      Number(body.coinToUsdRate)   || DEFAULTS.coinToUsdRate,
    minPayoutCoins:     Math.max(0, Math.round(Number(body.minPayoutCoins) || DEFAULTS.minPayoutCoins)),
    payoutMode:         ["manual", "moncash_auto"].includes(body.payoutMode)
                          ? body.payoutMode
                          : DEFAULTS.payoutMode,
    moncashEnvironment: ["sandbox", "live"].includes(body.moncashEnvironment)
                          ? body.moncashEnvironment
                          : DEFAULTS.moncashEnvironment,
    moncashEnabled:     Boolean(body.moncashEnabled),
  };

  const { error } = await supabase
    .from("app_settings")
    .upsert({ key: KEY, value, updated_at: new Date().toISOString() }, { onConflict: "key" });

  if (error) return NextResponse.json({ error: error.message }, { status: 500 });
  return NextResponse.json(value);
}
