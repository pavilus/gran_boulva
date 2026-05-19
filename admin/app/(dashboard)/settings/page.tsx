"use client";

import Topbar from "@/components/Topbar";
import { useEffect, useState } from "react";
import { Plus, Save, Trash2 } from "lucide-react";

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
  supportAmounts: number[];
  boostTiers: BoostTier[];
  coinPacks: CoinPack[];
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
  supportAmounts: [10, 25, 50, 100],
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
    { coins: 1000, price: 999, label: "$9.99", savings: "", popular: false },
    {
      coins: 2500,
      price: 1999,
      label: "$19.99",
      savings: "Ekonomize 20%",
      popular: true,
    },
  ],
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
  const [supportAmountsText, setSupportAmountsText] = useState("10, 25, 50, 100");
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState("");

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
    return () => {
      alive = false;
    };
  }, []);

  const setEconomyNumber = (key: keyof Pick<CoinEconomy, "coinsPerVote" | "coinsPerArgument" | "transferFee">) => (value: string) => {
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
      setEconomy(data);
      setSupportAmountsText(data.supportAmounts.join(", "));
      setMessage("Paramèt coins yo sove.");
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
