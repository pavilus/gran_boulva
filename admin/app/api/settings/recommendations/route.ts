import { NextResponse } from "next/server";
import { requireAdmin } from "@/lib/auth/admin";
import { createAdminClient } from "@/lib/supabase/admin";

type RecommendationSettings = {
  personalizedRatio: number;
  discoveryRatio: number;
  perspectiveRatio: number;
  freshnessDecayHours: number;
  trendingWeight: number;
  interestWeight: number;
  diversityWeight: number;
};

const DEFAULT_SETTINGS: RecommendationSettings = {
  personalizedRatio: 70,
  discoveryRatio: 20,
  perspectiveRatio: 10,
  freshnessDecayHours: 48,
  trendingWeight: 1.2,
  interestWeight: 2,
  diversityWeight: 0.35,
};

function toNumber(value: unknown, fallback: number) {
  const n = Number(value);
  return Number.isFinite(n) && n >= 0 ? n : fallback;
}

function clean(input: Partial<RecommendationSettings>): RecommendationSettings {
  return {
    personalizedRatio: Math.round(
      toNumber(input.personalizedRatio, DEFAULT_SETTINGS.personalizedRatio)
    ),
    discoveryRatio: Math.round(
      toNumber(input.discoveryRatio, DEFAULT_SETTINGS.discoveryRatio)
    ),
    perspectiveRatio: Math.round(
      toNumber(input.perspectiveRatio, DEFAULT_SETTINGS.perspectiveRatio)
    ),
    freshnessDecayHours: Math.round(
      toNumber(input.freshnessDecayHours, DEFAULT_SETTINGS.freshnessDecayHours)
    ),
    trendingWeight: toNumber(input.trendingWeight, DEFAULT_SETTINGS.trendingWeight),
    interestWeight: toNumber(input.interestWeight, DEFAULT_SETTINGS.interestWeight),
    diversityWeight: toNumber(input.diversityWeight, DEFAULT_SETTINGS.diversityWeight),
  };
}

export async function GET() {
  const unauthorized = await requireAdmin();
  if (unauthorized) return unauthorized;

  const supabase = createAdminClient();
  const { data, error } = await supabase
    .from("app_settings")
    .select("value")
    .eq("key", "recommendation_settings")
    .maybeSingle();

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json(clean(data?.value ?? DEFAULT_SETTINGS));
}

export async function POST(request: Request) {
  const unauthorized = await requireAdmin();
  if (unauthorized) return unauthorized;

  const payload = clean(await request.json());
  const supabase = createAdminClient();
  const { error } = await supabase.from("app_settings").upsert(
    {
      key: "recommendation_settings",
      value: payload,
      updated_at: new Date().toISOString(),
    },
    { onConflict: "key" }
  );

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json(payload);
}
