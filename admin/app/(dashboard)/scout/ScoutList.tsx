"use client";

import { useState, useTransition, useRef } from "react";
import { useRouter } from "next/navigation";
import {
  Bot, RefreshCw, Check, X, ChevronDown, ChevronUp,
  Loader2, TrendingUp, Flame, Shield, Upload, ImageIcon,
  Save, ExternalLink, Tag, Users, Lightbulb, Zap, Eye,
  Star, Globe,
} from "lucide-react";

type Category = { id: string; name_ht: string; name_en: string };

type Draft = {
  id: string;
  type: "matchup" | "prediction" | null;
  title_ht: string;
  title_en: string | null;
  option_a: string;
  option_b: string;
  description_ht: string | null;
  image_url_a: string | null;
  image_url_b: string | null;
  category_id: string | null;
  category: { name_ht: string } | { name_ht: string }[] | null;
  combined_score: number | null;
  trend_score: number | null;
  debate_score: number | null;
  safety_score: number | null;
  popularity_score: number | null;
  virality_score: number | null;
  uniqueness_score: number | null;
  relevance_score: number | null;
  prediction_score: number | null;
  risk_level: string | null;
  status: string;
  created_at: string;
  deadline_at: string | null;
  source_links: string[] | null;
  source_platform: string | null;
  trending_keywords: string[] | null;
  detected_entities: string[] | null;
  selection_reason: string | null;
};

const riskColor: Record<string, string> = { low: "#10b981", medium: "#f59e0b", high: "#ef4444" };

const SCORES = [
  { key: "popularity_score",  label: "Popularite",  icon: Star,       color: "#fcd34d" },
  { key: "trend_score",       label: "Resan",       icon: TrendingUp, color: "#a78bfa" },
  { key: "debate_score",      label: "Debat",       icon: Flame,      color: "#ec4899" },
  { key: "virality_score",    label: "Viralite",    icon: Zap,        color: "#f97316" },
  { key: "uniqueness_score",  label: "Inisyalite",  icon: RefreshCw,  color: "#67e8f9" },
  { key: "relevance_score",   label: "Relevan",     icon: Globe,      color: "#6ee7b7" },
  { key: "safety_score",      label: "Sekirite",    icon: Shield,     color: "#10b981" },
  { key: "prediction_score",  label: "Prediksyon",  icon: Eye,        color: "#818cf8" },
] as const;

function ScoreBar({ value, color, label, Icon }: { value: number | null; color: string; label: string; Icon: any }) {
  const pct = Math.round(((value ?? 0) / 10) * 100);
  return (
    <div className="flex items-center gap-2">
      <Icon size={10} color={color} className="shrink-0" />
      <span style={{ color: "#475569", fontSize: 10, minWidth: 62 }}>{label}</span>
      <div className="flex-1 rounded-full overflow-hidden" style={{ height: 3, background: "#1e2040" }}>
        <div className="h-full rounded-full transition-all" style={{ width: `${pct}%`, background: color }} />
      </div>
      <span style={{ color, fontSize: 10, minWidth: 22, textAlign: "right" }}>
        {value?.toFixed(1) ?? "—"}
      </span>
    </div>
  );
}

function Chip({ label, color = "#475569", bg = "#1e2040" }: { label: string; color?: string; bg?: string }) {
  return (
    <span
      className="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium"
      style={{ color, background: bg, fontSize: 10 }}
    >
      {label}
    </span>
  );
}

