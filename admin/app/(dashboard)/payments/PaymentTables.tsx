"use client";

import { useState } from "react";

type JoinedUser = { username?: string | null } | { username?: string | null }[] | null;

type Purchase = {
  id: string;
  coin_amount?: number | null;
  usd_cents?: number | null;
  status: string;
  created_at: string;
  user_id?: string | null;
  user?: JoinedUser;
};

type Coin = {
  id: string;
  amount?: number | null;
  fee?: number | null;
  transaction_type?: string | null;
  status: string;
  created_at: string;
  user_id?: string | null;
  user?: JoinedUser;
};

const STATUS_COLORS: Record<string, string> = {
  succeeded: "#22c55e",
  completed: "#22c55e",
  pending: "#f59e0b",
  failed: "#ef4444",
  refunded: "#94a3b8",
};

function Badge({ label, color }: { label: string; color: string }) {
  return (
    <span className="px-2 py-0.5 rounded-full text-xs font-semibold" style={{ background: `${color}22`, color }}>
      {label}
    </span>
  );
}

function fmtDate(d: string) {
  return new Date(d).toLocaleDateString("fr-HT", { month: "short", day: "numeric", year: "numeric", hour: "2-digit", minute: "2-digit" });
}

function usernameFrom(user: JoinedUser) {
  const row = Array.isArray(user) ? user[0] : user;
  return row?.username ?? null;
}

