"use client";

import { useState } from "react";

type Boost = {
  id: string;
  expires_at?: string | null;
  coins_spent?: number | null;
  amount?: number | null;
  argument?: { body?: string | null; user?: { username?: string | null } | null } | null;
};

function Badge({ label, color }: { label: string; color: string }) {
  return (
    <span className="px-2 py-0.5 rounded-full text-xs font-semibold" style={{ background: `${color}22`, color }}>
      {label}
    </span>
  );
}

function fmtDate(d: string) {
  return new Date(d).toLocaleDateString("fr-HT", { month: "short", day: "numeric", year: "numeric" });
}

export default function BoostTable({ boosts }: { boosts: Boost[] }) {
  const [filters, setFilters] = useState({
    argument: "",
    user: "",
    coins: "",
    expires: "",
    status: "",
  });

  const filtered = boosts.filter((b) => {
    const expired = b.expires_at ? new Date(b.expires_at) <= new Date() : true;
    const status = expired ? "Ekspire" : "Aktif";
    const argBody = b.argument?.body ?? "—";
    const username = b.argument?.user?.username ?? "—";
    const coins = String(b.coins_spent ?? b.amount ?? "—");
    if (filters.argument && !argBody.toLowerCase().includes(filters.argument.toLowerCase())) return false;
    if (filters.user && !username.toLowerCase().includes(filters.user.toLowerCase())) return false;
    if (filters.coins && !coins.includes(filters.coins)) return false;
    if (filters.expires && !(b.expires_at ? fmtDate(b.expires_at) : "—").toLowerCase().includes(filters.expires.toLowerCase())) return false;
    if (filters.status && !status.toLowerCase().includes(filters.status.toLowerCase())) return false;
    return true;
  });

  return (
    <div className="rounded-xl overflow-hidden" style={{ border: "1px solid #1e2040" }}>
      <table className="w-full text-sm">
        <thead>
          <tr style={{ background: "#0a0b18", borderBottom: "1px solid #1e2040" }}>
            {["Agiman", "Itilizatè", "Coins", "Ekspire", "Estati"].map((h) => (
              <th key={h} className="px-4 py-3 text-left text-xs font-semibold uppercase" style={{ color: "#475569" }}>{h}</th>
            ))}
          </tr>
          <tr style={{ background: "#0a0b18", borderBottom: "1px solid #1e2040" }}>
            {[
              ["argument", "Filtre agiman"],
              ["user", "Filtre itilizatè"],
              ["coins", "Filtre coins"],
              ["expires", "Filtre dat"],
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
          </tr>
        </thead>
        <tbody>
          {filtered.length === 0 && (
            <tr><td colSpan={5} className="px-4 py-10 text-center" style={{ color: "#475569" }}>Pa gen boost yo</td></tr>
          )}
          {filtered.map((b) => {
            const expired = b.expires_at ? new Date(b.expires_at) <= new Date() : true;
            const argBody = b.argument?.body ?? "—";
            const username = b.argument?.user?.username ?? "—";
            return (
              <tr key={b.id} style={{ borderBottom: "1px solid #1e2040", background: "#0e0f1e" }}>
                <td className="px-4 py-3 text-white" style={{ maxWidth: 300 }}>
                  <div className="truncate" style={{ color: "#d1d5db" }}>{argBody.slice(0, 80)}{argBody.length > 80 ? "…" : ""}</div>
                </td>
                <td className="px-4 py-3" style={{ color: "#a78bfa" }}>@{username}</td>
                <td className="px-4 py-3 font-semibold" style={{ color: "#fcd34d" }}>{b.coins_spent ?? b.amount ?? "—"}</td>
                <td className="px-4 py-3" style={{ color: "#94a3b8" }}>{b.expires_at ? fmtDate(b.expires_at) : "—"}</td>
                <td className="px-4 py-3">
                  <Badge label={expired ? "Ekspire" : "Aktif"} color={expired ? "#64748b" : "#22c55e"} />
                </td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  );
}
