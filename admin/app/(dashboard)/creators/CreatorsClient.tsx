"use client";

import { useState } from "react";
import { Star, TrendingUp, Users, DollarSign, ChevronDown, ChevronUp, CheckCircle, XCircle, Award } from "lucide-react";

// ─── Types ────────────────────────────────────────────────────────────────────
type CreatorUser = {
  id: string;
  username: string;
  avatar_url?: string;
  followers_count: number;
  participation_count: number;
  victory_count: number;
  total_support_received: number;
  influence_score: number;
  verification_type?: string;
  verification_status?: string;
};

type Creator = {
  user_id: string;
  creator_tier: number;
  creator_score: number;
  trust_score: number;
  is_monetization_enabled: boolean;
  monetization_suspended: boolean;
  revenue_share_rate: number;
  total_earned_coins: number;
  pending_payout_coins: number;
  total_paid_out_coins: number;
  score_updated_at?: string;
  tier_updated_at?: string;
  user?: CreatorUser;
};

type Payout = {
  id: string;
  creator_user_id: string;
  coins_amount: number;
  payout_method?: string;
  payout_phone?: string;
  estimated_usd?: number;
  moncash_reference?: string;
  auto_processed?: boolean;
  status: string;
  requested_at: string;
  user?: { username: string; avatar_url?: string };
};

// ─── Constants ─────────────────────────────────────────────────────────────────
const TIERS = ["Itilizatè", "Kreyatè Entèmedyè", "Kreyatè Verifye", "Kreyatè Elit", "Ikòn Kiltirèl"];
const TIER_COLORS = ["#64748b", "#22c55e", "#3b82f6", "#a855f7", "#f59e0b"];
const TIER_ICONS = ["👤", "🌱", "✅", "⚡", "👑"];
const TABS = ["all", "monetized", "payouts"] as const;
const TAB_LABELS: Record<string, string> = {
  all: "Tout Kreyatè",
  monetized: "Monetize",
  payouts: "Peman an atant",
};

function fmtDate(d?: string) {
  if (!d) return "—";
  return new Date(d).toLocaleDateString("fr-HT", { month: "short", day: "numeric", year: "numeric" });
}

