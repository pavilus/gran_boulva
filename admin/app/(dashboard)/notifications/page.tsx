import { createAdminClient } from "@/lib/supabase/admin";
import Topbar from "@/components/Topbar";
import NotificationsClient from "./NotificationsClient";

export default async function NotificationsPage() {
  const supabase = createAdminClient();

  // Recent notifications (broadcast ones — no specific user_id, or system-type)
  const { data: recent } = await supabase
    .from("notifications")
    .select("id, type, title, body, created_at, is_read")
    .order("created_at", { ascending: false })
    .limit(50);

  const { count: userCount } = await supabase
    .from("users")
    .select("*", { count: "exact", head: true });

  return (
    <div className="flex flex-col flex-1 min-h-0 overflow-y-auto" style={{ background: "#07080f" }}>
      <Topbar title="Notifikasyon" />
      <div className="flex-1 p-5">
        <NotificationsClient recent={recent ?? []} userCount={userCount ?? 0} />
      </div>
    </div>
  );
}
