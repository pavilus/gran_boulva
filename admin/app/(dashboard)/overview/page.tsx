import Topbar from "@/components/Topbar";
import StatCard from "@/components/StatCard";
import ActivityChart from "@/components/ActivityChart";
import ScoutPanel from "@/components/ScoutPanel";
import RecentMatchups from "@/components/RecentMatchups";
import RevenueChart from "@/components/RevenueChart";
import ReportsPanel from "@/components/ReportsPanel";
import { Users, Swords, Vote, CircleDollarSign, DollarSign } from "lucide-react";
import {
  getDashboardStats,
  getRecentMatchups,
  getScoutDrafts,
  getRecentReports,
  getActivitySeries,
} from "@/lib/dashboard";

function fmt(n: number): string {
  if (n >= 1_000_000) return `${(n / 1_000_000).toFixed(2)}M`;
  if (n >= 1_000) return `${(n / 1_000).toFixed(1)}K`;
  return n.toString();
}

export default async function DashboardPage() {
  const [stats, matchups, drafts, reports, activity] = await Promise.all([
    getDashboardStats(),
    getRecentMatchups(),
    getScoutDrafts(),
    getRecentReports(),
    getActivitySeries(),
  ]);

  const STATS = [
    {
      label: "Itilizatè Aktif",
      value: fmt(stats.users),
      change: 5.4,
      changeLabel: "semèn sa",
      icon: Users,
      iconColor: "#a78bfa",
      iconBg: "rgba(124,58,237,0.18)",
    },
    {
      label: "Matchups Aktif",
      value: fmt(stats.activeMatchups),
      change: 8.1,
      changeLabel: "depi dènye",
      icon: Swords,
      iconColor: "#f9a8d4",
      iconBg: "rgba(236,72,153,0.18)",
    },
    {
      label: "Vòt Total",
      value: fmt(stats.totalVotes),
      change: 3.4,
      changeLabel: "semèn sa",
      icon: Vote,
      iconColor: "#67e8f9",
      iconBg: "rgba(6,182,212,0.15)",
    },
    {
      label: "Boulva Coins",
      value: fmt(stats.totalCoins),
      change: 3.2,
      changeLabel: "semèn sa",
      icon: CircleDollarSign,
      iconColor: "#fcd34d",
      iconBg: "rgba(245,158,11,0.15)",
    },
    {
      label: "Revni USD",
      value: fmt(stats.totalRevenue),
      change: 8.3,
      changeLabel: "depi dènye",
      icon: DollarSign,
      iconColor: "#6ee7b7",
      iconBg: "rgba(16,185,129,0.15)",
      prefix: "$",
    },
  ];

  const BOTTOM_STATS = [
    { label: "Itilizatè", value: fmt(stats.users) },
    { label: "Agiman", value: fmt(stats.totalArguments), change: "+4.8%" },
    { label: "Prediksyon", value: fmt(stats.predictions) },
    {
      label: "Rapò ijan",
      value: fmt(stats.pendingReports),
      change: stats.pendingReports > 0 ? `${stats.pendingReports} ijan` : undefined,
    },
  ];

  return (
    <div className="flex flex-col flex-1 min-h-0 overflow-y-auto" style={{ background: "#07080f" }}>
      <Topbar
        title="Dashboard"
        subtitle={stats.pendingReports > 0 ? `${stats.pendingReports} Ijans alèt` : undefined}
      />

      <div className="flex-1 p-5 space-y-4">
        {/* Stat cards */}
        <div className="flex gap-3">
          {STATS.map((s) => (
            <StatCard key={s.label} {...s} />
          ))}
        </div>

        {/* Middle row: chart + scout */}
        <div className="grid gap-4" style={{ gridTemplateColumns: "1fr 370px" }}>
          <ActivityChart data={activity} />
          <ScoutPanel drafts={drafts} />
        </div>

        {/* Bottom row: matchups + revenue + reports */}
        <div className="grid gap-4" style={{ gridTemplateColumns: "1fr 300px 280px" }}>
          <RecentMatchups matchups={matchups} />
          <RevenueChart />
          <ReportsPanel reports={reports} />
        </div>

        {/* Footer stats bar */}
        <div
          className="rounded-xl px-6 py-4 flex items-center"
          style={{ background: "#0e0f1e", border: "1px solid #1e2040" }}
        >
          {BOTTOM_STATS.map((s, i) => (
            <div key={s.label} className="flex items-center">
              <div className="px-6">
                <div className="text-white font-bold text-base">{s.value}</div>
                <div style={{ color: "#475569", fontSize: 11 }}>{s.label}</div>
                {s.change && (
                  <span className="text-xs font-semibold" style={{ color: "#10b981" }}>
                    {s.change}
                  </span>
                )}
              </div>
              {i < BOTTOM_STATS.length - 1 && (
                <div style={{ width: 1, height: 36, background: "#1e2040" }} />
              )}
            </div>
          ))}

          <div className="ml-auto flex items-center gap-3">
            <div>
              <div style={{ color: "#fcd34d", fontSize: 11, fontWeight: 600 }}>Boulva Coins</div>
              <div className="text-white font-bold text-lg">{fmt(stats.totalCoins)}</div>
            </div>
            <div
              className="flex items-center justify-center rounded-xl"
              style={{
                width: 48,
                height: 48,
                background: "linear-gradient(135deg,#f59e0b,#fcd34d)",
                boxShadow: "0 0 20px rgba(245,158,11,0.4)",
              }}
            >
              <CircleDollarSign size={24} color="#07080f" />
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