function ImagePicker({ label, current, onChange }: { label: string; current: string | null; onChange: (url: string | null) => void }) {
  const inputRef = useRef<HTMLInputElement>(null);
  const [uploading, setUploading] = useState(false);
  const [preview, setPreview] = useState<string | null>(current);
  const [error, setError] = useState<string | null>(null);

  async function handleFile(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (!file) return;
    setError(null);
    if (file.size > 10 * 1024 * 1024) {
      setError("Imaj la twò gwo. Maksimòm lan se 10 MB.");
      e.target.value = "";
      return;
    }
    setPreview(URL.createObjectURL(file));
    setUploading(true);
    const fd = new FormData();
    fd.append("file", file);
    try {
      const res = await fetch("/api/scout/upload", { method: "POST", body: fd });
      const data = await res.json().catch(() => ({}));
      if (!res.ok || !data.url) throw new Error(data.error ?? "Upload failed");
      onChange(data.url);
    } catch (err) {
      setPreview(current);
      setError(err instanceof Error ? err.message : "Upload failed");
    } finally {
      setUploading(false);
      e.target.value = "";
    }
  }

  function cancelImage() {
    setPreview(null);
    setError(null);
    onChange(null);
  }

  return (
    <div className="flex flex-col gap-2">
      <div className="text-xs font-medium" style={{ color: "#64748b" }}>{label}</div>
      <div
        className="relative rounded-xl overflow-hidden cursor-pointer flex items-center justify-center"
        style={{ height: 110, background: "#13152a", border: "1px dashed #1e2040" }}
        onClick={() => inputRef.current?.click()}
      >
        {preview ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img src={preview} alt={label} className="w-full h-full object-cover" />
        ) : (
          <div className="flex flex-col items-center gap-1.5">
            <ImageIcon size={20} color="#334155" />
            <span style={{ color: "#334155", fontSize: 11 }}>Klike pou chwazi</span>
          </div>
        )}
        {uploading && (
          <div className="absolute inset-0 flex items-center justify-center" style={{ background: "rgba(7,8,15,0.7)" }}>
            <Loader2 size={20} color="#a78bfa" className="animate-spin" />
          </div>
        )}
        {preview && !uploading && (
          <div className="absolute inset-0 flex items-center justify-center opacity-0 hover:opacity-100 transition-opacity" style={{ background: "rgba(7,8,15,0.55)" }}>
            <Upload size={16} color="white" />
          </div>
        )}
      </div>
      <div className="flex items-center justify-between">
        <span style={{ color: error ? "#f87171" : "#334155", fontSize: 10 }}>{error ?? "JPG / PNG / WebP · maks 10 MB"}</span>
        <span
          className="px-2 py-0.5 rounded font-mono text-xs"
          style={{ background: "rgba(124,58,237,0.1)", color: "#a78bfa", fontSize: 10 }}
        >
          800 × 900 px
        </span>
      </div>
      {preview && !uploading && (
        <button
          type="button"
          onClick={cancelImage}
          className="self-start px-2 py-1 rounded-md text-xs font-semibold"
          style={{ color: "#94a3b8", border: "1px solid #1e2040" }}
        >
          Retire imaj
        </button>
      )}
      <input ref={inputRef} type="file" accept="image/*" className="hidden" onChange={handleFile} />
    </div>
  );
}

