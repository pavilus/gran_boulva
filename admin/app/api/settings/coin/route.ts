import { NextResponse } from "next/server";
import { requireAdmin } from "@/lib/auth/admin";
import { createAdminClient } from "@/lib/supabase/admin";

type CoinPack = {
  coins: number;
  price: number;
  label: string;
  savings: string;
  popular: boolean;
};

type BoostTier = {
  label: string;
  tier: string;
  coins: number;
  desc: string;
};

type CoinEconomy = {
  coinsPerVote: number;
  coinsPerArgument: number;
  transferFee: number;
  signupBonus: number;
  dailyClaimBase: number;
  dailyStreakBonus: number;
  dailyClaimMax: number;
  supportAmounts: number[];
  boostTiers: BoostTier[];
  coinPacks: CoinPack[];
};

const DEFAULT_ECONOMY: CoinEconomy = {
  coinsPerVote: 0,
  coinsPerArgument: 0,
  transferFee: 10,
  signupBonus: 5,
  dailyClaimBase: 2,
  dailyStreakBonus: 1,
  dailyClaimMax: 10,
  supportAmounts: [50, 250, 1000, 5000, 10000],
  boostTiers: [
    {
      label: "24 Èdtan",
      tier: "24h",
      coins: 150,
      desc: "Vizibilite × 2 pandan 24 èdtan",
    },
    {
      label: "4 Jou",
      tier: "4d",
      coins: 350,
      desc: "Vizibilite × 5 pandan 4 jou",
    },
    {
      label: "1 Semèn",
      tier: "1w",
      coins: 550,
      desc: "Vizibilite × 10 pandan 1 semèn",
    },
  ],
  coinPacks: [
    { coins: 100,  price: 99,   label: "$0.99",  savings: "",            popular: false },
    { coins: 550,  price: 499,  label: "$4.99",  savings: "9% ekonomi",  popular: false },
    { coins: 1200, price: 999,  label: "$9.99",  savings: "16% ekonomi", popular: true  },
    { coins: 2500, price: 1999, label: "$19.99", savings: "19% ekonomi", popular: false },
    { coins: 7000, price: 4999, label: "$49.99", savings: "29% ekonomi", popular: false },
  ],
};

function toNumber(value: unknown, fallback = 0) {
  const n = Number(value);
  return Number.isFinite(n) && n >= 0 ? Math.round(n) : fallback;
}

function cleanEconomy(input: Partial<CoinEconomy>): CoinEconomy {
  const supportAmounts = Array.isArray(input.supportAmounts)
    ? input.supportAmounts.map((v) => toNumber(v)).filter((v) => v > 0)
    : DEFAULT_ECONOMY.supportAmounts;

  const boostTiers = Array.isArray(input.boostTiers)
    ? input.boostTiers
        .map((tier) => ({
          label: String(tier?.label ?? "").trim(),
          tier: String(tier?.tier ?? "").trim(),
          coins: toNumber(tier?.coins),
          desc: String(tier?.desc ?? "").trim(),
        }))
        .filter((tier) => tier.label && tier.tier && tier.coins > 0)
    : DEFAULT_ECONOMY.boostTiers;

  const coinPacks = Array.isArray(input.coinPacks)
    ? input.coinPacks
        .map((pack) => ({
          coins: toNumber(pack?.coins),
          price: toNumber(pack?.price),
          label: String(pack?.label ?? "").trim(),
          savings: String(pack?.savings ?? "").trim(),
          popular: Boolean(pack?.popular),
        }))
        .filter((pack) => pack.coins > 0 && pack.price > 0 && pack.label)
    : DEFAULT_ECONOMY.coinPacks;

  return {
    coinsPerVote: toNumber(input.coinsPerVote),
    coinsPerArgument: toNumber(input.coinsPerArgument),
    transferFee: toNumber(input.transferFee, DEFAULT_ECONOMY.transferFee),
    signupBonus: toNumber(input.signupBonus, DEFAULT_ECONOMY.signupBonus),
    dailyClaimBase: toNumber(input.dailyClaimBase, DEFAULT_ECONOMY.dailyClaimBase),
    dailyStreakBonus: toNumber(
      input.dailyStreakBonus,
      DEFAULT_ECONOMY.dailyStreakBonus
    ),
    dailyClaimMax: toNumber(input.dailyClaimMax, DEFAULT_ECONOMY.dailyClaimMax),
    supportAmounts: supportAmounts.length
      ? [...new Set(supportAmounts)]
      : DEFAULT_ECONOMY.supportAmounts,
    boostTiers: boostTiers.length ? boostTiers : DEFAULT_ECONOMY.boostTiers,
    coinPacks: coinPacks.length ? coinPacks : DEFAULT_ECONOMY.coinPacks,
  };
}

export async function GET() {
  const unauthorized = await requireAdmin();
  if (unauthorized) return unauthorized;

  const supabase = createAdminClient();
  const { data, error } = await supabase
    .from("app_settings")
    .select("value")
    .eq("key", "coin_economy")
    .maybeSingle();

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json(cleanEconomy(data?.value ?? DEFAULT_ECONOMY));
}

export async function POST(request: Request) {
  const unauthorized = await requireAdmin();
  if (unauthorized) return unauthorized;

  const payload = cleanEconomy(await request.json());
  const supabase = createAdminClient();
  const { error } = await supabase.from("app_settings").upsert(
    {
      key: "coin_economy",
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
