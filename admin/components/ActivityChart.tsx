"use client";

import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Legend,
} from "recharts";

type ActivityPoint = { day: string; votes: number; arguments: number };

const CustomTooltip = ({ active, payload, label }: any) => {
  if (active && payload && payload.length) {
    return (
      <div
        style={{
          background: "#13152a",
          border: "1px solid #2d1b69",
          borderRadius: 8,
          padding: "10px 14px",
          fontSize: 12,
        }}
      >
        <p style={{ color: "#94a3b8", marginBottom: 6 }}>{label}</p>
        {payload.map((p: any) => (
          <p key={p.dataKey} style={{ color: p.color, margin: "2px 0" }}>
            {p.name}: <strong>{p.value.toLocaleString()}</strong>
          </p>
        ))}
      </div>
    );
  }
  return null;
};

export default function ActivityChart({ data }: { data: ActivityPoint[] }) {
  return (
    <div
      className="rounded-xl p-5"
      style={{ background: "#0e0f1e", border: "1px solid #2e3060" }}
    >
      <div className="flex items-center justify-between mb-5">
        <div>
          <div className="text-white font-semibold text-sm">Aktivite sou platfòm nan</div>
          <div style={{ color: "#94a3b8", fontSize: 11, marginTop: 2 }}>Vòt ak Agiman</div>
        </div>
        <div
          className="flex items-center gap-1 text-xs px-2 py-1 rounded-full"
          style={{ background: "rgba(124,58,237,0.15)", color: "#a78bfa" }}
        >
          7 jou yo
        </div>
      </div>

      <ResponsiveContainer width="100%" height={200}>
        <LineChart data={data} margin={{ top: 5, right: 5, left: -20, bottom: 0 }}>
          <CartesianGrid strokeDasharray="3 3" stroke="#1e2040" vertical={false} />
          <XAxis
            dataKey="day"
            tick={{ fill: "#475569", fontSize: 10 }}
            axisLine={false}
            tickLine={false}
          />
          <YAxis
            tick={{ fill: "#475569", fontSize: 10 }}
            axisLine={false}
            tickLine={false}
            tickFormatter={(v) => `${(v / 1000).toFixed(0)}k`}
          />
          <Tooltip content={<CustomTooltip />} />
          <Line
            type="monotone"
            dataKey="votes"
            name="Vòt"
            stroke="#7c3aed"
            strokeWidth={2.5}
            dot={false}
            activeDot={{ r: 5, fill: "#7c3aed" }}
          />
          <Line
            type="monotone"
            dataKey="arguments"
            name="Agiman"
            stroke="#ec4899"
            strokeWidth={2.5}
            dot={false}
            activeDot={{ r: 5, fill: "#ec4899" }}
          />
        </LineChart>
      </ResponsiveContainer>

      {/* Legend */}
      <div className="flex items-center gap-4 mt-3">
        <div className="flex items-center gap-1.5">
          <div className="rounded-full" style={{ width: 8, height: 8, background: "#7c3aed" }} />
          <span style={{ color: "#94a3b8", fontSize: 11 }}>Vòt</span>
        </div>
        <div className="flex items-center gap-1.5">
          <div className="rounded-full" style={{ width: 8, height: 8, background: "#ec4899" }} />
          <span style={{ color: "#94a3b8", fontSize: 11 }}>Agiman</span>
        </div>
      </div>
    </div>
  );
}
