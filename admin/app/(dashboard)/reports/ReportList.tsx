"use client";

import { useState } from "react";
import { CheckCircle, XCircle } from "lucide-react";

type Report = {
  id: string; status: string; reason: string; created_at: string;
  reporter_user_id?: string; reported_type?: string; reported_id?: string;
  content_type?: string; reporter_id?: string;
};

const STATUS_COLORS: Record<string, string> = {
  pending: "#f59e0b", resolved: "#22c55e", dismissed: "#64748b",
};

const TABS = ["pending", "resolved", "dismissed"] as const;
const TAB_LABELS = { pending: "An Atant", resolved: "Rezoud", dismissed: "Rejte" };

function fmtDate(d: string) {
  return new Date(d).toLocaleDateString("fr-HT", { month: "short", day: "numeric", year: "numeric" });
}

async function doAction(id: string, action: string) {
  await fetch("/api/reports/action", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ id, action }),
  });
}

export default function ReportList({ reports: initial }: { reports: Report[] }) {
  const [reports, setReports] = useState(initial);
  const [activeTab, setActiveTab] = useState<typeof TABS[number]>("pending");
  const [loading, setLoading] = useState<string | null>(null);
  const [filters, setFilters] = useState({
    type: "",
    reason: "",
    date: "",
    status: "",
  });

  const filtered = reports.filter((r) => {
    if (r.status !== activeTab) return false;
    const type = r.reported_type ?? r.content_type ?? "";
    if (filters.type && !type.toLowerCase().includes(filters.type.toLowerCase())) return false;
    if (filters.reason && !r.reason.toLowerCase().includes(filters.reason.toLowerCase())) return false;
    if (filters.date && !fmtDate(r.created_at).toLowerCase().includes(filters.date.toLowerCase())) return false;
    if (filters.status && !r.status.toLowerCase().includes(filters.status.toLowerCase())) return false;
    return true;
  });

  const act = async (id: string, action: string) => {
    setLoading(`${id}-${action}`);
    await doAction(id, action);
    setReports((prev) => prev.map((r) =>
      r.id === id ? { ...r, status: action === "resolve" ? "resolved" : "dismissed" } : r
    ));
    setLoading(null);
  };

  return (
    <div className="space-y-4">
      {/* Tabs */}
      <div className="flex gap-1">
        {TABS.map((t) => (
          <button key={t} onClick={() => setActiveTab(t)}
            className="px-4 py-2 rounded-lg text-xs font-semibold transition-colors"
            style={{
              background: activeTab === t ? "rgba(124,58,237,0.2)" : "transparent",
              color: activeTab === t ? "#a78bfa" : "#475569",
              border: activeTab === t ? "1px solid rgba(124,58,237,0.4)" : "1px solid transparent",
            }}>
            {TAB_LABELS[t]} ({reports.filter(r => r.status === t).length})
          </button>
        ))}
      </div>

      <div className="rounded-xl overflow-hidden" style={{ border: "1px solid #1e2040" }}>
        <table className="w-full text-sm">
          <thead>
            <tr style={{ background: "#0a0b18", borderBottom: "1px solid #1e2040" }}>
              {["Tip", "Rezon", "Dat", "Estati", "Aksyon"].map((h) => (
                <th key={h} className="px-4 py-3 text-left text-xs font-semibold uppercase" style={{ color: "#475569" }}>{h}</th>
              ))}
            </tr>
            <tr style={{ background: "#0a0b18", borderBottom: "1px solid #1e2040" }}>
              {[
                ["type", "Filtre tip"],
                ["reason", "Filtre rezon"],
                ["date", "Filtre dat"],
                ["status", "Filtre estati"],
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
                <button onClick={() => setFilters({ type: "", reason: "", date: "", status: "" })}
                  className="px-2 py-1.5 rounded-md text-xs font-semibold"
                  style={{ color: "#64748b", border: "1px solid #1e2040" }}>Reset</button>
              </th>
            </tr>
          </thead>
          <tbody>
            {filtered.length === 0 && (
              <tr><td colSpan={5} className="px-4 py-12 text-center" style={{ color: "#475569" }}>Okenn rapò nan kategori sa</td></tr>
            )}
            {filtered.map((r) => (
              <tr key={r.id} style={{ borderBottom: "1px solid #1e2040", background: "#0e0f1e" }}>
                <td className="px-4 py-3">
                  <span className="px-2 py-0.5 rounded-full text-xs font-semibold"
                    style={{ background: "rgba(124,58,237,0.15)", color: "#a78bfa" }}>
                    {r.reported_type ?? r.content_type ?? "—"}
                  </span>
                </td>
                <td className="px-4 py-3 text-white" style={{ maxWidth: 360 }}>
                  <div className="truncate">{r.reason}</div>
                </td>
                <td className="px-4 py-3 whitespace-nowrap" style={{ color: "#64748b" }}>{fmtDate(r.created_at)}</td>
                <td className="px-4 py-3">
                  <span className="px-2 py-0.5 rounded-full text-xs font-semibold"
                    style={{ background: `${STATUS_COLORS[r.status] ?? "#94a3b8"}22`, color: STATUS_COLORS[r.status] ?? "#94a3b8" }}>
                    {TAB_LABELS[r.status as typeof TABS[number]] ?? r.status}
                  </span>
                </td>
                <td className="px-4 py-3">
                  {r.status === "pending" && (
                    <div className="flex gap-1">
                      <button onClick={() => act(r.id, "resolve")} disabled={!!loading}
                        title="Rezoud" className="p-1.5 rounded-lg"
                        style={{ color: "#22c55e", background: "rgba(34,197,94,0.1)" }}>
                        <CheckCircle size={14} />
                      </button>
                      <button onClick={() => act(r.id, "dismiss")} disabled={!!loading}
                        title="Rejte" className="p-1.5 rounded-lg"
                        style={{ color: "#64748b", background: "rgba(100,116,139,0.1)" }}>
                        <XCircle size={14} />
                      </button>
                    </div>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
