import { createAdminClient } from "@/lib/supabase/admin";
import Topbar from "@/components/Topbar";
import AuditTable from "./AuditTable";

export default async function AuditPage() {
  const supabase = createAdminClient();

  const { data: logs } = await supabase
    .from("moderation_logs")
    .select("*, admin:users!admin_id(username), target:users!target_id(username)")
    .order("created_at", { ascending: false })
    .limit(200);

  return (
    <div className="flex flex-col flex-1 min-h-0 overflow-y-auto" style={{ background: "#07080f" }}>
      <Topbar title="CMS Logs" />
      <div className="flex-1 p-5">
        <AuditTable logs={logs ?? []} />
      </div>
    </div>
  );
}
