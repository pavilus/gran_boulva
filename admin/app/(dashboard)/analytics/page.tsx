import { createAdminClient } from "@/lib/supabase/admin";
import Topbar from "@/components/Topbar";
import ActivityChart from "@/components/ActivityChart";
import { getActivitySeries } from "@/lib/dashboard";
import { Users, Vote, MessageSquare, TrendingUp } from "lucide-react";

function StatBox({ label, value, icon: Icon, color }: { label: string; value: string; icon: any; color: string }) {
  return (
    <div className="rounded-xl p-5 flex items-center gap-4" style={{ background: "#0e0f1e", border: "1px solid #1e2040" }}>
      <div className="flex items-center justify-center rounded-xl shrink-0" style={{ width: 44, height: 44, background: `${color}22` }}>
        <Icon size={20} color={color} />
      </div>
      <div>
        <div className="text-white font-bold text-xl">{value}</div>
        <div style={{ color: "#64748b", fontSize: 12 }}>{label}</div>
      </div>
    </div>
  );
}

function fmt(n: number) {
  if (n >= 1_000_000) return `${(n / 1_000_000).toFixed(1)}M`;
  if (n >= 1_000) return `${(n / 1_000).toFixed(1)}K`;
  return `${n}`;
}

export default async function AnalyticsPage() {
  const supabase = createAdminClient();

  const [
    activity,
    { count: userCount },
    { count: voteCount },
    { count: argCount },
    { count: predCount },
  ] = await Promise.all([
    getActivitySeries(),
    supabase.from("users").select("*", { count: "exact", head: true }),
    supabase.from("votes").select("*", { count: "exact", head: true }),
    supabase.from("arguments").select("*", { count: "exact", head: true }),
    supabase.from("predictions").select("*", { count: "exact", head: true }),
  ]);

  // 30-day trend
  const since30 = new Date();
  since30.setDate(since30.getDate() - 30);
  const { data: newUsers } = await supabase
    .from("users")
    .select("created_at")
    .gte("created_at", since30.toISOString());

  const { data: newVotes } = await supabase
    .from("votes")
    .select("created_at")
    .gte("created_at", since30.toISOString());

  return (
    <div className="flex flex-col flex-1 min-h-0 overflow-y-auto" style={{ background: "#07080f" }}>
      <Topbar title="Analytics" />
      <div className="flex-1 p-5 space-y-5">

        {/* KPI row */}
        <div className="grid grid-cols-4 gap-4">
          <StatBox label="Itilizatè total" value={fmt(userCount ?? 0)} icon={Users} color="#a78bfa" />
          <StatBox label="Vòt total" value={fmt(voteCount ?? 0)} icon={Vote} color="#67e8f9" />
          <StatBox label="Agiman total" value={fmt(argCount ?? 0)} icon={MessageSquare} color="#f9a8d4" />
          <StatBox label="Prediksyon" value={fmt(predCount ?? 0)} icon={TrendingUp} color="#6ee7b7" />
        </div>

        {/* 7-day activity chart */}
        <ActivityChart data={activity} />

        {/* 30-day summary cards */}
        <div className="grid grid-cols-2 gap-4">
          <div className="rounded-xl p-5" style={{ background: "#0e0f1e", border: "1px solid #1e2040" }}>
            <div className="text-white font-semibold mb-1">Nouvo itilizatè (30j)</div>
            <div className="text-3xl font-bold" style={{ color: "#a78bfa" }}>{fmt(newUsers?.length ?? 0)}</div>
            <div style={{ color: "#475569", fontSize: 12, marginTop: 4 }}>Enskripsyon nouvèl</div>
          </div>
          <div className="rounded-xl p-5" style={{ background: "#0e0f1e", border: "1px solid #1e2040" }}>
            <div className="text-white font-semibold mb-1">Vòt (30j)</div>
            <div className="text-3xl font-bold" style={{ color: "#67e8f9" }}>{fmt(newVotes?.length ?? 0)}</div>
            <div style={{ color: "#475569", fontSize: 12, marginTop: 4 }}>Vòt ranmasé</div>
          </div>
        </div>

      </div>
    </div>
  );
}
