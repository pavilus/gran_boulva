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
  Cell,
} from "recharts";

type RevenuePoint = { day: string; revenue: number };

const CustomTooltip = ({ active, payload, label }: any) => {
  if (active && payload && payload.length) {
    return (
      <div
        style={{
          background: "#13152a",
          border: "1px solid #2d1b69",
          borderRadius: 8,
          padding: "8px 12px",
          fontSize: 12,
        }}
      >
        <p style={{ color: "#94a3b8", marginBottom: 4 }}>{label}</p>
        <p style={{ color: "#10b981", fontWeight: 700 }}>
          ${payload[0].value.toFixed(2)}
        </p>
      </div>
    );
  }
  return null;
};

export default function RevenueChart({
  data,
  totalRevenue,
  revenueChange,
}: {
  data: RevenuePoint[];
  totalRevenue: number;
  revenueChange: number;
}) {
  const weekTotal = data.reduce((s, d) => s + d.revenue, 0);
  const positive = revenueChange >= 0;

  return (
    <div
      className="rounded-xl p-5"
      style={{ background: "#0e0f1e", border: "1px solid #1e2040" }}
    >
      <div className="flex items-center justify-between mb-4">
        <div>
          <div className="text-white font-semibold text-sm">Revni sou 7 jòu yo</div>
          <div className="font-bold mt-0.5" style={{ color: "#10b981", fontSize: 20 }}>
            ${weekTotal.toFixed(2)}
          </div>
          <div style={{ color: "#475569", fontSize: 10, marginTop: 2 }}>
            Total: ${totalRevenue.toFixed(2)}
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

      <div className="flex items-center justify-between mb-1">
        <span style={{ color: "#475569", fontSize: 10 }}>7 jou ki pase yo</span>
        <Link href="/payments" style={{ color: "#a78bfa", fontSize: 11, textDecoration: "none" }}>Wè tout →</Link>
      </div>

      <ResponsiveContainer width="100%" height={130}>
        <BarChart data={data} margin={{ top: 0, right: 0, left: -24, bottom: 0 }} barSize={16}>
          <CartesianGrid strokeDasharray="3 3" stroke="#1e2040" vertical={false} />
          <XAxis
            dataKey="day"
            tick={{ fill: "#475569", fontSize: 9 }}
            axisLine={false}
            tickLine={false}
          />
          <YAxis
            tick={{ fill: "#475569", fontSize: 9 }}
            axisLine={false}
            tickLine={false}
            tickFormatter={(v) => `$${v.toFixed(0)}`}
          />
          <Tooltip content={<CustomTooltip />} cursor={{ fill: "rgba(124,58,237,0.05)" }} />
          <Bar dataKey="revenue" radius={[4, 4, 0, 0]}>
            {data.map((_, i) => (
              <Cell
                key={i}
                fill={i === data.length - 1 ? "#7c3aed" : "rgba(124,58,237,0.35)"}
              />
            ))}
          </Bar>
        </BarChart>
      </ResponsiveContainer>
    </div>
  );
}
