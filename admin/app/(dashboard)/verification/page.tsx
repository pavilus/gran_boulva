import { createAdminClient } from "@/lib/supabase/admin";
import Topbar from "@/components/Topbar";
import VerificationList from "./VerificationList";

export default async function VerificationPage() {
  const supabase = createAdminClient();

  const { data: requests } = await supabase
    .from("verification_requests")
    .select("*, user:users!verification_requests_user_id_fkey(username, avatar_url, verification_status)")
    .order("submitted_at", { ascending: false });

  const pending = (requests ?? []).filter((r) => r.status === "pending").length;

  return (
    <div className="flex flex-col flex-1 min-h-0 overflow-y-auto" style={{ background: "#07080f" }}>
      <Topbar
        title={`Verifikasyon${pending > 0 ? ` · ${pending} an atant` : ""}`}
      />
      <div className="flex-1 p-5">
        <VerificationList requests={requests ?? []} />
      </div>
    </div>
  );
}
