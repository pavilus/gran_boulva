"use client";

import { useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { Trophy, Bot, Check, X, Loader2, ChevronDown, ChevronUp } from "lucide-react";

type Prediction = {
  id: string; title_ht: string; title_en?: string; option_a: string; option_b: string;
  deadline_at: string; status: string; winning_option?: string; total_votes: number;
  created_at: string; category_id?: string | null;
  category?: { name_ht: string } | { name_ht: string }[] | null;
};

type PredictionDraft = {
  id: string; title_ht: string; title_en?: string | null; option_a: string; option_b: string;
  description_ht?: string | null; deadline_at?: string | null; combined_score?: number | null;
  category_id?: string | null; source_platform?: string | null; risk_level?: string | null;
  selection_reason?: string | null; created_at: string;
  category?: { name_ht: string } | { name_ht: string }[] | null;
};

type Category = { id: string; name_ht: string; name_en: string };

// ─── Category color palette ───────────────────────────────────────────────────
const PALETTE = ["#a78bfa","#60a5fa","#34d399","#f97316","#ec4899","#fcd34d","#67e8f9","#f87171","#a3e635","#fb923c"];

function catColor(name: string): string {
  let h = 0;
  for (let i = 0; i < name.length; i++) h = name.charCodeAt(i) + ((h << 5) - h);
  return PALETTE[Math.abs(h) % PALETTE.length];
}

function CategoryChip({ name }: { name: string }) {
  const color = catColor(name);
  return (
    <span className="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-semibold"
      style={{ background: `${color}20`, color, border: `1px solid ${color}40`, fontSize: 10 }}>
      {name}
    </span>
  );
}

function getCatName(category: Prediction["category"]): string {
  if (!category) return "—";
  const c = Array.isArray(category) ? category[0] : category;
  return c?.name_ht ?? "—";
}

const TABS = ["active", "closed", "resolved"] as const;
const TAB_LABELS = { active: "Ouvè", closed: "Fèmen", resolved: "Rezoud" };

function fmtDate(d?: string | null) {
  if (!d) return "—";
  return new Date(d).toLocaleDateString("fr-HT", { month: "short", day: "numeric", year: "numeric" });
}

// ─── Resolve modal ────────────────────────────────────────────────────────────
function ResolveModal({ p, onClose, onResolved }: { p: Prediction; onClose: () => void; onResolved: (winner: string) => void }) {
  const [winner, setWinner] = useState<"A" | "B" | null>(null);
  const [loading, setLoading] = useState(false);

  const confirm = async () => {
    if (!winner) return;
    setLoading(true);
    await fetch("/api/predictions/action", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ id: p.id, action: "resolve", winner }),
    });
    onResolved(winner);
    setLoading(false);
  };

  return (
    <div className="fixed inset-0 flex items-center justify-center z-50" style={{ background: "rgba(0,0,0,0.7)" }}>
      <div className="rounded-2xl p-6 w-full max-w-md" style={{ background: "#0e0f1e", border: "1px solid #1e2040" }}>
        <div className="text-white font-bold text-lg mb-2">Rezoud Prediksyon</div>
        <div style={{ color: "#94a3b8", fontSize: 14, marginBottom: 20 }}>{p.title_ht}</div>
        <div className="space-y-3 mb-6">
          {(["A", "B"] as const).map((opt) => (
            <button key={opt} onClick={() => setWinner(opt)}
              className="w-full px-4 py-3 rounded-xl text-left font-semibold transition-all"
              style={{
                background: winner === opt ? "rgba(124,58,237,0.25)" : "#0a0b18",
                border: winner === opt ? "1px solid #7c3aed" : "1px solid #1e2040",
                color: winner === opt ? "#a78bfa" : "white",
              }}>
              {opt === "A" ? p.option_a : p.option_b}
            </button>
          ))}
        </div>
        <div className="flex gap-3">
          <button onClick={onClose} className="flex-1 px-4 py-2 rounded-xl text-sm"
            style={{ border: "1px solid #1e2040", color: "#94a3b8" }}>Anile</button>
          <button onClick={confirm} disabled={!winner || loading}
            className="flex-1 px-4 py-2 rounded-xl text-sm font-semibold text-white"
            style={{ background: winner ? "linear-gradient(90deg,#7c3aed,#a855f7)" : "#1e2040" }}>
            {loading ? "…" : "Konfime"}
          </button>
        </div>
      </div>
    </div>
  );
}