// ─── Main component ───────────────────────────────────────────────────────────
export default function CreatorsClient({
  creators: initial,
  pendingPayouts: initialPayouts,
}: {
  creators: Creator[];
  pendingPayouts: Payout[];
}) {
  const [creators, setCreators] = useState(initial);
  const [payouts, setPayouts] = useState(initialPayouts);
  const [activeTab, setActiveTab] = useState<typeof TABS[number]>("all");
  const [expanded, setExpanded] = useState<string | null>(null);
  const [loading, setLoading] = useState<string | null>(null);
  const [tierInput, setTierInput] = useState<Record<string, number>>({});

  // Filter by tab
  const filtered =
    activeTab === "monetized"
      ? creators.filter((c) => c.is_monetization_enabled)
      : creators;

  // Summary stats
  const totalMonetized = creators.filter((c) => c.is_monetization_enabled).length;
  const totalPending = payouts.reduce((s, p) => s + p.coins_amount, 0);

  // ─── Actions ────────────────────────────────────────────────────────────────
  const setTier = async (creator: Creator, newTier: number) => {
    setLoading(`tier-${creator.user_id}`);
    const res = await fetch("/api/creators/tier", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ userId: creator.user_id, tier: newTier }),
    });
    if (res.ok) {
      setCreators((prev) =>
        prev.map((c) =>
          c.user_id === creator.user_id
            ? {
                ...c,
                creator_tier: newTier,
                is_monetization_enabled: newTier >= 2,
                revenue_share_rate: newTier === 3 ? 0.8 : newTier === 4 ? c.revenue_share_rate : newTier >= 2 ? 0.7 : 0,
              }
            : c
        )
      );
    }
    setLoading(null);
  };

  const processPayout = async (payoutId: string, action: "complete" | "fail") => {
    setLoading(`payout-${payoutId}`);
    await fetch("/api/creators/tier", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ payoutId, payoutAction: action }),
    });
    setPayouts((prev) => prev.filter((p) => p.id !== payoutId));
    setLoading(null);
  };

  const autoProcess = async (payoutId: string) => {
    setLoading(`auto-${payoutId}`);
    const res = await fetch(
      `${process.env.NEXT_PUBLIC_SUPABASE_URL}/functions/v1/process-creator-payout`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY}`,
        },
        body: JSON.stringify({ payoutId }),
      }
    );
    const data = await res.json();
    if (data.ok && !data.manual) {
      // Auto-processed via MonCash — remove from queue
      setPayouts((prev) => prev.filter((p) => p.id !== payoutId));
    } else if (data.manual) {
      alert("Mòd Manuel aktif — voye lajan manyèlman, epi makre konplè.");
    } else {
      alert(`Erè: ${data.error}`);
    }
    setLoading(null);
  };

  const toggleSuspend = async (creator: Creator) => {
    setLoading(`suspend-${creator.user_id}`);
    const res = await fetch("/api/creators/tier", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ userId: creator.user_id, suspend: !creator.monetization_suspended }),
    });
    if (res.ok) {
      setCreators((prev) =>
        prev.map((c) =>
          c.user_id === creator.user_id
            ? { ...c, monetization_suspended: !c.monetization_suspended }
            : c
        )
      );
    }
    setLoading(null);
  };

  const inputStyle = { background: "#0a0b18", border: "1px solid #1e2040", color: "#D4D4D4" };

  return (
    <div className="space-y-4">
      {/* Summary cards */}
      <div className="grid grid-cols-3 gap-3">
        <_StatCard icon={<Users size={16} />} label="Total kreyatè" value={creators.length} color="#a855f7" />
        <_StatCard icon={<Star size={16} />} label="Monetize" value={totalMonetized} color="#22c55e" />
        <_StatCard icon={<DollarSign size={16} />} label="Peman an atant" value={`${totalPending} monè`} color="#f59e0b" />
      </div>

      {/* Tabs */}
      <div className="flex gap-2 flex-wrap">
        {TABS.map((t) => (
          <button
            key={t}
            onClick={() => setActiveTab(t)}
            className="px-4 py-2 rounded-lg text-xs font-semibold transition-all"
            style={{
              background: activeTab === t ? "linear-gradient(90deg,#7c3aed,#a855f7)" : "#0e0f1e",
              color: activeTab === t ? "white" : "#64748b",
              border: activeTab === t ? "none" : "1px solid #1e2040",
            }}
          >
            {TAB_LABELS[t]}
            {t === "payouts" && payouts.length > 0 && (
              <span className="ml-2 px-1.5 py-0.5 rounded-full text-xs"
                style={{ background: activeTab === t ? "rgba(255,255,255,0.2)" : "#1e2040", color: activeTab === t ? "white" : "#f59e0b" }}>
                {payouts.length}
              </span>
            )}
          </button>
        ))}
      </div>

      {/* Payout queue (only shown when payouts tab is active) */}
      {activeTab === "payouts" && (
        <div className="space-y-2">
          {payouts.length === 0 && (
            <div className="text-center py-10" style={{ color: "#475569" }}>
              <CheckCircle size={32} className="mx-auto mb-2 opacity-30" />
              <p className="text-sm">Pa gen peman an atant</p>
            </div>
          )}
          {payouts.map((p) => (
            <div key={p.id} className="rounded-xl overflow-hidden"
              style={{ border: "1px solid #1e2040", background: "#0e0f1e" }}>
              {/* Main row */}
              <div className="flex items-center gap-3 px-4 py-3">
                <div style={{ width: 36, height: 36, borderRadius: "50%", background: "linear-gradient(135deg,#7c3aed,#ec4899)", display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0 }}>
                  {p.user?.avatar_url
                    ? <img src={p.user.avatar_url} alt="" style={{ width: "100%", height: "100%", objectFit: "cover", borderRadius: "50%" }} />
                    : <span style={{ color: "#D4D4D4", fontWeight: "bold", fontSize: 13 }}>{p.user?.username?.[0]?.toUpperCase()}</span>}
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 flex-wrap">
                    <span style={{ color: "#D4D4D4", fontWeight: 700, fontSize: 13 }}>@{p.user?.username}</span>
                    <span className="px-2 py-0.5 rounded text-xs"
                      style={{ background: "rgba(96,165,250,0.12)", color: "#60a5fa" }}>
                      {p.payout_method ?? "—"}
                    </span>
                    {p.estimated_usd != null && (
                      <span className="px-2 py-0.5 rounded text-xs font-bold"
                        style={{ background: "rgba(34,197,94,0.12)", color: "#22c55e" }}>
                        ${p.estimated_usd.toFixed(2)} USD
                      </span>
                    )}
                  </div>
                  <div style={{ color: "#64748b", fontSize: 11, marginTop: 2 }}>
                    {p.coins_amount} coins
                    {p.payout_phone && <> · 📱 {p.payout_phone}</>}
                    {" · "}{fmtDate(p.requested_at)}
                  </div>
                </div>
                {/* Action buttons */}
                <div className="flex gap-2 shrink-0">
                  <button onClick={() => autoProcess(p.id)}
                    disabled={!!loading}
                    className="px-2 py-1.5 rounded-lg text-xs font-semibold"
                    style={{ color: "#a78bfa", background: "rgba(167,139,250,0.08)", border: "1px solid rgba(167,139,250,0.2)" }}
                    title="Trete otomatik (MonCash si aktive, osinon montre enfòmasyon)">
                    {loading === `auto-${p.id}` ? "..." : "⚡ Trete"}
                  </button>
                  <button onClick={() => processPayout(p.id, "complete")}
                    disabled={!!loading}
                    className="p-1.5 rounded-lg"
                    style={{ color: "#22c55e", background: "rgba(34,197,94,0.08)" }}
                    title="Makre konplè manyèlman">
                    {loading === `payout-${p.id}` ? <span style={{ fontSize: 10 }}>...</span> : <CheckCircle size={15} />}
                  </button>
                  <button onClick={() => processPayout(p.id, "fail")}
                    disabled={!!loading}
                    className="p-1.5 rounded-lg"
                    style={{ color: "#ef4444", background: "rgba(239,68,68,0.08)" }}
                    title="Makre echèk">
                    <XCircle size={15} />
                  </button>
                </div>
              </div>
              {/* Phone copy hint if present */}
              {p.payout_phone && (
                <div className="px-4 pb-3 flex items-center gap-2">
                  <span style={{ color: "#475569", fontSize: 11 }}>Telefòn pou voye:</span>
                  <code style={{ color: "#a78bfa", fontSize: 12, background: "rgba(167,139,250,0.08)", padding: "2px 8px", borderRadius: 4 }}>
                    {p.payout_phone}
                  </code>
                  <button
                    onClick={() => navigator.clipboard.writeText(p.payout_phone!)}
                    className="text-xs px-2 py-0.5 rounded"
                    style={{ color: "#64748b", background: "#0a0b18", border: "1px solid #1e2040" }}>
                    Kopye
                  </button>
                </div>
              )}
            </div>
          ))}
        </div>
      )}

      {/* Creator list */}
      {activeTab !== "payouts" && (
        <div className="space-y-3">
          {filtered.length === 0 && (
            <div className="text-center py-14" style={{ color: "#475569" }}>
              <Award size={36} className="mx-auto mb-2 opacity-30" />
              <p className="text-sm">Pa gen kreyatè nan kategori sa</p>
            </div>
          )}
          {filtered.map((c) => {
            const isExpanded = expanded === c.user_id;
            const tierColor = TIER_COLORS[c.creator_tier] ?? "#64748b";
            const tierIcon = TIER_ICONS[c.creator_tier] ?? "👤";

            return (
              <div key={c.user_id} className="rounded-xl overflow-hidden"
                style={{ border: "1px solid #1e2040", background: "#0e0f1e" }}>
                {/* Row header */}
                <div className="flex items-center gap-3 px-4 py-3">
                  {/* Avatar */}
                  <div style={{ width: 40, height: 40, borderRadius: "50%", flexShrink: 0, background: "linear-gradient(135deg,#7c3aed,#ec4899)", display: "flex", alignItems: "center", justifyContent: "center", overflow: "hidden" }}>
                    {c.user?.avatar_url
                      ? <img src={c.user.avatar_url} alt="" style={{ width: "100%", height: "100%", objectFit: "cover" }} />
                      : <span style={{ color: "#D4D4D4", fontWeight: "bold", fontSize: 14 }}>{c.user?.username?.[0]?.toUpperCase() ?? "?"}</span>}
                  </div>

                  {/* Info */}
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 flex-wrap">
                      <span style={{ color: "#D4D4D4", fontWeight: 700, fontSize: 14 }}>@{c.user?.username ?? "—"}</span>
                      <span style={{ fontSize: 14 }}>{tierIcon}</span>
                      <span className="px-2 py-0.5 rounded-full text-xs font-semibold"
                        style={{ background: `${tierColor}20`, color: tierColor }}>
                        {TIERS[c.creator_tier] ?? "—"}
                      </span>
                      {c.monetization_suspended && (
                        <span className="px-2 py-0.5 rounded-full text-xs font-semibold"
                          style={{ background: "rgba(239,68,68,0.12)", color: "#ef4444" }}>
                          Sispann
                        </span>
                      )}
                      {c.is_monetization_enabled && !c.monetization_suspended && (
                        <span className="px-2 py-0.5 rounded-full text-xs font-semibold"
                          style={{ background: "rgba(34,197,94,0.12)", color: "#22c55e" }}>
                          {Math.round(c.revenue_share_rate * 100)}% revni
                        </span>
                      )}
                    </div>
                    <div style={{ color: "#475569", fontSize: 11, marginTop: 2 }}>
                      Skò {c.creator_score}/100 · {c.user?.followers_count ?? 0} abòne · {c.total_earned_coins} monè touche
                    </div>
                  </div>

                  {/* Score ring */}
                  <div className="shrink-0 flex flex-col items-center" style={{ width: 44 }}>
                    <div style={{ position: "relative", width: 36, height: 36 }}>
                      <svg viewBox="0 0 36 36" style={{ width: 36, height: 36, transform: "rotate(-90deg)" }}>
                        <circle cx="18" cy="18" r="15" fill="none" stroke="#1e2040" strokeWidth="3" />
                        <circle cx="18" cy="18" r="15" fill="none" stroke={tierColor} strokeWidth="3"
                          strokeDasharray={`${(c.creator_score / 100) * 94.2} 94.2`} />
                      </svg>
                      <span style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center", color: "#D4D4D4", fontSize: 9, fontWeight: "bold" }}>
                        {c.creator_score}
                      </span>
                    </div>
                  </div>

                  {/* Expand toggle */}
                  <button onClick={() => setExpanded(isExpanded ? null : c.user_id)}
                    className="p-1.5 rounded-lg" style={{ color: "#94a3b8", background: "rgba(148,163,184,0.08)" }}>
                    {isExpanded ? <ChevronUp size={15} /> : <ChevronDown size={15} />}
                  </button>
                </div>

                {/* Expanded detail */}
                {isExpanded && (
                  <div className="px-4 pb-4 space-y-4" style={{ borderTop: "1px solid #1a1b2e" }}>
                    {/* Stats grid */}
                    <div className="grid grid-cols-3 gap-2 pt-3">
                      {[
                        { label: "Patisipasyon", v: c.user?.participation_count ?? 0 },
                        { label: "Viktwa", v: c.user?.victory_count ?? 0 },
                        { label: "Sipò resevwa", v: c.user?.total_support_received ?? 0 },
                        { label: "Coins touche", v: c.total_earned_coins },
                        { label: "An atant", v: c.pending_payout_coins },
                        { label: "Deja peye", v: c.total_paid_out_coins },
                      ].map(({ label, v }) => (
                        <div key={label} className="text-center p-2 rounded-lg" style={{ background: "#0a0b18" }}>
                          <div style={{ color: "#D4D4D4", fontWeight: "bold", fontSize: 14 }}>{v}</div>
                          <div style={{ color: "#64748b", fontSize: 10 }}>{label}</div>
                        </div>
                      ))}
                    </div>

                    {/* Tier change */}
                    <div className="space-y-2">
                      <div style={{ color: "#94a3b8", fontSize: 12 }}>Chanje nivo:</div>
                      <div className="flex gap-2 flex-wrap">
                        {TIERS.map((label, i) => (
                          <button
                            key={i}
                            onClick={() => setTier(c, i)}
                            disabled={!!loading || c.creator_tier === i}
                            className="px-3 py-1.5 rounded-lg text-xs font-semibold transition-all"
                            style={{
                              background: c.creator_tier === i ? `${TIER_COLORS[i]}25` : "#0a0b18",
                              color: c.creator_tier === i ? TIER_COLORS[i] : "#64748b",
                              border: `1px solid ${c.creator_tier === i ? TIER_COLORS[i] + "60" : "#1e2040"}`,
                              opacity: loading === `tier-${c.user_id}` ? 0.5 : 1,
                            }}
                          >
                            {TIER_ICONS[i]} {label}
                          </button>
                        ))}
                      </div>
                    </div>

                    {/* Suspend / un-suspend */}
                    <div className="flex gap-2">
                      <button
                        onClick={() => toggleSuspend(c)}
                        disabled={!!loading}
                        className="px-3 py-2 rounded-lg text-xs font-semibold flex items-center gap-1.5"
                        style={{
                          background: c.monetization_suspended ? "rgba(34,197,94,0.1)" : "rgba(239,68,68,0.08)",
                          color: c.monetization_suspended ? "#22c55e" : "#ef4444",
                          border: c.monetization_suspended ? "1px solid rgba(34,197,94,0.25)" : "1px solid rgba(239,68,68,0.2)",
                        }}
                      >
                        {c.monetization_suspended ? <><CheckCircle size={13} /> Reyaktive monetizasyon</> : <><XCircle size={13} /> Sispann monetizasyon</>}
                      </button>
                    </div>

                    <div style={{ color: "#334155", fontSize: 10 }}>
                      Dènye aktyalizasyon skò: {fmtDate(c.score_updated_at)} · Nivo chanje: {fmtDate(c.tier_updated_at)}
                    </div>
                  </div>
                )}
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}

// ─── Shared stat card ─────────────────────────────────────────────────────────
function _StatCard({ icon, label, value, color }: { icon: React.ReactNode; label: string; value: string | number; color: string }) {
  return (
    <div className="rounded-xl p-4" style={{ background: "#0e0f1e", border: "1px solid #1e2040" }}>
      <div className="flex items-center gap-2 mb-1" style={{ color }}>
        {icon}
        <span className="text-xs font-semibold">{label}</span>
      </div>
      <div style={{ color: "#D4D4D4", fontWeight: "bold", fontSize: 20 }}>{value}</div>
    </div>
  );
}
