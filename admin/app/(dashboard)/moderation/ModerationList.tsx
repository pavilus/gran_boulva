"use client";

import { useState } from "react";
import { Trash2, Flag, RotateCcw } from "lucide-react";

type Argument = {
  id: string; body: string; status: string; like_count: number; dislike_count: number;
  reply_count: number; created_at: string; matchup_id: string;
  matchup?: { title_ht: string } | { title_ht: string }[];
  user?: { username: string; avatar_url?: string } | { username: string; avatar_url?: string }[];
};

const TABS = ["active", "flagged", "removed"] as const;
const TAB_LABELS = { active: "Aktif", flagged: "Flagé", removed: "Efase" };

function fmtDate(d: string) {
  return new Date(d).toLocaleDateString("fr-HT", { month: "short", day: "numeric" });
}

async function doAction(id: string, action: string) {
  await fetch("/api/moderation/action", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ id, action }),
  });
}

export default function ModerationList({ args: initial }: { args: Argument[] }) {
  const [args, setArgs] = useState(initial);
  const [activeTab, setActiveTab] = useState<typeof TABS[number]>("active");
  const [loading, setLoading] = useState<string | null>(null);
  const [search, setSearch] = useState("");
  const [filters, setFilters] = useState({
    user: "",
    argument: "",
    matchup: "",
    reactions: "",
    date: "",
  });

  const getUser = (a: Argument) => {
    if (!a.user) return "—";
    const u = Array.isArray(a.user) ? a.user[0] : a.user;
    return u?.username ?? "—";
  };

  const getMatchup = (a: Argument) => {
    if (!a.matchup) return "—";
    const m = Array.isArray(a.matchup) ? a.matchup[0] : a.matchup;
    return m?.title_ht ?? "—";
  };

  const filtered = args.filter((a) => {
    if (a.status !== activeTab) return false;
    const q = search.toLowerCase();
    if (q && !`${getUser(a)} ${a.body} ${getMatchup(a)} ${a.like_count} ${a.dislike_count}`.toLowerCase().includes(q)) return false;
    if (filters.user && !getUser(a).toLowerCase().includes(filters.user.toLowerCase())) return false;
    if (filters.argument && !a.body.toLowerCase().includes(filters.argument.toLowerCase())) return false;
    if (filters.matchup && !getMatchup(a).toLowerCase().includes(filters.matchup.toLowerCase())) return false;
    if (filters.reactions && !`${a.like_count}/${a.dislike_count}`.includes(filters.reactions)) return false;
    if (filters.date && !fmtDate(a.created_at).toLowerCase().includes(filters.date.toLowerCase())) return false;
    return true;
  });

  const act = async (id: string, action: string) => {
    setLoading(`${id}-${action}`);
    await doAction(id, action);
    setArgs((prev) => prev.map((a) =>
      a.id !== id ? a : {
        ...a,
        status: action === "flag" ? "flagged" : action === "remove" ? "removed" : "active",
      }
    ));
    setLoading(null);
  };

  return (
    <div className="space-y-4">
      <div className="flex items-center gap-3">
        <input
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="Chèche nan kontni…"
          className="px-3 py-2 rounded-lg text-sm text-white outline-none flex-1 max-w-sm"
          style={{ background: "#0e0f1e", border: "1px solid #1e2040" }}
        />
        <div className="flex gap-1">
          {TABS.map((t) => (
            <button key={t} onClick={() => setActiveTab(t)}
              className="px-3 py-1.5 rounded-lg text-xs font-semibold transition-colors"
              style={{
                background: activeTab === t ? "rgba(124,58,237,0.2)" : "transparent",
                color: activeTab === t ? "#a78bfa" : "#475569",
                border: activeTab === t ? "1px solid rgba(124,58,237,0.4)" : "1px solid transparent",
              }}>
              {TAB_LABELS[t]} ({args.filter(a => a.status === t).length})
            </button>
          ))}
        </div>
      </div>

      <div className="rounded-xl overflow-hidden" style={{ border: "1px solid #1e2040" }}>
        <table className="w-full text-sm">
          <thead>
            <tr style={{ background: "#0a0b18", borderBottom: "1px solid #1e2040" }}>
              {["Itilizatè", "Agiman", "Matchup", "👍 / 👎", "Dat", "Aksyon"].map((h) => (
                <th key={h} className="px-4 py-3 text-left text-xs font-semibold uppercase" style={{ color: "#475569" }}>{h}</th>
              ))}
            </tr>
            <tr style={{ background: "#0a0b18", borderBottom: "1px solid #1e2040" }}>
              {[
                ["user", "Filtre itilizatè"],
                ["argument", "Filtre agiman"],
                ["matchup", "Filtre matchup"],
                ["reactions", "Filtre 👍/👎"],
                ["date", "Filtre dat"],
              ].map(([key, placeholder]) => (
                <th key={key} className="px-4 pb-3">
                  <input value={filters[key as keyof typeof filters]}
                    onChange={(e) => setFilters((prev) => ({ ...prev, [key]: e.target.value }))}
                    placeholder={placeholder}
                    className="w-full px-2 py-1.5 rounded-md text-xs text-white outline-none"
                    style={{ background: "#0e0f1e", border: "1px solid #1e2040" }} />
                </th>
              ))}
              <th className="px-4 pb-3">
                <button onClick={() => setFilters({ user: "", argument: "", matchup: "", reactions: "", date: "" })}
                  className="px-2 py-1.5 rounded-md text-xs font-semibold"
                  style={{ color: "#64748b", border: "1px solid #1e2040" }}>Reset</button>
              </th>
            </tr>
          </thead>
          <tbody>
            {filtered.length === 0 && (
              <tr><td colSpan={6} className="px-4 py-12 text-center" style={{ color: "#475569" }}>Pa gen agiman</td></tr>
            )}
            {filtered.map((a) => (
              <tr key={a.id} style={{ borderBottom: "1px solid #1e2040", background: "#0e0f1e" }}>
                <td className="px-4 py-3" style={{ color: "#a78bfa" }}>@{getUser(a)}</td>
                <td className="px-4 py-3 text-white" style={{ maxWidth: 280 }}>
                  <div className="line-clamp-2" style={{ color: "#d1d5db" }}>{a.body}</div>
                </td>
                <td className="px-4 py-3" style={{ color: "#94a3b8", maxWidth: 200 }}>
                  <div className="truncate text-xs">{getMatchup(a)}</div>
                </td>
                <td className="px-4 py-3 whitespace-nowrap" style={{ color: "#64748b" }}>
                  <span style={{ color: "#22c55e" }}>{a.like_count}</span> / <span style={{ color: "#ef4444" }}>{a.dislike_count}</span>
                </td>
                <td className="px-4 py-3 whitespace-nowrap" style={{ color: "#64748b" }}>{fmtDate(a.created_at)}</td>
                <td className="px-4 py-3">
                  <div className="flex gap-1">
                    {a.status === "active" && (
                      <button onClick={() => act(a.id, "flag")} disabled={!!loading}
                        title="Flage" className="p-1.5 rounded-lg"
                        style={{ color: "#f59e0b", background: "rgba(245,158,11,0.1)" }}>
                        <Flag size={14} />
                      </button>
                    )}
                    {a.status !== "removed" && (
                      <button onClick={() => { if (confirm("Retire agiman sa?")) act(a.id, "remove"); }}
                        disabled={!!loading} title="Retire"
                        className="p-1.5 rounded-lg"
                        style={{ color: "#ef4444", background: "rgba(239,68,68,0.08)" }}>
                        <Trash2 size={14} />
                      </button>
                    )}
                    {a.status === "removed" && (
                      <button onClick={() => act(a.id, "restore")} disabled={!!loading}
                        title="Restore" className="p-1.5 rounded-lg"
                        style={{ color: "#22c55e", background: "rgba(34,197,94,0.1)" }}>
                        <RotateCcw size={14} />
                      </button>
                    )}
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
