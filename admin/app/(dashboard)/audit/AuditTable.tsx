"use client";

import { useState } from "react";

type Log = {
  id: string;
  created_at: string;
  action: string;
  content_type?: string | null;
  content_id?: string | null;
  notes?: string | null;
  admin?: { username?: string | null } | null;
  target?: { username?: string | null } | null;
};

const ACTION_COLORS: Record<string, string> = {
  remove: "#ef4444",
  approve: "#22c55e",
  warn: "#f59e0b",
  ban: "#ef4444",
  unban: "#22c55e",
  flag: "#f59e0b",
  restore: "#67e8f9",
};

function fmtDate(d: string) {
  return new Date(d).toLocaleString("fr-HT", { month: "short", day: "numeric", hour: "2-digit", minute: "2-digit" });
}

export default function AuditTable({ logs }: { logs: Log[] }) {
  const [filters, setFilters] = useState({ date: "", admin: "", action: "", target: "", notes: "" });
  const filtered = logs.filter((log) => {
    const target = log.target?.username ? `@${log.target.username}` : log.content_id?.slice(0, 12) ?? "";
    if (filters.date && !fmtDate(log.created_at).toLowerCase().includes(filters.date.toLowerCase())) return false;
    if (filters.admin && !(log.admin?.username ?? "").toLowerCase().includes(filters.admin.toLowerCase())) return false;
    if (filters.action && !log.action.toLowerCase().includes(filters.action.toLowerCase())) return false;
    if (filters.target && !`${log.content_type ?? ""} ${target}`.toLowerCase().includes(filters.target.toLowerCase())) return false;
    if (filters.notes && !(log.notes ?? "").toLowerCase().includes(filters.notes.toLowerCase())) return false;
    return true;
  });

  return (
    <div className="rounded-xl overflow-hidden" style={{ border: "1px solid #2e3060" }}>
      <table className="w-full text-sm">
        <thead>
          <tr style={{ background: "#0a0b18", borderBottom: "1px solid #2e3060" }}>
            {["Dat", "Admin", "Aksyon", "Sib", "Nòt"].map((h) => (
              <th key={h} className="px-4 py-3 text-left text-xs font-semibold uppercase" style={{ color: "#94a3b8" }}>{h}</th>
            ))}
          </tr>
          <tr style={{ background: "#0a0b18", borderBottom: "1px solid #2e3060" }}>
            {[
              ["date", "Filtre dat"],
              ["admin", "Filtre admin"],
              ["action", "Filtre aksyon"],
              ["target", "Filtre sib"],
              ["notes", "Filtre nòt"],
            ].map(([key, placeholder]) => (
              <th key={key} className="px-4 pb-3">
                <input value={filters[key as keyof typeof filters]}
                  onChange={(e) => setFilters((prev) => ({ ...prev, [key]: e.target.value }))}
                  placeholder={placeholder}
                  className="w-full px-2 py-1.5 rounded-md text-xs text-white outline-none"
                  style={{ background: "#0e0f1e", border: "1px solid #2e3060" }} />
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {filtered.length === 0 && (
            <tr><td colSpan={5} className="px-4 py-12 text-center" style={{ color: "#94a3b8" }}>Pa gen jounal yo</td></tr>
          )}
          {filtered.map((log) => {
            const actionColor = ACTION_COLORS[log.action] ?? "#94a3b8";
            return (
              <tr key={log.id} style={{ borderBottom: "1px solid #2e3060", background: "#0e0f1e" }}>
                <td className="px-4 py-3 whitespace-nowrap" style={{ color: "#94a3b8" }}>{fmtDate(log.created_at)}</td>
                <td className="px-4 py-3" style={{ color: "#a78bfa" }}>@{log.admin?.username ?? "—"}</td>
                <td className="px-4 py-3">
                  <span className="px-2 py-0.5 rounded-full text-xs font-semibold uppercase" style={{ background: `${actionColor}22`, color: actionColor }}>
                    {log.action}
                  </span>
                </td>
                <td className="px-4 py-3 text-white">
                  {log.content_type && <span style={{ color: "#94a3b8" }}>{log.content_type}: </span>}
                  {log.target?.username ? `@${log.target.username}` : log.content_id?.slice(0, 12)}
                </td>
                <td className="px-4 py-3" style={{ color: "#94a3b8" }}>{log.notes ?? "—"}</td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  );
}