function Field({ label, value, onChange, multiline = false }: { label: string; value: string; onChange: (v: string) => void; multiline?: boolean }) {
  const shared = {
    value,
    onChange: (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => onChange(e.target.value),
    className: "w-full text-xs text-white rounded-lg px-3 py-2",
    style: { background: "#13152a", border: "1px solid #1e2040", outline: "none" } as React.CSSProperties,
  };
  return (
    <div>
      <div className="text-xs mb-1" style={{ color: "#64748b" }}>{label}</div>
      {multiline ? <textarea {...shared} rows={3} style={{ ...shared.style, resize: "none" }} /> : <input {...shared} />}
    </div>
  );
}

function DraftRow({ draft: initial, categories, onAction }: { draft: Draft; categories: Category[]; onAction: (id: string, action: "approve" | "reject") => void }) {
  const [expanded, setExpanded] = useState(false);
  const [draft, setDraft] = useState(initial);
  const [saving, setSaving] = useState(false);
  const [acting, setActing] = useState<"approve" | "reject" | null>(null);
  const [saved, setSaved] = useState(false);
  const [tab, setTab] = useState<"edit" | "intel">("edit");

  const isPending = draft.status === "pending";
  const risk = draft.risk_level ?? "low";
  const catName = (Array.isArray(draft.category) ? draft.category[0]?.name_ht : draft.category?.name_ht) ?? "—";
  const isPrediction = draft.type === "prediction";
  const isDirty =
    draft.title_ht !== initial.title_ht ||
    draft.title_en !== initial.title_en ||
    draft.option_a !== initial.option_a ||
    draft.option_b !== initial.option_b ||
    draft.description_ht !== initial.description_ht ||
    draft.image_url_a !== initial.image_url_a ||
    draft.image_url_b !== initial.image_url_b ||
    draft.category_id !== initial.category_id ||
    draft.deadline_at !== initial.deadline_at;

  function set(field: keyof Draft, value: any) {
    setDraft((p) => ({ ...p, [field]: value }));
    setSaved(false);
  }

  function cancelEdits() {
    setDraft(initial);
    setSaved(false);
  }

  async function save() {
    setSaving(true);
    await fetch("/api/scout/update", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        draft_id: draft.id,
        title_ht: draft.title_ht,
        title_en: draft.title_en,
        option_a: draft.option_a,
        option_b: draft.option_b,
        description_ht: draft.description_ht,
        image_url_a: draft.image_url_a,
        image_url_b: draft.image_url_b,
        category_id: draft.category_id,
        deadline_at: draft.deadline_at,
      }),
    });
    setSaving(false);
    setSaved(true);
  }

  async function doAction(action: "approve" | "reject") {
    setActing(action);
    try {
      const res = await fetch("/api/scout/action", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ draft_id: draft.id, action }),
      });
      const data = await res.json().catch(() => ({}));
      if (res.ok) {
        onAction(draft.id, action);
      } else {
        alert(data.error ?? `Erè ${res.status} — eseye ankò`);
      }
    } catch (err) {
      alert(err instanceof Error ? err.message : "Erè rezo — eseye ankò");
    } finally {
      setActing(null);
    }
  }

  const sources = draft.source_links?.filter(Boolean) ?? [];
  const keywords = draft.trending_keywords?.filter(Boolean) ?? [];
  const entities = draft.detected_entities?.filter(Boolean) ?? [];

  return (
    <div className="rounded-xl overflow-hidden" style={{ background: "#0e0f1e", border: "1px solid #1e2040" }}>
      {/* Header */}
      <div className="flex items-center gap-3 p-4 cursor-pointer" onClick={() => setExpanded((p) => !p)}>
        <div
          className="flex items-center justify-center rounded-xl shrink-0 font-bold text-sm"
          style={{ width: 44, height: 44, background: "rgba(124,58,237,0.15)", color: "#a78bfa" }}
        >
          {draft.combined_score?.toFixed(1) ?? "—"}
        </div>
        <div className="flex-1 min-w-0">
          <div className="text-white text-sm font-medium leading-tight">{draft.title_ht}</div>
          <div className="flex items-center gap-2 mt-1 flex-wrap">
            <span
              className="px-1.5 py-0.5 rounded font-semibold"
              style={{ background: isPrediction ? "rgba(99,102,241,0.15)" : "rgba(124,58,237,0.15)", color: isPrediction ? "#818cf8" : "#a78bfa", fontSize: 10 }}
            >
              {isPrediction ? "Prediksyon" : "Matchup"}
            </span>
            <span style={{ color: "#475569", fontSize: 11 }}>{catName}</span>
            <span className="text-xs px-1.5 py-0.5 rounded font-medium" style={{ background: `${riskColor[risk]}1a`, color: riskColor[risk], fontSize: 10 }}>
              {risk}
            </span>
            {draft.source_platform && (
              <span style={{ color: "#334155", fontSize: 10 }}>
                <Globe size={9} className="inline mr-0.5" />{draft.source_platform}
              </span>
            )}
            <span style={{ color: "#334155", fontSize: 10 }}>{draft.option_a} vs {draft.option_b}</span>
          </div>
          {draft.selection_reason && (
            <div className="mt-0.5 text-xs leading-tight line-clamp-1" style={{ color: "#334155" }}>
              <Lightbulb size={9} className="inline mr-1" />{draft.selection_reason}
            </div>
          )}
        </div>
        <div className="flex items-center gap-2 shrink-0" onClick={(e) => e.stopPropagation()}>
          {isPending && !acting && (
            <>
              <button onClick={() => doAction("approve")} className="text-xs px-3 py-1.5 rounded-lg font-medium" style={{ background: "rgba(16,185,129,0.12)", color: "#10b981", border: "1px solid rgba(16,185,129,0.2)" }}>
                <Check size={12} className="inline mr-1" />Apwouve
              </button>
              <button onClick={() => doAction("reject")} className="text-xs px-3 py-1.5 rounded-lg font-medium" style={{ background: "rgba(239,68,68,0.1)", color: "#ef4444", border: "1px solid rgba(239,68,68,0.15)" }}>
                <X size={12} className="inline mr-1" />Rejte
              </button>
            </>
          )}
          {acting && <Loader2 size={14} color="#64748b" className="animate-spin" />}
          {!isPending && (
            <span className="text-xs px-2 py-1 rounded font-medium" style={{ background: draft.status === "approved" ? "rgba(16,185,129,0.12)" : "rgba(100,116,139,0.12)", color: draft.status === "approved" ? "#10b981" : "#64748b" }}>
              {draft.status === "approved" ? "Apwouve" : "Rejte"}
            </span>
          )}
          <div style={{ color: "#475569" }}>{expanded ? <ChevronUp size={16} /> : <ChevronDown size={16} />}</div>
        </div>
      </div>

      {/* Expanded */}
      {expanded && (
        <div style={{ borderTop: "1px solid #1e2040" }}>
          {/* Tabs */}
          <div className="flex gap-1 px-4 pt-3">
            {(["edit", "intel"] as const).map((t) => (
              <button
                key={t}
                onClick={() => setTab(t)}
                className="text-xs px-3 py-1.5 rounded-lg font-medium"
                style={{
                  background: tab === t ? "rgba(124,58,237,0.15)" : "transparent",
                  color: tab === t ? "#a78bfa" : "#475569",
                  border: tab === t ? "1px solid rgba(124,58,237,0.25)" : "1px solid transparent",
                }}
              >
                {t === "edit" ? "Edite" : "Intel & Sous"}
              </button>
            ))}
          </div>

          {/* Edit tab */}
          {tab === "edit" && (
            <div className="p-4 space-y-4">
              <div className="grid gap-4" style={{ gridTemplateColumns: "1fr 1fr" }}>
                <ImagePicker key={`a-${draft.image_url_a ?? "empty"}`} label={`Imaj — ${draft.option_a || "Opsyon A"}`} current={draft.image_url_a} onChange={(url) => set("image_url_a", url)} />
                <ImagePicker key={`b-${draft.image_url_b ?? "empty"}`} label={`Imaj — ${draft.option_b || "Opsyon B"}`} current={draft.image_url_b} onChange={(url) => set("image_url_b", url)} />
              </div>
              <div className="grid gap-3" style={{ gridTemplateColumns: "2fr 1fr" }}>
                <Field label="Tit (Kreyòl)" value={draft.title_ht} onChange={(v) => set("title_ht", v)} />
                <Field label="Tit (Angle)" value={draft.title_en ?? ""} onChange={(v) => set("title_en", v)} />
              </div>
              <div className="grid gap-3" style={{ gridTemplateColumns: "1fr 1fr" }}>
                <Field label="Opsyon A" value={draft.option_a} onChange={(v) => set("option_a", v)} />
                <Field label="Opsyon B" value={draft.option_b} onChange={(v) => set("option_b", v)} />
              </div>
              <div className="grid gap-3" style={{ gridTemplateColumns: "2fr 1fr" }}>
                <Field label="Deskripsyon (Kreyòl)" value={draft.description_ht ?? ""} onChange={(v) => set("description_ht", v)} multiline />
                <div className="space-y-3">
                  <div>
                    <div className="text-xs mb-1" style={{ color: "#64748b" }}>Kategorì</div>
                    <select
                      value={draft.category_id ?? ""}
                      onChange={(e) => {
                        const cat = categories.find((c) => c.id === e.target.value);
                        setDraft((p) => ({ ...p, category_id: e.target.value || null, category: cat ? { name_ht: cat.name_ht } : null }));
                        setSaved(false);
                      }}
                      className="w-full text-xs text-white rounded-lg px-3 py-2"
                      style={{ background: "#13152a", border: "1px solid #1e2040", outline: "none" }}
                    >
                      <option value="">— Chwazi —</option>
                      {categories.map((c) => <option key={c.id} value={c.id}>{c.name_ht}</option>)}
                    </select>
                  </div>
                  {isPrediction && (
                    <div>
                      <div className="text-xs mb-1" style={{ color: "#64748b" }}>Dat limit rezilta</div>
                      <input
                        type="date"
                        value={draft.deadline_at ? draft.deadline_at.slice(0, 10) : ""}
                        onChange={(e) => { set("deadline_at", e.target.value ? `${e.target.value}T00:00:00Z` : null); }}
                        className="w-full text-xs text-white rounded-lg px-3 py-2"
                        style={{ background: "#13152a", border: "1px solid #1e2040", outline: "none", colorScheme: "dark" }}
                      />
                    </div>
                  )}
                </div>
              </div>
              <div className="flex items-center gap-3">
                <button onClick={save} disabled={saving} className="flex items-center gap-2 text-xs px-4 py-2 rounded-lg font-medium disabled:opacity-50" style={{ background: "rgba(124,58,237,0.15)", color: "#a78bfa", border: "1px solid rgba(124,58,237,0.3)" }}>
                  {saving ? <Loader2 size={12} className="animate-spin" /> : <Save size={12} />}
                  {saving ? "K ap sove…" : saved ? "Sove ✓" : "Sove chanjman"}
                </button>
                <button
                  onClick={cancelEdits}
                  disabled={!isDirty || saving}
                  className="text-xs px-4 py-2 rounded-lg font-medium disabled:opacity-40"
                  style={{ color: "#94a3b8", border: "1px solid #1e2040" }}
                >
                  Anile
                </button>
                {isPending && !acting && (
                  <>
                    <button onClick={() => doAction("approve")} className="flex items-center gap-2 text-xs px-4 py-2 rounded-lg font-medium" style={{ background: "linear-gradient(90deg,#10b981,#34d399)", color: "white" }}>
                      <Check size={12} />Konfime & Apwouve
                    </button>
                    <button onClick={() => doAction("reject")} className="text-xs px-4 py-2 rounded-lg font-medium" style={{ background: "rgba(239,68,68,0.1)", color: "#ef4444", border: "1px solid rgba(239,68,68,0.15)" }}>
                      Rejte
                    </button>
                  </>
                )}
                {acting && <Loader2 size={14} color="#64748b" className="animate-spin" />}
              </div>
            </div>
          )}

          {/* Intel tab */}
          {tab === "intel" && (
            <div className="p-4 space-y-4">
              {/* Reason */}
              {draft.selection_reason && (
                <div className="rounded-xl p-3" style={{ background: "rgba(124,58,237,0.08)", border: "1px solid rgba(124,58,237,0.15)" }}>
                  <div className="flex items-center gap-1.5 mb-1">
                    <Lightbulb size={11} color="#a78bfa" />
                    <span className="text-xs font-semibold" style={{ color: "#a78bfa" }}>Poukisa sijèsyon sa</span>
                  </div>
                  <p className="text-xs leading-relaxed" style={{ color: "#94a3b8" }}>{draft.selection_reason}</p>
                </div>
              )}

              <div className="grid gap-4" style={{ gridTemplateColumns: "1fr 1fr" }}>
                {/* Left: scores */}
                <div className="space-y-2">
                  <div className="text-xs font-semibold mb-2" style={{ color: "#64748b" }}>Nòt yo</div>
                  {SCORES.map(({ key, label, icon: Icon, color }) => (
                    <ScoreBar key={key} value={(draft as any)[key]} color={color} label={label} Icon={Icon} />
                  ))}
                  <div className="flex items-center justify-between pt-2" style={{ borderTop: "1px solid #1e2040" }}>
                    <span className="text-xs" style={{ color: "#64748b" }}>Nòt total</span>
                    <span className="font-bold text-white">{draft.combined_score?.toFixed(1) ?? "—"}<span style={{ color: "#475569", fontSize: 11, fontWeight: 400 }}>/10</span></span>
                  </div>
                </div>

                {/* Right: metadata */}
                <div className="space-y-4">
                  {/* Platform */}
                  {draft.source_platform && (
                    <div>
                      <div className="flex items-center gap-1.5 mb-2">
                        <Globe size={11} color="#67e8f9" />
                        <span className="text-xs font-semibold" style={{ color: "#64748b" }}>Sous prensipal</span>
                      </div>
                      <Chip label={draft.source_platform} color="#67e8f9" bg="rgba(6,182,212,0.1)" />
                    </div>
                  )}

                  {/* Keywords */}
                  {keywords.length > 0 && (
                    <div>
                      <div className="flex items-center gap-1.5 mb-2">
                        <Tag size={11} color="#fcd34d" />
                        <span className="text-xs font-semibold" style={{ color: "#64748b" }}>Mo kle</span>
                      </div>
                      <div className="flex flex-wrap gap-1.5">
                        {keywords.map((k) => <Chip key={k} label={`#${k}`} color="#fcd34d" bg="rgba(245,158,11,0.1)" />)}
                      </div>
                    </div>
                  )}

                  {/* Entities */}
                  {entities.length > 0 && (
                    <div>
                      <div className="flex items-center gap-1.5 mb-2">
                        <Users size={11} color="#f9a8d4" />
                        <span className="text-xs font-semibold" style={{ color: "#64748b" }}>Antite detekte</span>
                      </div>
                      <div className="flex flex-wrap gap-1.5">
                        {entities.map((e) => <Chip key={e} label={e} color="#f9a8d4" bg="rgba(236,72,153,0.1)" />)}
                      </div>
                    </div>
                  )}

                  {/* Source links */}
                  {sources.length > 0 && (
                    <div>
                      <div className="flex items-center gap-1.5 mb-2">
                        <ExternalLink size={11} color="#6ee7b7" />
                        <span className="text-xs font-semibold" style={{ color: "#64748b" }}>Sous ({sources.length})</span>
                      </div>
                      <div className="space-y-1.5">
                        {sources.slice(0, 5).map((url, i) => {
                          let domain = url;
                          try { domain = new URL(url).hostname.replace("www.", ""); } catch {}
                          return (
                            <a key={i} href={url} target="_blank" rel="noopener noreferrer"
                              className="flex items-center gap-2 text-xs rounded-lg px-2.5 py-1.5 transition-colors"
                              style={{ background: "#13152a", color: "#6ee7b7" }}
                            >
                              <ExternalLink size={10} className="shrink-0" />
                              <span className="truncate">{domain}</span>
                            </a>
                          );
                        })}
                      </div>
                    </div>
                  )}
                </div>
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
}

export default function ScoutList({
  pending, approved, rejected, categories,
}: {
  pending: Draft[];
  approved: Draft[];
  rejected: Draft[];
  categories: Category[];
}) {
  const router = useRouter();
  const [running, startRunning] = useTransition();
  const [error, setError] = useState<string | null>(null);
  const [allDrafts, setAllDrafts] = useState({ pending, approved, rejected });
  const [activeTab, setActiveTab] = useState<"pending" | "approved" | "rejected">("pending");
  const [filters, setFilters] = useState({
    title: "",
    type: "",
    category: "",
    risk: "",
    score: "",
    platform: "",
  });

  async function runScout() {
    setError(null);
    startRunning(async () => {
      const res = await fetch("/api/scout/run", { method: "POST" });
      const data = await res.json();
      if (!res.ok) setError(data.error ?? "Scout failed");
      else router.refresh();
    });
  }

  function handleAction(id: string, action: "approve" | "reject") {
    setAllDrafts((prev) => {
      const draft = prev.pending.find((d) => d.id === id);
      if (!draft) return prev;
      return {
        pending: prev.pending.filter((d) => d.id !== id),
        approved: action === "approve" ? [{ ...draft, status: "approved" }, ...prev.approved] : prev.approved,
        rejected: action === "reject" ? [{ ...draft, status: "rejected" }, ...prev.rejected] : prev.rejected,
      };
    });
  }

  const tabs = [
    { key: "pending" as const, label: "K ap tann", count: allDrafts.pending.length, color: "#f59e0b" },
    { key: "approved" as const, label: "Apwouve", count: allDrafts.approved.length, color: "#10b981" },
    { key: "rejected" as const, label: "Rejte", count: allDrafts.rejected.length, color: "#475569" },
  ];

  const currentList = allDrafts[activeTab];

  // Derive unique values for dropdowns from current tab's data
  const catOptions = Array.from(new Set(currentList.map((d) => (Array.isArray(d.category) ? d.category[0]?.name_ht : d.category?.name_ht) ?? "").filter(Boolean))).sort();
  const platformOptions = Array.from(new Set(currentList.map((d) => d.source_platform ?? "").filter(Boolean))).sort();

  const shown = currentList.filter((d) => {
    const catName = (Array.isArray(d.category) ? d.category[0]?.name_ht : d.category?.name_ht) ?? "";
    if (filters.title && !`${d.title_ht} ${d.title_en ?? ""} ${d.option_a} ${d.option_b}`.toLowerCase().includes(filters.title.toLowerCase())) return false;
    if (filters.type && (d.type ?? "matchup") !== filters.type) return false;
    if (filters.category && catName !== filters.category) return false;
    if (filters.risk && (d.risk_level ?? "") !== filters.risk) return false;
    if (filters.score) {
      const s = d.combined_score ?? 0;
      if (filters.score === "7+" && s < 7) return false;
      if (filters.score === "5-7" && (s < 5 || s >= 7)) return false;
      if (filters.score === "<5" && s >= 5) return false;
    }
    if (filters.platform && (d.source_platform ?? "") !== filters.platform) return false;
    return true;
  });

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          {tabs.map((t) => (
            <button key={t.key} onClick={() => setActiveTab(t.key)}
              className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-medium transition-all"
              style={{
                background: activeTab === t.key ? "rgba(124,58,237,0.15)" : "transparent",
                color: activeTab === t.key ? "#a78bfa" : "#64748b",
                border: activeTab === t.key ? "1px solid rgba(124,58,237,0.3)" : "1px solid transparent",
              }}
            >
              {t.label}
              <span className="px-1.5 py-0.5 rounded-full text-xs font-bold" style={{ background: `${t.color}22`, color: t.color }}>
                {t.count}
              </span>
            </button>
          ))}
        </div>
        <button onClick={runScout} disabled={running}
          className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium disabled:opacity-60"
          style={{ background: "linear-gradient(90deg,#7c3aed,#a855f7)", color: "white" }}
        >
          {running ? <Loader2 size={14} className="animate-spin" /> : <Bot size={14} />}
          {running ? "Scout k ap kouri…" : "Run Scout"}
        </button>
      </div>

      {error && (
        <div className="text-sm px-4 py-3 rounded-xl" style={{ background: "rgba(239,68,68,0.08)", color: "#ef4444", border: "1px solid rgba(239,68,68,0.15)" }}>
          {error}
        </div>
      )}

      <div className="flex flex-wrap gap-2">
        <input
          value={filters.title}
          onChange={(e) => setFilters((prev) => ({ ...prev, title: e.target.value }))}
          placeholder="Filtre tit / opsyon…"
          className="px-3 py-2 rounded-lg text-xs text-white outline-none flex-1 min-w-[180px]"
          style={{ background: "#0e0f1e", border: "1px solid #1e2040" }}
        />
        {(["type","category","risk","score","platform"] as const).map((key) => {
          const opts: { value: string; label: string }[] =
            key === "type"     ? [{ value: "matchup", label: "Matchup" }, { value: "prediction", label: "Prediksyon" }] :
            key === "category" ? catOptions.map((c) => ({ value: c, label: c })) :
            key === "risk"     ? [{ value: "low", label: "Low" }, { value: "medium", label: "Medium" }, { value: "high", label: "High" }] :
            key === "score"    ? [{ value: "7+", label: "Score 7+" }, { value: "5-7", label: "Score 5–7" }, { value: "<5", label: "Score <5" }] :
                                 platformOptions.map((p) => ({ value: p, label: p }));
          const placeholder =
            key === "type" ? "Tout tip" :
            key === "category" ? "Tout kategorì" :
            key === "risk" ? "Tout risk" :
            key === "score" ? "Tout score" : "Tout sous";
          return (
            <select
              key={key}
              value={filters[key]}
              onChange={(e) => setFilters((prev) => ({ ...prev, [key]: e.target.value }))}
              className="px-3 py-2 rounded-lg text-xs text-white outline-none"
              style={{ background: "#0e0f1e", border: "1px solid #1e2040", minWidth: 130 }}
            >
              <option value="">{placeholder}</option>
              {opts.map((o) => <option key={o.value} value={o.value}>{o.label}</option>)}
            </select>
          );
        })}
        {Object.values(filters).some(Boolean) && (
          <button
            onClick={() => setFilters({ title: "", type: "", category: "", risk: "", score: "", platform: "" })}
            className="px-3 py-2 rounded-lg text-xs font-semibold"
            style={{ color: "#64748b", border: "1px solid #1e2040" }}
          >
            Reset
          </button>
        )}
      </div>

      <div className="space-y-3">
        {shown.length === 0 && (
          <div className="rounded-xl p-10 text-center" style={{ background: "#0e0f1e", border: "1px solid #1e2040" }}>
            <Bot size={32} color="#1e2040" className="mx-auto mb-3" />
            <div style={{ color: "#475569", fontSize: 13 }}>
              {activeTab === "pending" ? "Pa gen sijèsyon k ap tann — klike Run Scout" : `Pa gen brouyon ${activeTab === "approved" ? "apwouve" : "rejte"} yo`}
            </div>
          </div>
        )}
        {shown.map((d) => (
          <DraftRow key={d.id} draft={d} categories={categories} onAction={handleAction} />
        ))}
      </div>
    </div>
  );
}