export default function PaymentTables({ purchases, coins }: { purchases: Purchase[]; coins: Coin[] }) {
  const [purchaseFilters, setPurchaseFilters] = useState({ user: "", amount: "", status: "", date: "" });
  const [coinFilters, setCoinFilters] = useState({ user: "", amount: "", fee: "", type: "", status: "", date: "" });

  const filteredPurchases = purchases.filter((p) => {
    const username = usernameFrom(p.user ?? null) ?? p.user_id?.slice(0, 8) ?? "";
    const amount = `$${((p.usd_cents ?? 0) / 100).toFixed(2)}`;
    if (purchaseFilters.user && !username.toLowerCase().includes(purchaseFilters.user.toLowerCase())) return false;
    if (purchaseFilters.amount && !amount.includes(purchaseFilters.amount)) return false;
    if (purchaseFilters.status && !p.status.toLowerCase().includes(purchaseFilters.status.toLowerCase())) return false;
    if (purchaseFilters.date && !fmtDate(p.created_at).toLowerCase().includes(purchaseFilters.date.toLowerCase())) return false;
    return true;
  });

  const filteredCoins = coins.filter((c) => {
    const username = usernameFrom(c.user ?? null) ?? c.user_id?.slice(0, 8) ?? "";
    const type = c.transaction_type ?? "";
    if (coinFilters.user && !username.toLowerCase().includes(coinFilters.user.toLowerCase())) return false;
    if (coinFilters.amount && !String(c.amount ?? 0).includes(coinFilters.amount)) return false;
    if (coinFilters.fee && !String(c.fee ?? 0).includes(coinFilters.fee)) return false;
    if (coinFilters.type && !type.toLowerCase().includes(coinFilters.type.toLowerCase())) return false;
    if (coinFilters.status && !c.status.toLowerCase().includes(coinFilters.status.toLowerCase())) return false;
    if (coinFilters.date && !fmtDate(c.created_at).toLowerCase().includes(coinFilters.date.toLowerCase())) return false;
    return true;
  });

  return (
    <>
      {/* Coin Purchases (Stripe) */}
      <div>
        <div className="text-white font-semibold mb-3">Achte Coins (Stripe)</div>
        <div className="rounded-xl overflow-hidden" style={{ border: "1px solid #2e3060" }}>
          <table className="w-full text-sm">
            <thead>
              <tr style={{ background: "#0a0b18", borderBottom: "1px solid #2e3060" }}>
                {["Itilizatè", "Coins", "USD", "Estati", "Dat"].map((h) => (
                  <th key={h} className="px-4 py-3 text-left text-xs font-semibold uppercase" style={{ color: "#94a3b8" }}>{h}</th>
                ))}
              </tr>
              <tr style={{ background: "#0a0b18", borderBottom: "1px solid #2e3060" }}>
                {[
                  ["user", "Filtre itilizatè"],
                  ["", ""],
                  ["amount", "Filtre montan"],
                  ["status", "Filtre estati"],
                  ["date", "Filtre dat"],
                ].map(([key, placeholder], idx) => (
                  <th key={idx} className="px-4 pb-3">
                    {key ? (
                      <input
                        value={purchaseFilters[key as keyof typeof purchaseFilters]}
                        onChange={(e) => setPurchaseFilters((prev) => ({ ...prev, [key]: e.target.value }))}
                        placeholder={placeholder}
                        className="w-full px-2 py-1.5 rounded-md text-xs text-white outline-none"
                        style={{ background: "#0e0f1e", border: "1px solid #2e3060" }}
                      />
                    ) : null}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {filteredPurchases.length === 0 && (
                <tr><td colSpan={5} className="px-4 py-8 text-center" style={{ color: "#94a3b8" }}>Pa gen achte yo</td></tr>
              )}
              {filteredPurchases.map((p) => (
                <tr key={p.id} style={{ borderBottom: "1px solid #2e3060", background: "#0e0f1e" }}>
                  <td className="px-4 py-3" style={{ color: "#a78bfa" }}>@{usernameFrom(p.user ?? null) ?? p.user_id?.slice(0, 8)}</td>
                  <td className="px-4 py-3 font-semibold" style={{ color: "#fcd34d" }}>{(p.coin_amount ?? 0).toLocaleString()}</td>
                  <td className="px-4 py-3 font-semibold text-white">${((p.usd_cents ?? 0) / 100).toFixed(2)}</td>
                  <td className="px-4 py-3"><Badge label={p.status} color={STATUS_COLORS[p.status] ?? "#94a3b8"} /></td>
                  <td className="px-4 py-3" style={{ color: "#94a3b8" }}>{fmtDate(p.created_at)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Coin Transactions */}
      <div>
        <div className="text-white font-semibold mb-3">Tranzaksyon Coins</div>
        <div className="rounded-xl overflow-hidden" style={{ border: "1px solid #2e3060" }}>
          <table className="w-full text-sm">
            <thead>
              <tr style={{ background: "#0a0b18", borderBottom: "1px solid #2e3060" }}>
                {["Itilizatè", "Montan", "Frè", "Tip", "Estati", "Dat"].map((h) => (
                  <th key={h} className="px-4 py-3 text-left text-xs font-semibold uppercase" style={{ color: "#94a3b8" }}>{h}</th>
                ))}
              </tr>
              <tr style={{ background: "#0a0b18", borderBottom: "1px solid #2e3060" }}>
                {[
                  ["user", "Filtre itilizatè"],
                  ["amount", "Filtre montan"],
                  ["fee", "Filtre frè"],
                  ["type", "Filtre tip"],
                  ["status", "Filtre estati"],
                  ["date", "Filtre dat"],
                ].map(([key, placeholder]) => (
                  <th key={key} className="px-4 pb-3">
                    <input value={coinFilters[key as keyof typeof coinFilters]}
                      onChange={(e) => setCoinFilters((prev) => ({ ...prev, [key]: e.target.value }))}
                      placeholder={placeholder}
                      className="w-full px-2 py-1.5 rounded-md text-xs text-white outline-none"
                      style={{ background: "#0e0f1e", border: "1px solid #2e3060" }} />
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {filteredCoins.length === 0 && (
                <tr><td colSpan={6} className="px-4 py-8 text-center" style={{ color: "#94a3b8" }}>Pa gen tranzaksyon yo</td></tr>
              )}
              {filteredCoins.map((c) => (
                <tr key={c.id} style={{ borderBottom: "1px solid #2e3060", background: "#0e0f1e" }}>
                  <td className="px-4 py-3" style={{ color: "#a78bfa" }}>@{usernameFrom(c.user ?? null) ?? c.user_id?.slice(0, 8)}</td>
                  <td className="px-4 py-3 font-semibold" style={{ color: "#fcd34d" }}>{c.amount}</td>
                  <td className="px-4 py-3" style={{ color: "#94a3b8" }}>{c.fee ?? 0}</td>
                  <td className="px-4 py-3" style={{ color: "#94a3b8" }}>{c.transaction_type ?? "—"}</td>
                  <td className="px-4 py-3"><Badge label={c.status} color={STATUS_COLORS[c.status] ?? "#94a3b8"} /></td>
                  <td className="px-4 py-3" style={{ color: "#94a3b8" }}>{fmtDate(c.created_at)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </>
  );
}