// ─── Scout draft card ─────────────────────────────────────────────────────────
function DraftCard({ draft, onAction }: { draft: PredictionDraft; onAction: (id: string, action: "approve" | "reject") => void }) {
  const [acting, setActing] = useState<"approve" | "reject" | null>(null);
  const catName = getCatName(draft.category);
  const color = catColor(catName !== "—" ? catName : "default");

  async function doAction(action: "approve" | "reject") {
    setActing(action);
    const res = await fetch("/api/scout/action", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ draft_id: draft.id, action }),
    });
    setActing(null);
    if (res.ok) onAction(draft.id, action);
    else {
      const d = await res.json().catch(() => ({}));
      alert(d.error ?? "Erè — eseye ankò");
    }
  }

  return (
    <div className="rounded-xl p-4 flex gap-4 items-start" style={{ background: "#0e0f1e", border: `1px solid ${color}30`, borderLeft: `3px solid ${color}` }}>
      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-2 mb-1 flex-wrap">
          {catName !== "—" && <CategoryChip name={catName} />}
          {draft.combined_score != null && (
            <span className="text-xs font-bold px-1.5 py-0.5 rounded" style={{ background: "rgba(124,58,237,0.15)", color: "#a78bfa" }}>
              {draft.combined_score.toFixed(1)}
            </span>
          )}
          {draft.deadline_at && (
            <span className="text-xs" style={{ color: "#64748b" }}>Limit: {fmtDate(draft.deadline_at)}</span>
          )}
        </div>
        <div className="text-white text-sm font-semibold leading-snug mb-1">{draft.title_ht}</div>
        <div className="text-xs" style={{ color: "#64748b" }}>
          <span style={{ color: "#a78bfa" }}>A:</span> {draft.option_a} &nbsp;·&nbsp; <span style={{ color: "#ec4899" }}>B:</span> {draft.option_b}
        </div>
        {draft.selection_reason && (
          <div className="mt-1 text-xs leading-snug" style={{ color: "#475569" }}>{draft.selection_reason}</div>
        )}
      </div>
      <div className="flex gap-2 shrink-0">
        {acting ? (
          <Loader2 size={14} color="#64748b" className="animate-spin" />
        ) : (
          <>
            <button onClick={() => doAction("approve")}
              className="flex items-center gap-1 px-3 py-1.5 rounded-lg text-xs font-semibold"
              style={{ background: "rgba(16,185,129,0.12)", color: "#10b981", border: "1px solid rgba(16,185,129,0.2)" }}>
              <Check size={11} /> Apwouve
            </button>
            <button onClick={() => doAction("reject")}
              className="flex items-center gap-1 px-3 py-1.5 rounded-lg text-xs font-semibold"
              style={{ background: "rgba(239,68,68,0.08)", color: "#ef4444", border: "1px solid rgba(239,68,68,0.15)" }}>
              <X size={11} /> Rejte
            </button>
          </>
        )}
      </div>
    </div>
  );
}

