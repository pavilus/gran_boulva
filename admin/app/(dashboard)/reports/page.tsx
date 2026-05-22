import { createAdminClient } from "@/lib/supabase/admin";
import Topbar from "@/components/Topbar";
import ReportList from "./ReportList";

export default async function ReportsPage() {
  const supabase = createAdminClient();

  const { data: reports } = await supabase
    .from("reports")
    .select("*")
    .order("created_at", { ascending: false })
    .limit(200);

  const argumentIds = (reports ?? [])
    .filter((report) => report.reported_type === "argument" && report.reported_id)
    .map((report) => report.reported_id);
  const { data: reportedArguments } = argumentIds.length
    ? await supabase
      .from("arguments")
      .select("id, body, status, matchup:matchups(title_ht), user:users(username)")
      .in("id", argumentIds)
    : { data: [] };

  const argumentById = new Map((reportedArguments ?? []).map((argument) => [argument.id, argument]));
  const enrichedReports = (reports ?? []).map((report) => ({
    ...report,
    argument: report.reported_type === "argument"
      ? argumentById.get(report.reported_id) ?? null
      : null,
  }));

  const pendingCount = enrichedReports.filter((r) => r.status === "pending").length;

  return (
    <div className="flex flex-col flex-1 min-h-0 overflow-y-auto" style={{ background: "#07080f" }}>
      <Topbar
        title="Rapò"
        subtitle={pendingCount > 0 ? `${pendingCount} k ap tann revizyon` : undefined}
      />
      <div className="flex-1 p-5">
        <ReportList reports={enrichedReports} />
      </div>
    </div>
  );
}
