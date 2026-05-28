"use client";

import { useState } from "react";
import { CheckCircle, Archive, Trash2, Plus, X, ExternalLink, ChevronUp, ChevronDown, ChevronsUpDown, ImageIcon } from "lucide-react";
import Link from "next/link";

type Option = { id: string; option_label: string; option_name: string; vote_count: number; image_url?: string | null };
type Matchup = {
  id: string; title_ht: string; title_en?: string; status: string; total_votes: number;
  created_at: string; published_at?: string; category_id?: string;
  category?: { name_ht: string } | { name_ht: string }[];
  options?: Option[];
};
type Category = { id: string; name_ht: string; name_en: string };

const TABS = ["Semèn sa", "Tout", "draft", "published", "closed", "archived"] as const;
const STATUS_LABELS: Record<string, string> = { draft: "Draft", published: "Pibliye", closed: "Fèmen", archived: "Achive" };
const STATUS_COLORS: Record<string, string> = { draft: "#a78bfa", published: "#22c55e", closed: "#94a3b8", archived: "#475569" };

function isThisWeek(dateStr: string): boolean {
  const d = new Date(dateStr);
  const now = new Date();
  const diffMs = now.getTime() - d.getTime();
  return diffMs >= 0 && diffMs <= 7 * 24 * 60 * 60 * 1000;
}

const VOTE_RANGES = [
  { label: "Tout vòt", value: "" },
  { label: "0 – 100", value: "0-100" },
  { label: "101 – 500", value: "101-500" },
  { label: "501 – 1 000", value: "501-1000" },
  { label: "1 001 – 5 000", value: "1001-5000" },
  { label: "5 000+", value: "5000+" },
];

const selectStyle: React.CSSProperties = {
  background: "#0e0f1e",
  border: "1px solid #1e2040",
  color: "#94a3b8",
  borderRadius: 6,
  padding: "5px 8px",
  fontSize: 12,
  width: "100%",
  outline: "none",
  appearance: "none" as const,
};

function Badge({ status }: { status: string }) {
  return (
    <span className="px-2 py-0.5 rounded-full text-xs font-semibold"
      style={{ background: `${STATUS_COLORS[status] ?? "#94a3b8"}22`, color: STATUS_COLORS[status] ?? "#94a3b8" }}>
      {STATUS_LABELS[status] ?? status}
    </span>
  );
}

function fmtDate(d: string) {
  return new Date(d).toLocaleDateString("fr-HT", { month: "short", day: "numeric", year: "numeric" });
}

function inVoteRange(votes: number, range: string): boolean {
  if (!range) return true;
  if (range === "5000+") return votes > 5000;
  const [lo, hi] = range.split("-").map(Number);
  return votes >= lo && votes <= hi;
}

async function doAction(id: string, action: string) {
  await fetch("/api/matchups/action", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ id, action }),
  });
}

const inputStyle: React.CSSProperties = {
  background: "#0e0f1e", border: "1px solid #1e2040", color: "#e2e8f0",
  borderRadius: 8, padding: "8px 12px", fontSize: 13, width: "100%", outline: "none",
};

