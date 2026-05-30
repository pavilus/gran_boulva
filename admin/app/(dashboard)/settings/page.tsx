"use client";

import Topbar from "@/components/Topbar";
import { useEffect, useState } from "react";
import { Plus, Save, Trash2 } from "lucide-react";

type PayoutSettings = {
  coinToUsdRate: number;
  minPayoutCoins: number;
  payoutMode: "manual" | "moncash_auto";
  moncashEnvironment: "sandbox" | "live";
  moncashEnabled: boolean;
};

const fallbackPayout: PayoutSettings = {
  coinToUsdRate: 0.006,
  minPayoutCoins: 4167,
  payoutMode: "manual",
  moncashEnvironment: "sandbox",
  moncashEnabled: false,
};

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

type RecommendationSettings = {
  personalizedRatio: number;
  discoveryRatio: number;
  perspectiveRatio: number;
  freshnessDecayHours: number;
  trendingWeight: number;
  interestWeight: number;
  diversityWeight: number;
};

const emptyPack: CoinPack = {
  coins: 0,
  price: 0,
  label: "",
  savings: "",
  popular: false,
};

const emptyTier: BoostTier = {
  label: "",
  tier: "",
  coins: 0,
  desc: "",
};

const fallbackEconomy: CoinEconomy = {
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

const fallbackRecommendations: RecommendationSettings = {
  personalizedRatio: 70,
  discoveryRatio: 20,
  perspectiveRatio: 10,
  freshnessDecayHours: 48,
  trendingWeight: 1.2,
  interestWeight: 2,
  diversityWeight: 0.35,
};

function Section({
  title,
  children,
}: {
  title: string;
  children: React.ReactNode;
}) {
  return (
    <div
      className="rounded-xl p-6"
      style={{ background: "#0e0f1e", border: "1px solid #1e2040" }}
    >
      <div
        className="mb-5 pb-3 font-semibold text-white"
        style={{ borderBottom: "1px solid #1e2040" }}
      >
        {title}
      </div>
      <div className="space-y-4">{children}</div>
    </div>
  );
}

function Field({
  label,
  value,
  onChange,
  type = "text",
  hint,
}: {
  label: string;
  value: string | number;
  onChange: (v: string) => void;
  type?: string;
  hint?: string;
}) {
  return (
    <div>
      <label className="mb-1 block text-xs font-semibold" style={{ color: "#94a3b8" }}>
        {label}
      </label>
      <input
        type={type}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        className="w-full rounded-lg px-3 py-2 text-sm text-white outline-none"
        style={{ background: "#0a0b18", border: "1px solid #1e2040" }}
      />
      {hint && (
        <div className="mt-1" style={{ color: "#64748b", fontSize: 11 }}>
          {hint}
        </div>
      )}
    </div>
  );
}

function IconButton({
  label,
  onClick,
  children,
}: {
  label: string;
  onClick: () => void;
  children: React.ReactNode;
}) {
  return (
    <button
      type="button"
      aria-label={label}
      title={label}
      onClick={onClick}
      className="flex h-9 w-9 items-center justify-center rounded-lg text-white transition-colors"
      style={{ background: "#15172a", border: "1px solid #1e2040" }}
    >
      {children}
    </button>
  );
}

const numberValue = (value: string) => {
  const parsed = Number(value);
  return Number.isFinite(parsed) && parsed >= 0 ? Math.round(parsed) : 0;
};

export default function SettingsPage() {
  const [economy, setEconomy] = useState<CoinEconomy>(fallbackEconomy);
  const [recommendations, setRecommendations] =
    useState<RecommendationSettings>(fallbackRecommendations);
  const [payout, setPayout] = useState<PayoutSettings>(fallbackPayout);
  const [supportAmountsText, setSupportAmountsText] = useState("50, 250, 1000, 5000, 10000");
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState("");

  // Stripe key state
  const [stripeKey, setStripeKey]                     = useState("");
  const [stripeHint, setStripeHint]                   = useState("");
  const [stripeConfigured, setStripeConfigured]       = useState(false);
  const [stripeSaving, setStripeSaving]               = useState(false);
  const [stripeMsg, setStripeMsg]                     = useState("");
  const [webhookSecret, setWebhookSecret]             = useState("");
  const [webhookHint, setWebhookHint]                 = useState("");
  const [webhookConfigured, setWebhookConfigured]     = useState(false);
  const [webhookSaving, setWebhookSaving]             = useState(false);
  const [webhookMsg, setWebhookMsg]                   = useState("");

  useEffect(() => {
    let alive = true;
    fetch("/api/settings/coin")
      .then(async (res) => {
        if (!res.ok) throw new Error((await res.json()).error ?? "Load failed");
        return res.json();
      })
      .then((data: CoinEconomy) => {
        if (!alive) return;
        setEconomy(data);
        setSupportAmountsText(data.supportAmounts.join(", "));
      })
      .catch((error) => {
        if (alive) setMessage(error.message);
      })
      .finally(() => {
        if (alive) setLoading(false);
      });
    fetch("/api/settings/recommendations")
      .then(async (res) => {
        if (!res.ok) throw new Error((await res.json()).error ?? "Load failed");
        return res.json();
      })
      .then((data: RecommendationSettings) => {
        if (alive) setRecommendations(data);
      })
      .catch((error) => {
        if (alive) setMessage(error.message);
      });
    fetch("/api/settings/payout")
      .then(async (res) => {
        if (!res.ok) throw new Error((await res.json()).error ?? "Load failed");
        return res.json();
      })
      .then((data: PayoutSettings) => {
        if (alive) setPayout(data);
      })
      .catch(() => {/* use fallback */});
    fetch("/api/settings/stripe")
      .then(async (res) => res.ok ? res.json() : null)
      .then((data: { configured: boolean; hint: string; webhookConfigured: boolean; webhookHint: string } | null) => {
        if (!alive || !data) return;
        setStripeConfigured(data.configured);
        setStripeHint(data.hint);
        setWebhookConfigured(data.webhookConfigured);
        setWebhookHint(data.webhookHint);
      })
      .catch(() => {/* silent */});
    return () => {
      alive = false;
    };
  }, []);

  const setEconomyNumber = (key: keyof Pick<CoinEconomy, "coinsPerVote" | "coinsPerArgument" | "transferFee" | "signupBonus" | "dailyClaimBase" | "dailyStreakBonus" | "dailyClaimMax">) => (value: string) => {
    setEconomy((current) => ({ ...current, [key]: numberValue(value) }));
  };

  const updatePack = (index: number, patch: Partial<CoinPack>) => {
    setEconomy((current) => ({
      ...current,
      coinPacks: current.coinPacks.map((pack, i) =>
        i === index ? { ...pack, ...patch } : pack
      ),
    }));
  };

  const updateTier = (index: number, patch: Partial<BoostTier>) => {
    setEconomy((current) => ({
      ...current,
      boostTiers: current.boostTiers.map((tier, i) =>
        i === index ? { ...tier, ...patch } : tier
      ),
    }));
  };

  const setRecommendationNumber =
    (key: keyof RecommendationSettings) => (value: string) => {
      const parsed = Number(value);
      setRecommendations((current) => ({
        ...current,
        [key]: Number.isFinite(parsed) && parsed >= 0 ? parsed : 0,
      }));
    };

  const saveStripe = async () => {
    if (!stripeKey.trim()) return;
    setStripeSaving(true);
    setStripeMsg("");
    try {
      const res  = await fetch("/api/settings/stripe", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ secretKey: stripeKey.trim() }) });
      const data = await res.json() as { ok?: boolean; hint?: string; configured?: boolean; error?: string };
      if (!res.ok) throw new Error(data.error ?? "Save failed");
      setStripeConfigured(true);
      setStripeHint(data.hint ?? "");
      setStripeKey("");
      setStripeMsg("✓ Stripe key saved");
    } catch (err) {
      setStripeMsg(err instanceof Error ? err.message : "Save failed");
    } finally {
      setStripeSaving(false);
    }
  };

  const saveWebhookSecret = async () => {
    if (!webhookSecret.trim()) return;
    setWebhookSaving(true);
    setWebhookMsg("");
    try {
      const res  = await fetch("/api/settings/stripe", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ webhookSecret: webhookSecret.trim() }) });
      const data = await res.json() as { ok?: boolean; webhookHint?: string; webhookConfigured?: boolean; error?: string };
      if (!res.ok) throw new Error(data.error ?? "Save failed");
      setWebhookConfigured(true);
      setWebhookHint(data.webhookHint ?? "");
      setWebhookSecret("");
      setWebhookMsg("✓ Webhook secret saved");
    } catch (err) {
      setWebhookMsg(err instanceof Error ? err.message : "Save failed");
    } finally {
      setWebhookSaving(false);
    }
  };

  const save = async () => {
    setSaving(true);
    setMessage("");

    const supportAmounts = supportAmountsText
      .split(",")
      .map((part) => numberValue(part.trim()))
      .filter((value) => value > 0);

    try {
      const res = await fetch("/api/settings/coin", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ ...economy, supportAmounts }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error ?? "Save failed");
      const recRes = await fetch("/api/settings/recommendations", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(recommendations),
      });
      const recData = await recRes.json();
      if (!recRes.ok) throw new Error(recData.error ?? "Save failed");

      const payoutRes = await fetch("/api/settings/payout", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payout),
      });
      const payoutData = await payoutRes.json();
      if (!payoutRes.ok) throw new Error(payoutData.error ?? "Save failed");

      setEconomy(data);
      setRecommendations(recData);
      setPayout(payoutData);
      setSupportAmountsText(data.supportAmounts.join(", "));
      setMessage("Paramèt yo sove.");
    } catch (error) {
      setMessage(error instanceof Error ? error.message : "Save failed");
    } finally {
      setSaving(false);
      setTimeout(() => setMessage(""), 3000);
    }
  };

  return (
    <div
      className="flex min-h-0 flex-1 flex-col overflow-y-auto"
      style={{ background: "#07080f" }}
    >
      <Topbar title="Paramèt" />
      <div className="max-w-5xl flex-1 space-y-5 p-5">
        <Section title="Boulva Coins">
          <div className="grid gap-4 md:grid-cols-3">
            <Field
              label="Coins pa Vòt"
              value={economy.coinsPerVote}
              onChange={setEconomyNumber("coinsPerVote")}
              type="number"
              hint="0 = gratis"
            />
            <Field
              label="Coins pa Agiman"
              value={economy.coinsPerArgument}
              onChange={setEconomyNumber("coinsPerArgument")}
              type="number"
              hint="Rezève pou frè agiman si backend lan aktive li"
            />
            <Field
              label="Frè Transfè"
              value={economy.transferFee}
              onChange={setEconomyNumber("transferFee")}
              type="number"
              hint="Coins ajoute kòm frè lè yon itilizatè transfere"
            />
          </div>
          <Field
            label="Montan Sipò Agiman"
            value={supportAmountsText}
            onChange={setSupportAmountsText}
            hint="Separe yo ak vigil: 10, 25, 50, 100"
          />
        </Section>

        <Section title="Rekonpans Coins">
          <div className="grid gap-4 md:grid-cols-4">
            <Field
              label="Bonus Enskripsyon"
              value={economy.signupBonus}
              onChange={setEconomyNumber("signupBonus")}
              type="number"
              hint="Rekòmande: 5"
            />
            <Field
              label="Claim Chak Jou"
              value={economy.dailyClaimBase}
              onChange={setEconomyNumber("dailyClaimBase")}
              type="number"
              hint="Montan jou 1"
            />
            <Field
              label="Bonus Streak"
              value={economy.dailyStreakBonus}
              onChange={setEconomyNumber("dailyStreakBonus")}
              type="number"
              hint="Ajoute pa jou streak"
            />
            <Field
              label="Maks Claim Jou"
              value={economy.dailyClaimMax}
              onChange={setEconomyNumber("dailyClaimMax")}
              type="number"
              hint="Plafon chak jou"
            />
          </div>
        </Section>

        <Section title="Rekòmandasyon Feed">
          <div className="grid gap-4 md:grid-cols-3">
            <Field
              label="Pèsonalizasyon %"
              value={recommendations.personalizedRatio}
              onChange={setRecommendationNumber("personalizedRatio")}
              type="number"
              hint="Rekòmande: 70"
            />
            <Field
              label="Dekouvèt %"
              value={recommendations.discoveryRatio}
              onChange={setRecommendationNumber("discoveryRatio")}
              type="number"
              hint="Rekòmande: 20"
            />
            <Field
              label="Pèspektiv Nouvo %"
              value={recommendations.perspectiveRatio}
              onChange={setRecommendationNumber("perspectiveRatio")}
              type="number"
              hint="Rekòmande: 10"
            />
            <Field
              label="Freshness Decay"
              value={recommendations.freshnessDecayHours}
              onChange={setRecommendationNumber("freshnessDecayHours")}
              type="number"
              hint="An èdtan"
            />
            <Field
              label="Pwa Tandans"
              value={recommendations.trendingWeight}
              onChange={setRecommendationNumber("trendingWeight")}
              type="number"
            />
            <Field
              label="Pwa Enterè"
              value={recommendations.interestWeight}
              onChange={setRecommendationNumber("interestWeight")}
              type="number"
            />
            <Field
              label="Pwa Divèsite"
              value={recommendations.diversityWeight}
              onChange={setRecommendationNumber("diversityWeight")}
              type="number"
            />
          </div>
        </Section>

        <Section title="Pake Coins pou Achte">
          <div className="space-y-3">
            {economy.coinPacks.map((pack, index) => (
              <div
                key={index}
                className="grid gap-3 rounded-lg p-3 md:grid-cols-[1fr_1fr_1fr_1fr_auto_auto]"
                style={{ background: "#0a0b18", border: "1px solid #1e2040" }}
              >
                <Field
                  label="Coins"
                  value={pack.coins}
                  onChange={(value) => updatePack(index, { coins: numberValue(value) })}
                  type="number"
                />
                <Field
                  label="Pri an santim"
                  value={pack.price}
                  onChange={(value) => updatePack(index, { price: numberValue(value) })}
                  type="number"
                  hint="999 = $9.99"
                />
                <Field
                  label="Etikèt Pri"
                  value={pack.label}
                  onChange={(value) => updatePack(index, { label: value })}
                />
                <Field
                  label="Ekonomi"
                  value={pack.savings}
                  onChange={(value) => updatePack(index, { savings: value })}
                />
                <label className="flex items-center gap-2 self-end pb-2 text-sm text-white">
                  <input
                    type="checkbox"
                    checked={pack.popular}
                    onChange={(e) => updatePack(index, { popular: e.target.checked })}
                  />
                  Popilè
                </label>
                <div className="self-end pb-1">
                  <IconButton
                    label="Retire pake"
                    onClick={() =>
                      setEconomy((current) => ({
                        ...current,
                        coinPacks: current.coinPacks.filter((_, i) => i !== index),
                      }))
                    }
                  >
                    <Trash2 size={15} />
                  </IconButton>
                </div>
              </div>
            ))}
          </div>
          <button
            type="button"
            onClick={() =>
              setEconomy((current) => ({
                ...current,
                coinPacks: [...current.coinPacks, emptyPack],
              }))
            }
            className="flex items-center gap-2 rounded-lg px-4 py-2 text-sm font-semibold text-white"
            style={{ background: "#15172a", border: "1px solid #1e2040" }}
          >
            <Plus size={15} />
            Ajoute pake
          </button>
        </Section>

        <Section title="Boost Agiman">
          <div className="space-y-3">
            {economy.boostTiers.map((tier, index) => (
              <div
                key={index}
                className="grid gap-3 rounded-lg p-3 md:grid-cols-[1fr_1fr_1fr_2fr_auto]"
                style={{ background: "#0a0b18", border: "1px solid #1e2040" }}
              >
                <Field
                  label="Non"
                  value={tier.label}
                  onChange={(value) => updateTier(index, { label: value })}
                />
                <Field
                  label="Kòd"
                  value={tier.tier}
                  onChange={(value) => updateTier(index, { tier: value })}
                  hint="24h, 4d, 1w"
                />
                <Field
                  label="Coins"
                  value={tier.coins}
                  onChange={(value) => updateTier(index, { coins: numberValue(value) })}
                  type="number"
                />
                <Field
                  label="Deskripsyon"
                  value={tier.desc}
                  onChange={(value) => updateTier(index, { desc: value })}
                />
                <div className="self-end pb-1">
                  <IconButton
                    label="Retire boost"
                    onClick={() =>
                      setEconomy((current) => ({
                        ...current,
                        boostTiers: current.boostTiers.filter((_, i) => i !== index),
                      }))
                    }
                  >
                    <Trash2 size={15} />
                  </IconButton>
                </div>
              </div>
            ))}
          </div>
          <button
            type="button"
            onClick={() =>
              setEconomy((current) => ({
                ...current,
                boostTiers: [...current.boostTiers, emptyTier],
              }))
            }
            className="flex items-center gap-2 rounded-lg px-4 py-2 text-sm font-semibold text-white"
            style={{ background: "#15172a", border: "1px solid #1e2040" }}
          >
            <Plus size={15} />
            Ajoute boost
          </button>
        </Section>

        {/* ── Peman Kreyatè ─────────────────────────────────── */}
        <Section title="Peman Kreyatè">
          {/* Info banner */}
          <div className="mb-4 rounded-lg px-4 py-3 text-xs"
            style={{ background: "#0a0b18", border: "1px solid #1e2040", color: "#94a3b8" }}>
            <strong style={{ color: "#a78bfa" }}>Kijan sa travay:</strong>{" "}
            Defini to konvèsyon coins → USD ak minimòm pou reklame. Lè <em>Mòd Otomatik</em> aktive
            ak MonCash konfigire, sistem nan voye lajan otomatikman. Nan mòd <em>Manuel</em>, admin
            voye lajan deyò app la, epi makre peman an &quot;Konplè&quot;.
          </div>

          <div className="grid gap-4 md:grid-cols-2">
            <Field
              label="To Coins → USD"
              value={payout.coinToUsdRate}
              onChange={(v) => setPayout((p) => ({ ...p, coinToUsdRate: parseFloat(v) || 0.001 }))}
              type="number"
              hint="0.006 = 1000 coins = $6.00"
            />
            <Field
              label="Minimòm pou reklame (coins)"
              value={payout.minPayoutCoins}
              onChange={(v) => setPayout((p) => ({ ...p, minPayoutCoins: Math.max(0, parseInt(v) || 1000) }))}
              type="number"
              hint="Rekòmande: 1000"
            />
          </div>

          <div className="grid gap-4 md:grid-cols-2 mt-4">
            {/* Payout mode */}
            <div>
              <label className="block text-xs font-semibold mb-2" style={{ color: "#94a3b8" }}>
                Mòd Peman
              </label>
              <div className="flex gap-2">
                {(["manual", "moncash_auto"] as const).map((mode) => (
                  <button
                    key={mode}
                    type="button"
                    onClick={() => setPayout((p) => ({ ...p, payoutMode: mode }))}
                    className="flex-1 py-2 rounded-lg text-xs font-semibold transition-all"
                    style={{
                      background: payout.payoutMode === mode ? "linear-gradient(90deg,#7c3aed,#a855f7)" : "#0a0b18",
                      color: payout.payoutMode === mode ? "white" : "#64748b",
                      border: payout.payoutMode === mode ? "none" : "1px solid #1e2040",
                    }}
                  >
                    {mode === "manual" ? "✋ Manuel" : "⚡ MonCash Otomatik"}
                  </button>
                ))}
              </div>
            </div>

            {/* MonCash environment */}
            <div>
              <label className="block text-xs font-semibold mb-2" style={{ color: "#94a3b8" }}>
                Anviwònman MonCash
              </label>
              <div className="flex gap-2">
                {(["sandbox", "live"] as const).map((env) => (
                  <button
                    key={env}
                    type="button"
                    onClick={() => setPayout((p) => ({ ...p, moncashEnvironment: env }))}
                    className="flex-1 py-2 rounded-lg text-xs font-semibold transition-all"
                    style={{
                      background: payout.moncashEnvironment === env ? (env === "live" ? "rgba(34,197,94,0.2)" : "rgba(96,165,250,0.2)") : "#0a0b18",
                      color: payout.moncashEnvironment === env ? (env === "live" ? "#22c55e" : "#60a5fa") : "#64748b",
                      border: `1px solid ${payout.moncashEnvironment === env ? (env === "live" ? "rgba(34,197,94,0.4)" : "rgba(96,165,250,0.4)") : "#1e2040"}`,
                    }}
                  >
                    {env === "sandbox" ? "🧪 Sandbox" : "🚀 Live"}
                  </button>
                ))}
              </div>
            </div>
          </div>

          {/* MonCash enable toggle */}
          <div className="mt-4 flex items-center gap-3 rounded-lg px-4 py-3"
            style={{ background: "#0a0b18", border: `1px solid ${payout.moncashEnabled ? "rgba(34,197,94,0.3)" : "#1e2040"}` }}>
            <label className="flex items-center gap-3 cursor-pointer flex-1">
              <div
                onClick={() => setPayout((p) => ({ ...p, moncashEnabled: !p.moncashEnabled }))}
                className="relative shrink-0 cursor-pointer"
                style={{
                  width: 44, height: 24, borderRadius: 12,
                  background: payout.moncashEnabled ? "#22c55e" : "#334155",
                  transition: "background 0.2s",
                }}
              >
                <div style={{
                  position: "absolute", top: 3, left: payout.moncashEnabled ? 23 : 3,
                  width: 18, height: 18, borderRadius: "50%", background: "white",
                  transition: "left 0.2s",
                }} />
              </div>
              <div>
                <div className="text-sm font-semibold" style={{ color: payout.moncashEnabled ? "#22c55e" : "#64748b" }}>
                  MonCash Otomatik {payout.moncashEnabled ? "AKTIVE" : "DEZAKTIVE"}
                </div>
                <div className="text-xs" style={{ color: "#475569" }}>
                  Kle API yo dwe ajoute nan Supabase Secrets: MONCASH_CLIENT_ID, MONCASH_CLIENT_SECRET
                </div>
              </div>
            </label>
          </div>

          {/* USD preview */}
          <div className="mt-3 text-xs" style={{ color: "#475569" }}>
            Egzanp: {payout.minPayoutCoins} coins (minimòm) ≈{" "}
            <strong style={{ color: "#a78bfa" }}>
              ${(payout.minPayoutCoins * payout.coinToUsdRate).toFixed(2)} USD
            </strong>
            {" · "}10 000 coins ≈{" "}
            <strong style={{ color: "#a78bfa" }}>
              ${(10000 * payout.coinToUsdRate).toFixed(2)} USD
            </strong>
          </div>
        </Section>

        {/* ── Stripe Keys ──────────────────────────────────────────── */}
        <Section title="Stripe / Peman">
          <div className="flex flex-col gap-4">
            <div className="flex items-center gap-3 rounded-xl p-4" style={{ background: stripeConfigured ? "rgba(16,185,129,0.06)" : "rgba(245,158,11,0.06)", border: `1px solid ${stripeConfigured ? "rgba(16,185,129,0.25)" : "rgba(245,158,11,0.25)"}` }}>
              <span style={{ fontSize: 18 }}>{stripeConfigured ? "✅" : "⚠️"}</span>
              <div>
                <p className="text-sm font-semibold" style={{ color: stripeConfigured ? "#10b981" : "#f59e0b", margin: 0 }}>
                  {stripeConfigured ? `Stripe configured — ${stripeHint}` : "Stripe not configured — payments disabled"}
                </p>
                <p className="text-xs" style={{ color: "#475569", margin: "2px 0 0" }}>
                  {stripeConfigured ? "Enter a new key below to rotate it." : "Get your secret key from dashboard.stripe.com/apikeys"}
                </p>
              </div>
            </div>

            <div>
              <label className="block text-xs font-bold uppercase tracking-widest mb-2" style={{ color: "#64748b" }}>
                Secret Key (sk_test_… or sk_live_…)
              </label>
              <div className="flex gap-3">
                <input
                  type="password"
                  value={stripeKey}
                  onChange={e => setStripeKey(e.target.value)}
                  placeholder={stripeConfigured ? "Enter new key to rotate…" : "sk_test_…"}
                  className="flex-1 rounded-xl px-4 py-2 text-sm"
                  style={{ background: "#0a0b18", border: "1px solid #1e2040", color: "#e2e8f0", outline: "none" }}
                  onFocus={e => (e.target.style.borderColor = "rgba(168,85,247,0.5)")}
                  onBlur={e  => (e.target.style.borderColor = "#1e2040")}
                />
                <button
                  onClick={saveStripe}
                  disabled={stripeSaving || !stripeKey.trim()}
                  className="flex items-center gap-2 rounded-xl px-5 py-2 text-sm font-semibold text-white transition-all disabled:opacity-50"
                  style={{ background: "linear-gradient(90deg,#7c3aed,#a855f7)", whiteSpace: "nowrap" }}
                >
                  <Save size={14} />
                  {stripeSaving ? "Saving…" : "Save Key"}
                </button>
              </div>
              {stripeMsg && (
                <p className="text-xs mt-2" style={{ color: stripeMsg.startsWith("✓") ? "#10b981" : "#f87171" }}>{stripeMsg}</p>
              )}
            </div>

            <p className="text-xs" style={{ color: "#334155" }}>
              The key is stored encrypted in your database. It is never exposed to the browser.
              Use sk_test_ for testing, sk_live_ for production.
            </p>

            {/* Webhook secret */}
            <div className="flex items-center gap-3 rounded-xl p-4" style={{ background: webhookConfigured ? "rgba(16,185,129,0.06)" : "rgba(245,158,11,0.06)", border: `1px solid ${webhookConfigured ? "rgba(16,185,129,0.25)" : "rgba(245,158,11,0.25)"}` }}>
              <span style={{ fontSize: 18 }}>{webhookConfigured ? "✅" : "⚠️"}</span>
              <div>
                <p className="text-sm font-semibold" style={{ color: webhookConfigured ? "#10b981" : "#f59e0b", margin: 0 }}>
                  {webhookConfigured ? `Webhook secret configured — ${webhookHint}` : "Webhook secret not configured — payments won't be recorded"}
                </p>
                <p className="text-xs" style={{ color: "#475569", margin: "2px 0 0" }}>
                  {webhookConfigured ? "Enter a new secret below to rotate it." : "Get the signing secret from Stripe Dashboard → Developers → Webhooks"}
                </p>
              </div>
            </div>

            <div>
              <label className="block text-xs font-bold uppercase tracking-widest mb-2" style={{ color: "#64748b" }}>
                Webhook Signing Secret (whsec_…)
              </label>
              <div className="flex gap-3">
                <input
                  type="password"
                  value={webhookSecret}
                  onChange={e => setWebhookSecret(e.target.value)}
                  placeholder={webhookConfigured ? "Enter new secret to rotate…" : "whsec_…"}
                  className="flex-1 rounded-xl px-4 py-2 text-sm"
                  style={{ background: "#0a0b18", border: "1px solid #1e2040", color: "#e2e8f0", outline: "none" }}
                  onFocus={e => (e.target.style.borderColor = "rgba(168,85,247,0.5)")}
                  onBlur={e  => (e.target.style.borderColor = "#1e2040")}
                />
                <button
                  onClick={saveWebhookSecret}
                  disabled={webhookSaving || !webhookSecret.trim()}
                  className="flex items-center gap-2 rounded-xl px-5 py-2 text-sm font-semibold text-white transition-all disabled:opacity-50"
                  style={{ background: "linear-gradient(90deg,#7c3aed,#a855f7)", whiteSpace: "nowrap" }}
                >
                  <Save size={14} />
                  {webhookSaving ? "Saving…" : "Save Secret"}
                </button>
              </div>
              {webhookMsg && (
                <p className="text-xs mt-2" style={{ color: webhookMsg.startsWith("✓") ? "#10b981" : "#f87171" }}>{webhookMsg}</p>
              )}
            </div>
          </div>
        </Section>

        <div className="flex items-center gap-3">
          <button
            onClick={save}
            disabled={loading || saving}
            className="flex items-center gap-2 rounded-xl px-6 py-3 text-sm font-semibold text-white transition-all disabled:opacity-60"
            style={{
              background: "linear-gradient(90deg,#7c3aed,#a855f7)",
              boxShadow: "0 0 20px rgba(124,58,237,0.3)",
            }}
          >
            <Save size={15} />
            {saving ? "Ap sove..." : "Sove Chanjman yo"}
          </button>
          {message && <span className="text-sm" style={{ color: "#94a3b8" }}>{message}</span>}
        </div>
      </div>
    </div>
  );
}
