"use client";

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

const data = [
  { day: "May 9",  revenue: 2800 },
  { day: "May 10", revenue: 3400 },
  { day: "May 11", revenue: 2200 },
  { day: "May 12", revenue: 4600 },
  { day: "May 13", revenue: 3900 },
  { day: "May 14", revenue: 4100 },
  { day: "May 15", revenue: 3890 },
];

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
          ${payload[0].value.toLocaleString()}
        </p>
      </div>
    );
  }
  return null;
};

export default function RevenueChart() {
  return (
    <div
      className="rounded-xl p-5"
      style={{ background: "#0e0f1e", border: "1px solid #1e2040" }}
    >
      <div className="flex items-center justify-between mb-4">
        <div>
          <div className="text-white font-semibold text-sm">Revni sou 7 jòu yo</div>
          <div className="font-bold mt-0.5" style={{ color: "#10b981", fontSize: 20 }}>
            $24,890
          </div>
        </div>
        <div
          className="text-xs px-2 py-1 rounded-full font-semibold"
          style={{ background: "rgba(16,185,129,0.12)", color: "#10b981" }}
        >
          ↑ 8.3%
        </div>
      </div>

      <ResponsiveContainer width="100%" height={150}>
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
            tickFormatter={(v) => `$${(v / 1000).toFixed(0)}k`}
          />
          <Tooltip content={<CustomTooltip />} cursor={{ fill: "rgba(124,58,237,0.05)" }} />
          <Bar dataKey="revenue" radius={[4, 4, 0, 0]}>
            {data.map((_, i) => (
              <Cell
                key={i}
                fill={i === data.length - 2 ? "#7c3aed" : "rgba(124,58,237,0.35)"}
              />
            ))}
          </Bar>
        </BarChart>
      </ResponsiveContainer>
    </div>
  );
}