function CreateModal({ categories, onClose, onCreate }: {
  categories: Category[];
  onClose: () => void;
  onCreate: (m: Matchup) => void;
}) {
  const [form, setForm] = useState({ title_ht: "", title_en: "", description_ht: "", category_id: "", option_a_name: "", option_b_name: "" });
  const [saving, setSaving] = useState(false);
  const [err, setErr] = useState("");

  const set = (k: keyof typeof form, v: string) => setForm(p => ({ ...p, [k]: v }));

  const save = async () => {
    if (!form.title_ht.trim() || !form.category_id || !form.option_a_name.trim() || !form.option_b_name.trim()) {
      setErr("Tit, kategorì, ak de opsyon yo obligatwa."); return;
    }
    setSaving(true); setErr("");
    const res = await fetch("/api/matchups/action", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ action: "create", ...form }),
    });
    const json = await res.json();
    if (!res.ok) { setErr(json.error ?? "Erè"); setSaving(false); return; }
    onCreate({
      id: json.matchup.id,
      title_ht: form.title_ht,
      title_en: form.title_en || undefined,
      status: "draft",
      total_votes: 0,
      created_at: json.matchup.created_at ?? new Date().toISOString(),
      category_id: form.category_id,
      category: categories.find(c => c.id === form.category_id)
        ? { name_ht: categories.find(c => c.id === form.category_id)!.name_ht }
        : undefined,
      options: [
        { id: "", option_label: "A", option_name: form.option_a_name, vote_count: 0 },
        { id: "", option_label: "B", option_name: form.option_b_name, vote_count: 0 },
      ],
    });
    onClose();
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center" style={{ background: "rgba(0,0,0,0.7)" }} onClick={onClose}>
      <div className="rounded-2xl p-6 w-full max-w-lg mx-4 space-y-4" style={{ background: "#0a0b18", border: "1px solid #1e2040" }} onClick={e => e.stopPropagation()}>
        <div className="flex items-center justify-between mb-1">
          <h2 className="text-base font-semibold text-white">Kreye Matchup</h2>
          <button onClick={onClose}><X size={16} style={{ color: "#64748b" }} /></button>
        </div>

        <div className="space-y-3">
          <div>
            <label className="block text-xs font-semibold mb-1" style={{ color: "#64748b" }}>Tit (Kreyòl) *</label>
            <input style={inputStyle} placeholder="ex: Messi vs Ronaldo" value={form.title_ht} onChange={e => set("title_ht", e.target.value)} />
          </div>
          <div>
            <label className="block text-xs font-semibold mb-1" style={{ color: "#64748b" }}>Tit (Angle)</label>
            <input style={inputStyle} placeholder="English title (optional)" value={form.title_en} onChange={e => set("title_en", e.target.value)} />
          </div>
          <div>
            <label className="block text-xs font-semibold mb-1" style={{ color: "#64748b" }}>Kategorì *</label>
            <select style={{ ...inputStyle, appearance: "none" as const }} value={form.category_id} onChange={e => set("category_id", e.target.value)}>
              <option value="">— chwazi kategorì —</option>
              {categories.map(c => <option key={c.id} value={c.id}>{c.name_ht}</option>)}
            </select>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-semibold mb-1" style={{ color: "#a855f7" }}>Opsyon A *</label>
              <input style={inputStyle} placeholder="ex: Messi" value={form.option_a_name} onChange={e => set("option_a_name", e.target.value)} />
            </div>
            <div>
              <label className="block text-xs font-semibold mb-1" style={{ color: "#ec4899" }}>Opsyon B *</label>
              <input style={inputStyle} placeholder="ex: Ronaldo" value={form.option_b_name} onChange={e => set("option_b_name", e.target.value)} />
            </div>
          </div>
          <div>
            <label className="block text-xs font-semibold mb-1" style={{ color: "#64748b" }}>Deskripsyon</label>
            <textarea style={{ ...inputStyle, resize: "vertical", minHeight: 72 }} placeholder="Kontèks oswa règ (opsyonèl)" value={form.description_ht} onChange={e => set("description_ht", e.target.value)} />
          </div>
        </div>

        {err && <p className="text-xs" style={{ color: "#ef4444" }}>{err}</p>}

        <div className="flex justify-end gap-2 pt-1">
          <button onClick={onClose} className="px-4 py-2 rounded-lg text-sm" style={{ color: "#64748b", border: "1px solid #1e2040" }}>Anile</button>
          <button onClick={save} disabled={saving} className="px-4 py-2 rounded-lg text-sm font-semibold flex items-center gap-1.5"
            style={{ background: "rgba(168,85,247,0.2)", color: "#a855f7", border: "1px solid rgba(168,85,247,0.4)", opacity: saving ? 0.6 : 1 }}>
            <Plus size={13} />{saving ? "Ap kreye…" : "Kreye"}
          </button>
        </div>
      </div>
    </div>
  );
}

