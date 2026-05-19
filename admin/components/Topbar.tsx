"use client";

import { Bell, Calendar, Plus, AlertTriangle } from "lucide-react";

interface TopbarProps {
  title: string;
  subtitle?: string;
}

export default function Topbar({ title, subtitle }: TopbarProps) {
  return (
    <div
      className="flex items-center justify-between px-6 shrink-0"
      style={{
        height: 64,
        borderBottom: "1px solid #1e2040",
        background: "#07080f",
      }}
    >
      {/* Left */}
      <div className="flex items-center gap-3">
        <div>
          <div className="flex items-center gap-2">
            <h1 className="text-white font-bold text-lg leading-tight">{title}</h1>
            {subtitle && (
              <span
                className="flex items-center gap-1 text-xs font-semibold px-2 py-0.5 rounded-full"
                style={{ background: "rgba(239,68,68,0.15)", color: "#f87171" }}
              >
                <AlertTriangle size={11} />
                {subtitle}
              </span>
            )}
          </div>
        </div>
      </div>

      {/* Right */}
      <div className="flex items-center gap-3">
        {/* Date range */}
        <div
          className="flex items-center gap-2 px-3 py-1.5 rounded-lg text-xs"
          style={{
            background: "#0e0f1e",
            border: "1px solid #1e2040",
            color: "#94a3b8",
          }}
        >
          <Calendar size={13} />
          <span>May 13 – May 15, 2024</span>
        </div>

        {/* Notification */}
        <button
          className="relative flex items-center justify-center rounded-lg"
          style={{
            width: 34,
            height: 34,
            background: "#0e0f1e",
            border: "1px solid #1e2040",
            color: "#94a3b8",
          }}
        >
          <Bell size={15} />
          <span
            className="absolute top-1 right-1 rounded-full"
            style={{ width: 6, height: 6, background: "#ec4899" }}
          />
        </button>

        {/* CTA */}
        <button
          className="flex items-center gap-2 px-4 py-2 rounded-lg text-xs font-semibold text-white"
          style={{
            background: "linear-gradient(90deg,#7c3aed,#a855f7)",
            boxShadow: "0 0 16px rgba(124,58,237,0.4)",
          }}
        >
          <Plus size={14} />
          Kreye Matchup
        </button>
      </div>
    </div>
  );
}
