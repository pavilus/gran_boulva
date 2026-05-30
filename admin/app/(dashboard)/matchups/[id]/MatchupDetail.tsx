"use client";

import { useState, useEffect } from "react";
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip,
  ResponsiveContainer, LineChart, Line, Cell,
} from "recharts";
import { ChevronDown, ChevronUp, Loader2, MessageSquare, RefreshCw, Save, TrendingUp, Users } from "lucide-react";
import MatchupImageGenerator from "./MatchupImageGenerator";
import { createClient } from "@/lib/supabase/client";

// ─── Types ───────────────────────────────────────────────────────────────────

type Option = { id: string; option_label: string; option_name: string; vote_count: number; image_url?: string };
type Matchup = {
  id: string; title_ht: string; title_en?: string; description_ht?: string;
  status: string; total_votes: number; engagement_score: number;
  created_at: string; published_at?: string; expires_at?: string;
  poster_image_url?: string; share_image_url?: string;
  category?: { name_ht: string } | null;
  options?: Option[];
};
type Vote = {
  option_id: string; created_at: string; vote_changed: boolean;
  user?: {
    username?: string;
    full_name?: string;
    email?: string;
    avatar_url?: string;
    location?: string;
    influence_score?: number;
    role?: string;
  } | null;
};
type Arg = {
  id: string; body: string; like_count: number; dislike_count: number;
  reply_count: number; created_at: string; option_id: string; status: string;
  media_url?: string | null; media_type?: string | null; media_duration?: number | null;
  user?: { username: string } | null;
};

// ─── Helpers ─────────────────────────────────────────────────────────────────

const STATUS_COLORS: Record<string, string> = {
  draft: "#a78bfa", published: "#22c55e", closed: "#94a3b8", archived: "#475569",
};

function fmt(n: number) {
  if (n >= 1_000_000) return `${(n / 1_000_000).toFixed(1)}M`;
  if (n >= 1_000) return `${(n / 1_000).toFixed(1)}K`;
  return `${n}`;
}

function fmtDate(d: string) {
  return new Date(d).toLocaleDateString("fr-HT", { month: "short", day: "numeric", year: "numeric" });
}

function Card({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div className="rounded-xl p-5" style={{ background: "#0e0f1e", border: "1px solid #1e2040" }}>
      <div className="text-white font-semibold text-sm mb-4">{title}</div>
      {children}
    </div>
  );
}

const CustomTooltip = ({ active, payload, label }: any) => {
  if (!active || !payload?.length) return null;
  return (
    <div style={{ background: "#13152a", border: "1px solid #2d1b69", borderRadius: 8, padding: "10px 14px", fontSize: 12 }}>
      <p style={{ color: "#94a3b8", marginBottom: 4 }}>{label}</p>
      {payload.map((p: any) => (
        <p key={p.dataKey} style={{ color: p.color, margin: "2px 0" }}>
          {p.name}: <strong>{p.value}</strong>
        </p>
      ))}
    </div>
  );
};

// ─── Sub-components ───────────────────────────────────────────────────────────

function StatPill({ icon: Icon, label, value, color }: { icon: any; label: string; value: string | number; color: string }) {
  return (
    <div className="flex items-center gap-3 rounded-xl px-4 py-3" style={{ background: "#0a0b18", border: "1px solid #1e2040" }}>
      <div className="flex items-center justify-center rounded-lg shrink-0" style={{ width: 36, height: 36, background: `${color}22` }}>
        <Icon size={16} color={color} />
      </div>
      <div>
        <div className="text-white font-bold text-lg leading-tight">{value}</div>
        <div style={{ color: "#94a3b8", fontSize: 11 }}>{label}</div>
      </div>
    </div>
  );
}

