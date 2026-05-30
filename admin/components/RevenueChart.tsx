"use client";

import Link from "next/link";
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Legend,
} from "recharts";

type RevenuePoint = { day: string; coinRevenue: number; supporterRevenue: number };

const CustomTooltip = ({ active, payload, label }: any) => {
  if (active && payload && payload.length) {
    const coins     = payload.find((p: any) => p.dataKey === "coinRevenue")?.value ?? 0;
    const supporter = payload.find((p: any) => p.dataKey === "supporterRevenue")?.value ?? 0;
    return (
      <div style={{ background: "#13152a", border: "1px solid #2d1b69", borderRadius: 8, padding: "8px 12px", fontSize: 12 }}>
        <p style={{ color: "#94a3b8", marginBottom: 4 }}>{label}</p>
        {coins > 0     && <p style={{ color: "#10b981", fontWeight: 700, margin: "2px 0" }}>Coins: ${coins.toFixed(2)}</p>}
        {supporter > 0 && <p style={{ color: "#a78bfa", fontWeight: 700, margin: "2px 0" }}>Sipòtè: ${supporter.toFixed(2)}</p>}
        <p style={{ color: "#e2e8f0", fontWeight: 700, margin: "4px 0 0", borderTop: "1px solid #2d1b69", paddingTop: 4 }}>
          Total: ${(coins + supporter).toFixed(2)}
        </p>
      </div>
    );
  }
  return null;
};

export default function RevenueChart({
  data,
  totalRevenue,
  totalCoinRevenue,
  totalSupporterRevenue,
  revenueChange,
}: {
  data: RevenuePoint[];
  totalRevenue: number;
  totalCoinRevenue: number;
  totalSupporterRevenue: number;
  revenueChange: number;
}) {
  const weekTotal  = data.reduce((s, d) => s + d.coinRevenue + d.supporterRevenue, 0);
  const positive   = revenueChange >= 0;

  return (
    <div className="rounded-xl p-5" style={{ background: "#0e0f1e", border: "1px solid #1e2040" }}>
      <div className="flex items-center justify-between mb-3">
        <div>
          <div className="text-white font-semibold text-sm">Revni sou 7 jòu yo</div>
          <div className="font-bold mt-0.5" style={{ color: "#10b981", fontSize: 20 }}>
            ${weekTotal.toFixed(2)}
          </div>
        </div>
        <div
          className="text-xs px-2 py-1 rounded-full font-semibold"
          style={{
            background: positive ? "rgba(16,185,129,0.12)" : "rgba(239,68,68,0.12)",
            color: positive ? "#10b981" : "#ef4444",
          }}
        >
          {positive ? "↑" : "↓"} {Math.abs(revenueChange)}%
        </div>
      </div>

      {/* Split revenue totals */}
      <div className="flex gap-3 mb-3">
        <div className="flex-1 rounded-lg px-3 py-2" style={{ background: "rgba(16,185,129,0.07)", border: "1px solid rgba(16,185,129,0.15)" }}>
          <div style={{ color: "#94a3b8", fontSize: 9, textTransform: "uppercase", letterSpacing: 1 }}>Vant Coins</div>
          <div style={{ color: "#10b981", fontWeight: 700, fontSize: 14 }}>${totalCoinRevenue.toFixed(2)}</div>
        </div>
        <div className="flex-1 rounded-lg px-3 py-2" style={{ background: "rgba(167,139,250,0.07)", border: "1px solid rgba(167,139,250,0.15)" }}>
          <div style={{ color: "#94a3b8", fontSize: 9, textTransform: "uppercase", letterSpacing: 1 }}>Kreyatè Fondatè</div>
          <div style={{ color: "#a78bfa", fontWeight: 700, fontSize: 14 }}>${totalSupporterRevenue.toFixed(2)}</div>
        </div>
      </div>

      <div className="flex items-center justify-between mb-1">
        <span style={{ color: "#94a3b8", fontSize: 10 }}>Total: ${totalRevenue.toFixed(2)}</span>
        <Link href="/payments" style={{ color: "#a78bfa", fontSize: 11, textDecoration: "none" }}>Wè tout →</Link>
      </div>

      <ResponsiveContainer width="100%" height={120}>
        <BarChart data={data} margin={{ top: 0, right: 0, left: -24, bottom: 0 }} barSize={12}>
          <CartesianGrid strokeDasharray="3 3" stroke="#1e2040" vertical={false} />
          <XAxis dataKey="day" tick={{ fill: "#475569", fontSize: 9 }} axisLine={false} tickLine={false} />
          <YAxis tick={{ fill: "#475569", fontSize: 9 }} axisLine={false} tickLine={false} tickFormatter={(v) => `$${v.toFixed(0)}`} />
          <Tooltip content={<CustomTooltip />} cursor={{ fill: "rgba(124,58,237,0.05)" }} />
          <Bar dataKey="coinRevenue"      name="Coins"    stackId="a" fill="#10b981" radius={[0, 0, 0, 0]} />
          <Bar dataKey="supporterRevenue" name="Sipòtè"   stackId="a" fill="#7c3aed" radius={[4, 4, 0, 0]} />
        </BarChart>
      </ResponsiveContainer>
    </div>
  );
}