// ─── Main component ───────────────────────────────────────────────────────────
export default function PredictionList({
  predictions: initial, categories, predictionDrafts: initialDrafts,
}: {
  predictions: Prediction[];
  categories: Category[];
  predictionDrafts: PredictionDraft[];
}) {
  const router = useRouter();
  const [, startRefresh] = useTransition();
  const [preds, setPreds] = useState(initial);
  const [drafts, setDrafts] = useState(initialDrafts);
  const [activeTab, setActiveTab] = useState<typeof TABS[number]>("active");
  const [resolving, setResolving] = useState<Prediction | null>(null);
  const [draftsOpen, setDraftsOpen] = useState(true);

  // Dropdown filter state
  const [filters, setFilters] = useState({ title: "", category: "", status: "" });

  // Derive unique category names for dropdown
  const allCatNames = Array.from(new Set(preds.map((p) => getCatName(p.category)).filter((n) => n !== "—"))).sort();

  const filtered = preds.filter((p) => {
    if (p.status !== activeTab) return false;
    if (filters.title && !`${p.title_ht} ${p.title_en ?? ""}`.toLowerCase().includes(filters.title.toLowerCase())) return false;
    if (filters.category && getCatName(p.category) !== filters.category) return false;
    return true;
  });

  function handleDraftAction(id: string) {
    setDrafts((prev) => prev.filter((d) => d.id !== id));
    startRefresh(() => { router.refresh(); });
  }

  return (
    <div className="space-y-5">
      {resolving && (
        <ResolveModal
          p={resolving}
          onClose={() => setResolving(null)}
          onResolved={(winner) => {
            setPreds((prev) => prev.map((p) => p.id === resolving.id ? { ...p, status: "resolved", winning_option: winner } : p));
            setResolving(null);
          }}
        />
      )}

      {/* ── Scout prediction drafts ─────────────────────────────────── */}
      {drafts.length > 0 && (
        <div className="rounded-xl overflow-hidden" style={{ border: "1px solid rgba(99,102,241,0.3)", background: "rgba(99,102,241,0.04)" }}>
          <button
            className="w-full flex items-center gap-2 px-4 py-3"
            onClick={() => setDraftsOpen((o) => !o)}
          >
            <Bot size={14} color="#818cf8" />
            <span className="text-sm font-semibold" style={{ color: "#818cf8" }}>
              Sijèsyon Scout — Prediksyon ({drafts.length})
            </span>
            <span className="ml-auto" style={{ color: "#475569" }}>
              {draftsOpen ? <ChevronUp size={14} /> : <ChevronDown size={14} />}
            </span>
          </button>
          {draftsOpen && (
            <div className="px-4 pb-4 space-y-3">
              {drafts.map((d) => (
                <DraftCard key={d.id} draft={d} onAction={handleDraftAction} />
              ))}
            </div>
          )}
        </div>
      )}

      {/* ── Tabs ────────────────────────────────────────────────────── */}
      <div className="flex items-center gap-2">
        {TABS.map((t) => (
          <button key={t} onClick={() => setActiveTab(t)}
            className="px-4 py-2 rounded-lg text-xs font-semibold transition-colors"
            style={{
              background: activeTab === t ? "rgba(124,58,237,0.2)" : "transparent",
              color: activeTab === t ? "#a78bfa" : "#475569",
              border: activeTab === t ? "1px solid rgba(124,58,237,0.4)" : "1px solid transparent",
            }}>
            {TAB_LABELS[t]} ({preds.filter((p) => p.status === t).length})
          </button>
        ))}
      </div>

      {/* ── Filters ─────────────────────────────────────────────────── */}
      <div className="flex gap-2 flex-wrap">
        <input
          value={filters.title}
          onChange={(e) => setFilters((p) => ({ ...p, title: e.target.value }))}
          placeholder="Filtre pa tit…"
          className="px-3 py-2 rounded-lg text-xs text-white outline-none flex-1 min-w-[180px]"
          style={{ background: "#0e0f1e", border: "1px solid #1e2040" }}
        />
        <select
          value={filters.category}
          onChange={(e) => setFilters((p) => ({ ...p, category: e.target.value }))}
          className="px-3 py-2 rounded-lg text-xs text-white outline-none"
          style={{ background: "#0e0f1e", border: "1px solid #1e2040", minWidth: 160 }}
        >
          <option value="">Tout kategorì</option>
          {allCatNames.map((n) => (
            <option key={n} value={n}>{n}</option>
          ))}
        </select>
        {(filters.title || filters.category) && (
          <button
            onClick={() => setFilters({ title: "", category: "", status: "" })}
            className="px-3 py-2 rounded-lg text-xs font-semibold"
            style={{ color: "#64748b", border: "1px solid #1e2040" }}
          >
            Reset
          </button>
        )}
      </div>

      {/* ── Table ───────────────────────────────────────────────────── */}
      <div className="rounded-xl overflow-hidden" style={{ border: "1px solid #1e2040" }}>
        <table className="w-full text-sm">
          <thead>
            <tr style={{ background: "#0a0b18", borderBottom: "1px solid #1e2040" }}>
              {["Tit", "Opsyon A / B", "Kategorì", "Vòt", "Delè", "Aksyon"].map((h) => (
                <th key={h} className="px-4 py-3 text-left text-xs font-semibold uppercase" style={{ color: "#475569" }}>{h}</th>
              ))}
            </tr>
          </thead>
          <tbody>
            {filtered.length === 0 && (
              <tr><td colSpan={6} className="px-4 py-12 text-center" style={{ color: "#475569" }}>Pa gen prediksyon</td></tr>
            )}
            {filtered.map((p) => {
              const cat = getCatName(p.category);
              const color = catColor(cat !== "—" ? cat : "default");
              return (
                <tr key={p.id} style={{ borderBottom: "1px solid #1e2040", background: "#0e0f1e" }}>
                  <td className="px-4 py-3 text-white" style={{ maxWidth: 260 }}>
                    <div className="font-medium leading-tight">{p.title_ht}</div>
                    {p.winning_option && (
                      <div className="flex items-center gap-1 mt-1" style={{ color: "#fcd34d", fontSize: 11 }}>
                        <Trophy size={11} /> Gayan: {p.winning_option === "A" ? p.option_a : p.option_b}
                      </div>
                    )}
                  </td>
                  <td className="px-4 py-3" style={{ maxWidth: 220 }}>
                    <div className="text-xs" style={{ color: "#a78bfa" }}>A: {p.option_a}</div>
                    <div className="text-xs" style={{ color: "#ec4899" }}>B: {p.option_b}</div>
                  </td>
                  <td className="px-4 py-3">
                    {cat !== "—" ? <CategoryChip name={cat} /> : <span style={{ color: "#475569" }}>—</span>}
                  </td>
                  <td className="px-4 py-3 font-semibold text-white">{p.total_votes}</td>
                  <td className="px-4 py-3" style={{ color: "#64748b", whiteSpace: "nowrap" }}>{fmtDate(p.deadline_at)}</td>
                  <td className="px-4 py-3">
                    {p.status !== "resolved" && (
                      <button
                        onClick={() => setResolving(p)}
                        className="flex items-center gap-1 px-3 py-1.5 rounded-lg text-xs font-semibold"
                        style={{ background: `${color}18`, color, border: `1px solid ${color}40` }}
                      >
                        <Trophy size={12} /> Rezoud
                      </button>
                    )}
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </div>
  );
}