function VoteSplit({ options, votes }: { options: Option[]; votes: Vote[] }) {
  const total = votes.length;
  if (!options?.length) return null;

  const optA = options.find((o) => o.option_label === "A");
  const optB = options.find((o) => o.option_label === "B");

  const countA = votes.filter((v) => v.option_id === optA?.id).length;
  const countB = votes.filter((v) => v.option_id === optB?.id).length;
  const pctA = total > 0 ? Math.round((countA / total) * 100) : 50;
  const pctB = 100 - pctA;

  return (
    <Card title="Repartisyon Vòt yo">
      <div className="space-y-4">
        {/* Visual split bar */}
        <div className="rounded-full overflow-hidden flex" style={{ height: 14 }}>
          <div style={{ width: `${pctA}%`, background: "linear-gradient(90deg,#7c3aed,#a855f7)", transition: "width 0.5s" }} />
          <div style={{ width: `${pctB}%`, background: "linear-gradient(90deg,#ec4899,#f472b6)", transition: "width 0.5s" }} />
        </div>

        {/* Labels */}
        <div className="flex justify-between">
          <div>
            <div className="font-bold text-lg" style={{ color: "#a78bfa" }}>{pctA}%</div>
            <div className="text-white font-semibold text-sm">{optA?.option_name ?? "Opsyon A"}</div>
            <div style={{ color: "#94a3b8", fontSize: 12 }}>{fmt(countA)} vòt</div>
          </div>
          <div className="text-right">
            <div className="font-bold text-lg" style={{ color: "#ec4899" }}>{pctB}%</div>
            <div className="text-white font-semibold text-sm">{optB?.option_name ?? "Opsyon B"}</div>
            <div style={{ color: "#94a3b8", fontSize: 12 }}>{fmt(countB)} vòt</div>
          </div>
        </div>

        {/* Option detail rows */}
        {[
          { opt: optA, count: countA, pct: pctA, color: "#a78bfa" },
          { opt: optB, count: countB, pct: pctB, color: "#ec4899" },
        ].map(({ opt, count, pct, color }) =>
          opt ? (
            <div key={opt.id} className="flex items-center gap-3">
              <div className="w-2 h-2 rounded-full shrink-0" style={{ background: color }} />
              <div className="flex-1">
                <div className="flex justify-between mb-1">
                  <span className="text-white text-xs font-medium">{opt.option_name}</span>
                  <span className="text-xs font-bold" style={{ color }}>{pct}%</span>
                </div>
                <div className="rounded-full overflow-hidden" style={{ height: 5, background: "#1e2040" }}>
                  <div style={{ width: `${pct}%`, height: "100%", background: color, transition: "width 0.5s" }} />
                </div>
              </div>
              <div className="text-xs font-semibold text-white w-14 text-right">{fmt(count)}</div>
            </div>
          ) : null
        )}
      </div>
    </Card>
  );
}

function VoteTimeline({ votes, createdAt }: { votes: Vote[]; createdAt: string }) {
  // Build day-by-day series from creation to now
  const start = new Date(createdAt);
  const now = new Date();
  const dayMs = 86_400_000;
  const totalDays = Math.min(Math.ceil((now.getTime() - start.getTime()) / dayMs) + 1, 30);

  const data = Array.from({ length: totalDays }, (_, i) => {
    const d = new Date(start.getTime() + i * dayMs);
    const key = d.toLocaleDateString("en-US", { month: "short", day: "numeric" });
    const dayVotes = votes.filter((v) => {
      const vd = new Date(v.created_at);
      return vd.toLocaleDateString("en-US", { month: "short", day: "numeric" }) === key;
    });
    return { day: key, vòt: dayVotes.length };
  });

  if (data.every((d) => d.vòt === 0)) {
    return (
      <Card title="Vòt pandan tan">
        <div className="text-center py-8" style={{ color: "#94a3b8" }}>Pa gen done vòt yo</div>
      </Card>
    );
  }

  return (
    <Card title={`Vòt pandan tan (${totalDays <= 1 ? "jodi a" : `${totalDays} jou`})`}>
      <ResponsiveContainer width="100%" height={160}>
        <LineChart data={data} margin={{ top: 4, right: 4, left: -28, bottom: 0 }}>
          <CartesianGrid strokeDasharray="3 3" stroke="#1e2040" vertical={false} />
          <XAxis dataKey="day" tick={{ fill: "#475569", fontSize: 9 }} axisLine={false} tickLine={false}
            interval={Math.max(0, Math.floor(data.length / 7) - 1)} />
          <YAxis tick={{ fill: "#475569", fontSize: 9 }} axisLine={false} tickLine={false} />
          <Tooltip content={<CustomTooltip />} />
          <Line type="monotone" dataKey="vòt" name="Vòt" stroke="#7c3aed" strokeWidth={2.5}
            dot={false} activeDot={{ r: 4, fill: "#7c3aed" }} />
        </LineChart>
      </ResponsiveContainer>
    </Card>
  );
}

