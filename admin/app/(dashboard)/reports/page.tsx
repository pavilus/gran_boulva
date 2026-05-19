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

  const pendingCount = (reports ?? []).filter((r) => r.status === "pending").length;

  return (
    <div className="flex flex-col flex-1 min-h-0 overflow-y-auto" style={{ background: "#07080f" }}>
      <Topbar
        title="Rapò"
        subtitle={pendingCount > 0 ? `${pendingCount} k ap tann revizyon` : undefined}
      />
      <div className="flex-1 p-5">
        <ReportList reports={reports ?? []} />
      </div>
    </div>
  );
}
