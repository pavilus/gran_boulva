"use client";

import { Bell, Calendar, AlertTriangle } from "lucide-react";
import Link from "next/link";
import { useState, useEffect } from "react";
import { createClient } from "@/lib/supabase/client";

interface TopbarProps {
  title: string;
  subtitle?: string;
}

function currentWeekRange(): string {
  const now = new Date();
  const day = now.getDay(); // 0 = Sunday
  const diffToMon = day === 0 ? -6 : 1 - day;
  const mon = new Date(now);
  mon.setDate(now.getDate() + diffToMon);
  const sun = new Date(mon);
  sun.setDate(mon.getDate() + 6);
  const fmt = (d: Date) =>
    d.toLocaleDateString("en-US", { month: "short", day: "numeric" });
  return `${fmt(mon)} – ${fmt(sun)}, ${now.getFullYear()}`;
}

export default function Topbar({ title, subtitle }: TopbarProps) {
  const [unread, setUnread] = useState(0);
  const weekRange = currentWeekRange();

  useEffect(() => {
    const supabase = createClient();
    supabase
      .from("notifications")
      .select("*", { count: "exact", head: true })
      .eq("is_read", false)
      .then(({ count }) => { if (count != null) setUnread(count); });
  }, []);

  return (
    <div
      className="flex items-center justify-between px-6 shrink-0"
      style={{ height: 64, borderBottom: "1px solid #1e2040", background: "#07080f" }}
    >
      {/* Left — page title + alert badge */}
      <div className="flex items-center gap-3">
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

      {/* Right — current week + notification bell */}
      <div className="flex items-center gap-3">

        {/* Current week chip */}
        <div
          className="flex items-center gap-2 px-3 py-1.5 rounded-lg text-xs"
          style={{ background: "#0e0f1e", border: "1px solid #1e2040", color: "#94a3b8" }}
        >
          <Calendar size={13} />
          <span>{weekRange}</span>
        </div>

        {/* Notification bell — links to /notifications */}
        <Link href="/notifications">
          <div
            className="relative flex items-center justify-center rounded-lg cursor-pointer hover:border-purple-500/50 transition-colors"
            style={{ width: 34, height: 34, background: "#0e0f1e", border: "1px solid #1e2040", color: "#94a3b8" }}
          >
            <Bell size={15} />
            {unread > 0 && (
              <span
                className="absolute top-1 right-1 rounded-full flex items-center justify-center"
                style={{
                  minWidth: unread > 9 ? 14 : 8,
                  height: unread > 9 ? 14 : 8,
                  background: "#ec4899",
                  fontSize: 8,
                  fontWeight: 700,
                  color: "white",
                  padding: unread > 9 ? "0 2px" : 0,
                }}
              >
                {unread > 9 ? "9+" : ""}
              </span>
            )}
          </div>
        </Link>

      </div>
    </div>
  );
}