function LocationBreakdown({ votes }: { votes: Vote[] }) {
  const locMap: Record<string, number> = {};
  for (const v of votes) {
    const loc = (v.user as any)?.location || "Enkoni";
    locMap[loc] = (locMap[loc] ?? 0) + 1;
  }

  const sorted = Object.entries(locMap)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 8);

  const max = sorted[0]?.[1] ?? 1;
  const total = votes.length;

  if (sorted.length === 0) {
    return (
      <Card title="Lokasyon Votè yo">
        <div className="text-center py-8" style={{ color: "#94a3b8" }}>Pa gen done lokasyon</div>
      </Card>
    );
  }

  const chartData = sorted.map(([loc, count]) => ({ loc: loc.length > 16 ? loc.slice(0, 16) + "…" : loc, vòt: count }));

  return (
    <Card title="Lokasyon Votè yo">
      <div className="space-y-2">
        {sorted.map(([loc, count]) => {
          const pct = total > 0 ? Math.round((count / total) * 100) : 0;
          return (
            <div key={loc} className="flex items-center gap-3">
              <div className="text-xs text-white w-32 shrink-0 truncate" title={loc}>{loc}</div>
              <div className="flex-1 rounded-full overflow-hidden" style={{ height: 6, background: "#1e2040" }}>
                <div style={{ width: `${(count / max) * 100}%`, height: "100%", background: "linear-gradient(90deg,#7c3aed,#a855f7)" }} />
              </div>
              <div className="text-xs font-semibold text-white w-8 text-right">{count}</div>
              <div className="text-xs w-8 text-right" style={{ color: "#94a3b8" }}>{pct}%</div>
            </div>
          );
        })}
      </div>
    </Card>
  );
}