export default function MatchupList({ matchups: initial, categories }: { matchups: Matchup[]; categories: Category[] }) {
  const [matchups, setMatchups] = useState(initial);
  const [activeTab, setActiveTab] = useState<typeof TABS[number]>("Semèn sa");
  const [loading, setLoading] = useState<string | null>(null);
  const [search, setSearch] = useState("");
  const [filters, setFilters] = useState({ title: "", category: "", votes: "", status: "" });
  const [sort, setSort] = useState<{ col: string; dir: "asc" | "desc" } | null>(null);
  const [showCreate, setShowCreate] = useState(false);

  const setFilter = (key: keyof typeof filters, value: string) =>
    setFilters((prev) => ({ ...prev, [key]: value }));

  const toggleSort = (col: string) =>
    setSort((prev) => prev?.col === col ? { col, dir: prev.dir === "asc" ? "desc" : "asc" } : { col, dir: "asc" });

  const catName = (m: Matchup) => {
    if (!m.category) return "—";
    const c = Array.isArray(m.category) ? m.category[0] : m.category;
    return c?.name_ht ?? "—";
  };

  const sortValue = (m: Matchup, col: string): string | number => {
    if (col === "title") return m.title_ht.toLowerCase();
    if (col === "category") return catName(m).toLowerCase();
    if (col === "votes") return m.total_votes ?? 0;
    if (col === "status") return m.status;
    if (col === "date") return m.created_at;
    return "";
  };

  const thisWeekCount = matchups.filter((m) => m.status === "published" && isThisWeek(m.created_at)).length;

  const filtered = matchups.filter((m) => {
    if (activeTab === "Semèn sa") return m.status === "published" && isThisWeek(m.created_at);
    if (activeTab !== "Tout" && m.status !== activeTab) return false;
    const q = search.toLowerCase();
    if (q && !`${m.title_ht} ${m.title_en ?? ""} ${catName(m)} ${m.status}`.toLowerCase().includes(q)) return false;
    if (filters.title && !`${m.title_ht} ${m.title_en ?? ""}`.toLowerCase().includes(filters.title.toLowerCase())) return false;
    if (filters.category && m.category_id !== filters.category) return false;
    if (filters.votes && !inVoteRange(m.total_votes ?? 0, filters.votes)) return false;
    if (filters.status && m.status !== filters.status) return false;
    return true;
  });

  const sorted = sort
    ? [...filtered].sort((a, b) => {
        const av = sortValue(a, sort.col);
        const bv = sortValue(b, sort.col);
        const cmp = typeof av === "number" && typeof bv === "number"
          ? av - bv
          : String(av).localeCompare(String(bv));
        return sort.dir === "asc" ? cmp : -cmp;
      })
    : filtered;

  const act = async (id: string, action: string) => {
    setLoading(`${id}-${action}`);
    await doAction(id, action);
    setMatchups((prev) =>
      action === "delete"
        ? prev.filter((m) => m.id !== id)
        : prev.map((m) =>
          m.id === id
            ? { ...m, status: action === "publish" ? "published" : action === "archive" ? "archived" : action === "close" ? "closed" : m.status }
            : m
        )
    );
    setLoading(null);
  };

  return (
    <div className="space-y-4">
      {showCreate && (
        <CreateModal
          categories={categories}
          onClose={() => setShowCreate(false)}
          onCreate={(m) => setMatchups(prev => [m, ...prev])}
        />
      )}

      {/* Search + tabs */}
      <div className="flex items-center gap-3 flex-wrap">
        <input
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="Chèche matchup…"
          className="px-3 py-2 rounded-lg text-sm text-white outline-none flex-1 max-w-xs"
          style={{ background: "#0e0f1e", border: "1px solid #1e2040" }}
        />
        <button
          onClick={() => setShowCreate(true)}
          className="flex items-center gap-1.5 px-3 py-2 rounded-lg text-xs font-semibold shrink-0"
          style={{ background: "rgba(168,85,247,0.15)", color: "#a855f7", border: "1px solid rgba(168,85,247,0.35)" }}
        >
          <Plus size={13} /> Kreye Matchup
        </button>
        <div className="flex gap-1 flex-wrap">
          {TABS.map((t) => {
            const count = t === "Semèn sa"
              ? thisWeekCount
              : t === "Tout"
              ? matchups.length
              : matchups.filter((m) => m.status === t).length;
            const label = t === "Semèn sa" ? `🗓 Semèn sa (${count})` : t === "Tout" ? `Tout (${count})` : `${STATUS_LABELS[t]} (${count})`;
            const isSemèn = t === "Semèn sa";
            return (
              <button key={t}
                onClick={() => setActiveTab(t)}
                className="px-3 py-1.5 rounded-lg text-xs font-semibold transition-colors capitalize"
                style={{
                  background: activeTab === t
                    ? isSemèn ? "rgba(34,197,94,0.2)" : "rgba(124,58,237,0.2)"
                    : "transparent",
                  color: activeTab === t
                    ? isSemèn ? "#22c55e" : "#a78bfa"
                    : "#475569",
                  border: activeTab === t
                    ? isSemèn ? "1px solid rgba(34,197,94,0.4)" : "1px solid rgba(124,58,237,0.4)"
                    : "1px solid transparent",
                }}>
                {label}
              </button>
            );
          })}
        </div>
      </div>

      {/* Table */}
      <div className="rounded-xl overflow-hidden" style={{ border: "1px solid #1e2040" }}>
        <table className="w-full text-sm">
          <thead>
            <tr style={{ background: "#0a0b18", borderBottom: "1px solid #1e2040" }}>
              {([
                ["title", "Tit"],
                ["category", "Kategorì"],
                ["votes", "Vòt"],
                ["status", "Estati"],
                ["date", "Dat"],
              ] as [string, string][]).map(([col, label]) => {
                const active = sort?.col === col;
                const Icon = active ? (sort!.dir === "asc" ? ChevronUp : ChevronDown) : ChevronsUpDown;
                return (
                  <th key={col}
                    onClick={() => toggleSort(col)}
                    className="px-4 py-3 text-left text-xs font-semibold uppercase cursor-pointer select-none"
                    style={{ color: active ? "#a78bfa" : "#475569" }}>
                    <span className="inline-flex items-center gap-1">
                      {label} <Icon size={12} />
                    </span>
                  </th>
                );
              })}
              <th className="px-4 py-3 text-left text-xs font-semibold uppercase" style={{ color: "#475569" }}>Aksyon</th>
            </tr>
            <tr style={{ background: "#0a0b18", borderBottom: "1px solid #1e2040" }}>
              {/* Title — free text */}
              <th className="px-4 pb-3">
                <div className="flex justify-center">
                  <input
                    value={filters.title}
                    onChange={(e) => setFilter("title", e.target.value)}
                    placeholder="Filtre tit…"
                    className="w-full px-2 py-1.5 rounded-md text-xs text-white outline-none normal-case"
                    style={{ background: "#0e0f1e", border: "1px solid #1e2040" }}
                  />
                </div>
              </th>

              {/* Category — select */}
              <th className="px-4 pb-3">
                <div className="flex justify-center">
                  <select value={filters.category} onChange={(e) => setFilter("category", e.target.value)} style={selectStyle}>
                    <option value="">Tout kategorì</option>
                    {categories.map((c) => (
                      <option key={c.id} value={c.id}>{c.name_ht}</option>
                    ))}
                  </select>
                </div>
              </th>

              {/* Votes — ranges select */}
              <th className="px-4 pb-3">
                <div className="flex justify-center">
                  <select value={filters.votes} onChange={(e) => setFilter("votes", e.target.value)} style={selectStyle}>
                    {VOTE_RANGES.map((r) => (
                      <option key={r.value} value={r.value}>{r.label}</option>
                    ))}
                  </select>
                </div>
              </th>

              {/* Status — select */}
              <th className="px-4 pb-3">
                <div className="flex justify-center">
                  <select value={filters.status} onChange={(e) => setFilter("status", e.target.value)} style={selectStyle}>
                    <option value="">Tout estati</option>
                    {Object.entries(STATUS_LABELS).map(([val, label]) => (
                      <option key={val} value={val}>{label}</option>
                    ))}
                  </select>
                </div>
              </th>

              {/* Date — empty (no per-column date filter, covered by search) */}
              <th className="px-4 pb-3" />

              {/* Reset */}
              <th className="px-4 pb-3">
                <div className="flex justify-center">
                  <button
                    onClick={() => setFilters({ title: "", category: "", votes: "", status: "" })}
                    className="px-2 py-1.5 rounded-md text-xs font-semibold"
                    style={{ color: "#64748b", border: "1px solid #1e2040" }}
                  >
                    Risèt
                  </button>
                </div>
              </th>
            </tr>
          </thead>
          <tbody>
            {sorted.length === 0 && (
              <tr><td colSpan={6} className="px-4 py-12 text-center" style={{ color: "#475569" }}>Okenn matchup yo</td></tr>
            )}
            {sorted.map((m) => (
              <tr key={m.id} style={{ borderBottom: "1px solid #1e2040", background: "#0e0f1e" }}>
                <td className="px-4 py-3 text-white" style={{ maxWidth: 340, minWidth: 200 }}>
                  <Link href={`/matchups/${m.id}`} className="group flex items-start gap-1.5 hover:opacity-80 transition-opacity">
                    <div className="min-w-0">
                      <div className="flex items-center gap-1.5 flex-wrap">
                        <span className="font-medium break-words group-hover:underline" style={{ textDecorationColor: "#a78bfa" }}>{m.title_ht}</span>
                        {m.options?.some((o) => o.image_url) && (
                          <span title="Imaj jenerasyon disponib" style={{ color: "#a855f7", flexShrink: 0 }}>
                            <ImageIcon size={12} />
                          </span>
                        )}
                      </div>
                      {m.title_en && <div className="break-words" style={{ color: "#475569", fontSize: 11 }}>{m.title_en}</div>}
                    </div>
                    <ExternalLink size={11} className="shrink-0 mt-1 opacity-0 group-hover:opacity-100 transition-opacity" style={{ color: "#a78bfa" }} />
                  </Link>
                </td>
                <td className="px-4 py-3" style={{ color: "#94a3b8", whiteSpace: "normal", minWidth: 100 }}>{catName(m)}</td>
                <td className="px-4 py-3 font-semibold text-white" style={{ whiteSpace: "nowrap" }}>{(m.total_votes ?? 0).toLocaleString()}</td>
                <td className="px-4 py-3" style={{ whiteSpace: "nowrap" }}><Badge status={m.status} /></td>
                <td className="px-4 py-3" style={{ color: "#64748b", whiteSpace: "nowrap" }}>{fmtDate(m.created_at)}</td>
                <td className="px-4 py-3">
                  <div className="flex items-center gap-1">
                    {m.status === "draft" && (
                      <button
                        onClick={() => act(m.id, "publish")}
                        disabled={!!loading}
                        title="Piblie"
                        className="p-1.5 rounded-lg transition-colors"
                        style={{ color: "#22c55e", background: "rgba(34,197,94,0.1)" }}
                      >
                        <CheckCircle size={14} />
                      </button>
                    )}
                    {m.status === "published" && (
                      <button
                        onClick={() => act(m.id, "close")}
                        disabled={!!loading}
                        title="Fèmen"
                        className="p-1.5 rounded-lg transition-colors"
                        style={{ color: "#94a3b8", background: "rgba(100,116,139,0.1)" }}
                      >
                        <Archive size={14} />
                      </button>
                    )}
                    {(m.status === "closed" || m.status === "draft") && (
                      <button
                        onClick={() => act(m.id, "archive")}
                        disabled={!!loading}
                        title="Achive"
                        className="p-1.5 rounded-lg transition-colors"
                        style={{ color: "#64748b", background: "rgba(100,116,139,0.08)" }}
                      >
                        <Archive size={14} />
                      </button>
                    )}
                    <button
                      onClick={() => { if (confirm("Efase matchup sa?")) act(m.id, "delete"); }}
                      disabled={!!loading}
                      title="Efase"
                      className="p-1.5 rounded-lg transition-colors"
                      style={{ color: "#ef4444", background: "rgba(239,68,68,0.08)" }}
                    >
                      <Trash2 size={14} />
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