function TopArguments({ args, options }: { args: Arg[]; options: Option[] }) {
  const optMap = Object.fromEntries((options ?? []).map((o) => [o.id, o]));

  return (
    <Card title={`Top Agiman (${args.length})`}>
      {args.length === 0 ? (
        <div className="text-center py-8" style={{ color: "#94a3b8" }}>Pa gen agiman yo</div>
      ) : (
        <div className="space-y-3">
          {args.slice(0, 8).map((a) => {
            const opt = optMap[a.option_id];
            const color = opt?.option_label === "A" ? "#a78bfa" : "#ec4899";
            const statusColor = a.status === "active" ? "#22c55e" : a.status === "flagged" ? "#f59e0b" : "#ef4444";
            const username = (a.user as any)?.username ?? "—";
            return (
              <div key={a.id} className="rounded-lg p-3" style={{ background: "#0a0b18", border: "1px solid #1e2040" }}>
                <div className="flex items-start gap-2 mb-2">
                  <div className="flex-1">
                    <div className="flex items-center gap-2 mb-1">
                      <span className="text-xs font-semibold" style={{ color }}>
                        {opt?.option_label ?? "?"}: {opt?.option_name ?? ""}
                      </span>
                      <span className="text-xs px-1.5 py-0.5 rounded-full" style={{ background: `${statusColor}22`, color: statusColor }}>
                        {a.status}
                      </span>
                    </div>
                    {/* Media badge */}
                    {a.media_url && (
                      <span className="inline-flex items-center gap-1 text-xs font-semibold px-2 py-0.5 rounded-full mb-1" style={{ background: "rgba(168,85,247,0.15)", color: "#a855f7", border: "1px solid rgba(168,85,247,0.3)" }}>
                        {a.media_type === "video" ? "🎬 Videyo" : "🎤 Vwa"}{a.media_duration ? ` · ${a.media_duration}s` : ""}
                      </span>
                    )}
                    {/* Text body */}
                    {a.body && a.body.trim() && (
                      <div className="text-sm leading-relaxed" style={{ color: "#d1d5db" }}>
                        {a.body.length > 140 ? a.body.slice(0, 140) + "…" : a.body}
                      </div>
                    )}
                    {/* Inline media player */}
                    {a.media_url && a.media_type === "audio" && (
                      <audio controls src={a.media_url} className="mt-1.5" style={{ width: "100%", height: 32, accentColor: "#a855f7" }} />
                    )}
                    {a.media_url && a.media_type === "video" && (
                      <video controls src={a.media_url} className="mt-1.5 rounded-lg" style={{ width: "100%", maxHeight: 160, background: "#000" }} />
                    )}
                  </div>
                </div>
                <div className="flex items-center gap-4">
                  <span style={{ color: "#94a3b8", fontSize: 11 }}>@{username}</span>
                  <span style={{ color: "#22c55e", fontSize: 11 }}>👍 {a.like_count}</span>
                  <span style={{ color: "#ef4444", fontSize: 11 }}>👎 {a.dislike_count}</span>
                  {a.reply_count > 0 && <span style={{ color: "#94a3b8", fontSize: 11 }}>💬 {a.reply_count}</span>}
                </div>
              </div>
            );
          })}
        </div>
      )}
    </Card>
  );
}

function VoterInfluence({ votes }: { votes: Vote[] }) {
  const brackets = [
    { label: "0–99", min: 0, max: 99, color: "#94a3b8" },
    { label: "100–499", min: 100, max: 499, color: "#94a3b8" },
    { label: "500–999", min: 500, max: 999, color: "#a78bfa" },
    { label: "1000+", min: 1000, max: Infinity, color: "#7c3aed" },
  ];

  const data = brackets.map(({ label, min, max, color }) => ({
    label, color,
    count: votes.filter((v) => {
      const s = (v.user as any)?.influence_score ?? 0;
      return s >= min && s <= max;
    }).length,
  }));

  const max = Math.max(...data.map((d) => d.count), 1);

  return (
    <Card title="Enfliyans Votè yo">
      <div className="space-y-2">
        {data.map((d) => (
          <div key={d.label} className="flex items-center gap-3">
            <div className="text-xs text-white w-16 shrink-0">{d.label}</div>
            <div className="flex-1 rounded-full overflow-hidden" style={{ height: 6, background: "#1e2040" }}>
              <div style={{ width: `${(d.count / max) * 100}%`, height: "100%", background: d.color, transition: "width 0.5s" }} />
            </div>
            <div className="text-xs font-semibold text-white w-8 text-right">{d.count}</div>
          </div>
        ))}
      </div>
    </Card>
  );
}

function VoterList({ votes, options }: { votes: Vote[]; options: Option[] }) {
  const optMap = Object.fromEntries((options ?? []).map((o) => [o.id, o]));
  const rows = votes
    .slice()
    .sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime())
    .slice(0, 50);

  return (
    <Card title={`Votè yo (${votes.length})`}>
      {rows.length === 0 ? (
        <div className="text-center py-8" style={{ color: "#94a3b8" }}>Pa gen votè yo</div>
      ) : (
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr style={{ borderBottom: "1px solid #1e2040" }}>
                {["Itilizatè", "Chwa", "Lokasyon", "Enfliyans", "Wòl", "Dat"].map((h) => (
                  <th key={h} className="text-left py-2 px-2 text-xs font-semibold uppercase" style={{ color: "#94a3b8" }}>
                    {h}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {rows.map((v, idx) => {
                const opt = optMap[v.option_id];
                const user = v.user;
                const name = user?.username ? `@${user.username}` : user?.full_name ?? user?.email ?? "—";
                const color = opt?.option_label === "A" ? "#a78bfa" : "#ec4899";
                return (
                  <tr key={`${v.option_id}-${v.created_at}-${idx}`} style={{ borderBottom: "1px solid rgba(30,32,64,0.5)" }}>
                    <td className="py-2 px-2 text-white">{name}</td>
                    <td className="py-2 px-2">
                      <span className="px-2 py-0.5 rounded-full text-xs font-semibold" style={{ background: `${color}22`, color }}>
                        {opt?.option_label ?? "?"}: {opt?.option_name ?? "—"}
                      </span>
                    </td>
                    <td className="py-2 px-2" style={{ color: "#94a3b8" }}>{user?.location ?? "—"}</td>
                    <td className="py-2 px-2 text-white">{fmt(user?.influence_score ?? 0)}</td>
                    <td className="py-2 px-2" style={{ color: "#94a3b8" }}>{user?.role ?? "—"}</td>
                    <td className="py-2 px-2" style={{ color: "#94a3b8" }}>{fmtDate(v.created_at)}</td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}
    </Card>
  );
}

// ─── Edit Panel ───────────────────────────────────────────────────────────────

const inputStyle: React.CSSProperties = {
  width: "100%", background: "#080916", border: "1px solid #1e2040",
  borderRadius: 8, color: "#D4D4D4", fontSize: 13, padding: "8px 12px", outline: "none",
};

type Category = { id: string; name_ht: string };

function EditMatchupPanel({ matchup }: { matchup: Matchup }) {
  const [open, setOpen] = useState(false);
  const [saving, setSaving] = useState(false);
  const [success, setSuccess] = useState(false);
  const [error, setError] = useState("");
  const [categories, setCategories] = useState<Category[]>([]);

  const options = matchup.options ?? [];
  const optA = options.find((o) => o.option_label === "A");
  const optB = options.find((o) => o.option_label === "B");
  const categoryId = (matchup as any).category_id ?? "";

  const [form, setForm] = useState({
    title_ht: matchup.title_ht ?? "",
    title_en: matchup.title_en ?? "",
    description_ht: matchup.description_ht ?? "",
    category_id: categoryId,
    status: matchup.status ?? "draft",
    expires_at: matchup.expires_at ? matchup.expires_at.slice(0, 16) : "",
    option_a_name: optA?.option_name ?? "",
    option_b_name: optB?.option_name ?? "",
  });

  useEffect(() => {
    const supabase = createClient();
    supabase.from("categories").select("id, name_ht").order("name_ht")
      .then(({ data }) => { if (data) setCategories(data); });
  }, []);

  const set = (k: string, v: string) => setForm((p) => ({ ...p, [k]: v }));

  async function save() {
    setSaving(true);
    setError("");
    setSuccess(false);
    try {
      const res = await fetch("/api/matchups/action", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ action: "update", id: matchup.id, ...form }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error ?? "Erè");
      setSuccess(true);
      setTimeout(() => setSuccess(false), 3000);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Erè");
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="rounded-xl overflow-hidden" style={{ background: "#0e0f1e", border: "1px solid #1e2040" }}>
      {/* Toggle header */}
      <button
        className="w-full flex items-center justify-between px-5 py-4 text-left"
        onClick={() => setOpen((p) => !p)}
      >
        <span className="text-sm font-semibold" style={{ color: "#D4D4D4" }}>Edite Matchup</span>
        {open ? <ChevronUp size={16} style={{ color: "#94a3b8" }} /> : <ChevronDown size={16} style={{ color: "#94a3b8" }} />}
      </button>

      {open && (
        <div className="px-5 pb-5 space-y-4" style={{ borderTop: "1px solid #1e2040" }}>
          <div className="pt-4 grid gap-4" style={{ gridTemplateColumns: "1fr 1fr" }}>
            {/* Title HT */}
            <div className="col-span-2">
              <label className="text-xs font-semibold mb-1 block" style={{ color: "#94a3b8" }}>Tit (Kreyòl) *</label>
              <input style={inputStyle} value={form.title_ht} onChange={(e) => set("title_ht", e.target.value)} />
            </div>
            {/* Title EN */}
            <div className="col-span-2">
              <label className="text-xs font-semibold mb-1 block" style={{ color: "#94a3b8" }}>Title (English)</label>
              <input style={inputStyle} value={form.title_en} onChange={(e) => set("title_en", e.target.value)} />
            </div>
            {/* Description */}
            <div className="col-span-2">
              <label className="text-xs font-semibold mb-1 block" style={{ color: "#94a3b8" }}>Deskripsyon</label>
              <textarea
                style={{ ...inputStyle, resize: "vertical", minHeight: 72 }}
                value={form.description_ht}
                onChange={(e) => set("description_ht", e.target.value)}
              />
            </div>
            {/* Category */}
            <div>
              <label className="text-xs font-semibold mb-1 block" style={{ color: "#94a3b8" }}>Kategori</label>
              <select style={{ ...inputStyle, appearance: "none" as const }} value={form.category_id} onChange={(e) => set("category_id", e.target.value)}>
                <option value="">— chwazi —</option>
                {categories.map((c) => <option key={c.id} value={c.id}>{c.name_ht}</option>)}
              </select>
            </div>
            {/* Status */}
            <div>
              <label className="text-xs font-semibold mb-1 block" style={{ color: "#94a3b8" }}>Estati</label>
              <select style={{ ...inputStyle, appearance: "none" as const }} value={form.status} onChange={(e) => set("status", e.target.value)}>
                <option value="draft">Draft</option>
                <option value="published">Published</option>
                <option value="closed">Closed</option>
                <option value="archived">Archived</option>
              </select>
            </div>
            {/* Expires at */}
            <div>
              <label className="text-xs font-semibold mb-1 block" style={{ color: "#94a3b8" }}>Ekspire</label>
              <input type="datetime-local" style={inputStyle} value={form.expires_at} onChange={(e) => set("expires_at", e.target.value)} />
            </div>
            {/* Option A name */}
            <div>
              <label className="text-xs font-semibold mb-1 block" style={{ color: "#a78bfa" }}>Opsyon A — Non</label>
              <input style={{ ...inputStyle, borderColor: "#3d2a6e" }} value={form.option_a_name} onChange={(e) => set("option_a_name", e.target.value)} />
            </div>
            {/* Option B name */}
            <div>
              <label className="text-xs font-semibold mb-1 block" style={{ color: "#ec4899" }}>Opsyon B — Non</label>
              <input style={{ ...inputStyle, borderColor: "#6b1d3e" }} value={form.option_b_name} onChange={(e) => set("option_b_name", e.target.value)} />
            </div>
          </div>

          {/* Feedback */}
          {error && <p className="text-xs rounded-lg px-3 py-2" style={{ color: "#fca5a5", background: "rgba(239,68,68,.1)" }}>{error}</p>}
          {success && <p className="text-xs rounded-lg px-3 py-2" style={{ color: "#86efac", background: "rgba(34,197,94,.1)" }}>✓ Chanjman yo sovgade</p>}

          <button
            onClick={save}
            disabled={saving || !form.title_ht.trim()}
            className="inline-flex items-center gap-2 rounded-lg px-5 py-2.5 text-xs font-semibold disabled:opacity-50"
            style={{ background: "linear-gradient(90deg,#7c3aed,#ec4899)", color: "#fff" }}
          >
            {saving ? <Loader2 size={14} className="animate-spin" /> : <Save size={14} />}
            {saving ? "Ap sovgade…" : "Sovgade chanjman"}
          </button>
        </div>
      )}
    </div>
  );
}

// ─── Main Component ───────────────────────────────────────────────────────────

export default function MatchupDetail({ matchup, votes, args }: { matchup: Matchup; votes: Vote[]; args: Arg[] }) {
  const options = matchup.options ?? [];
  const catName = matchup.category ? (matchup.category as any).name_ht ?? "—" : "—";
  const statusColor = STATUS_COLORS[matchup.status] ?? "#94a3b8";
  const changedVotes = votes.filter((v) => v.vote_changed).length;
  const uniqueLocations = new Set(votes.map((v) => (v.user as any)?.location).filter(Boolean)).size;
  const totalArgs = args.length;
  const totalLikes = args.reduce((s, a) => s + (a.like_count ?? 0), 0);

  return (
    <div className="space-y-5">
      {/* Edit panel */}
      <EditMatchupPanel matchup={matchup} />

      {/* Header card */}
      <div className="rounded-xl p-5" style={{ background: "#0e0f1e", border: "1px solid #1e2040" }}>
        <div className="flex items-start justify-between gap-4">
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2 mb-2">
              <span className="px-2 py-0.5 rounded-full text-xs font-semibold capitalize"
                style={{ background: `${statusColor}22`, color: statusColor }}>
                {matchup.status}
              </span>
              <span className="text-xs" style={{ color: "#94a3b8" }}>{catName}</span>
            </div>
            <h2 className="text-white font-bold text-xl leading-snug">{matchup.title_ht}</h2>
            {matchup.title_en && <div style={{ color: "#94a3b8", fontSize: 13, marginTop: 4 }}>{matchup.title_en}</div>}
            {matchup.description_ht && (
              <div style={{ color: "#94a3b8", fontSize: 13, marginTop: 8, lineHeight: 1.5 }}>{matchup.description_ht}</div>
            )}
          </div>
          <div className="text-right shrink-0">
            <div style={{ color: "#94a3b8", fontSize: 11 }}>Kreye</div>
            <div style={{ color: "#94a3b8", fontSize: 12 }}>{fmtDate(matchup.created_at)}</div>
            {matchup.published_at && (
              <>
                <div style={{ color: "#94a3b8", fontSize: 11, marginTop: 6 }}>Piblie</div>
                <div style={{ color: "#94a3b8", fontSize: 12 }}>{fmtDate(matchup.published_at)}</div>
              </>
            )}
            {matchup.expires_at && (
              <>
                <div style={{ color: "#94a3b8", fontSize: 11, marginTop: 6 }}>Ekspire</div>
                <div style={{ color: "#94a3b8", fontSize: 12 }}>{fmtDate(matchup.expires_at)}</div>
              </>
            )}
          </div>
        </div>
      </div>

      {/* KPI pills */}
      <div className="grid grid-cols-4 gap-3">
        <StatPill icon={Users} label="Vòt Total" value={fmt(votes.length)} color="#a78bfa" />
        <StatPill icon={MessageSquare} label="Agiman" value={fmt(totalArgs)} color="#ec4899" />
        <StatPill icon={RefreshCw} label="Vòt Chanje" value={fmt(changedVotes)} color="#f59e0b" />
        <StatPill icon={TrendingUp} label="Lokasyon Diferan" value={uniqueLocations || "—"} color="#6ee7b7" />
      </div>

      <MatchupImageGenerator
        matchupId={matchup.id}
        initialPoster={matchup.poster_image_url}
        initialShare={matchup.share_image_url}
        initialOptionA={options.find((option) => option.option_label === "A")?.image_url}
        initialOptionB={options.find((option) => option.option_label === "B")?.image_url}
      />

      {/* Vote split + timeline */}
      <div className="grid gap-5" style={{ gridTemplateColumns: "1fr 1fr" }}>
        <VoteSplit options={options} votes={votes} />
        <VoteTimeline votes={votes} createdAt={matchup.created_at} />
      </div>

      {/* Location + influence */}
      <div className="grid gap-5" style={{ gridTemplateColumns: "1fr 1fr" }}>
        <LocationBreakdown votes={votes} />
        <VoterInfluence votes={votes} />
      </div>

      {/* Arguments */}
      <VoterList votes={votes} options={options} />
      <TopArguments args={args} options={options} />
    </div>
  );
}
