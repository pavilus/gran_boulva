import { createAdminClient } from "@/lib/supabase/admin";
import Topbar from "@/components/Topbar";
import CreatorsClient from "./CreatorsClient";

export default async function CreatorsPage() {
  const supabase = createAdminClient();

  // Join creator_profiles → users for display
  const { data: creators } = await supabase
    .from("creator_profiles")
    .select(`
      *,
      user:users!creator_profiles_user_id_fkey(
        id, username, avatar_url, followers_count, participation_count,
        victory_count, total_support_received, influence_score,
        verification_type, verification_status
      )
    `)
    .order("creator_score", { ascending: false });

  // Pending payout requests
  const { data: payouts } = await supabase
    .from("creator_payouts")
    .select(`
      *,
      user:users!creator_payouts_creator_user_id_fkey(username, avatar_url)
    `)
    .eq("status", "pending")
    .order("requested_at", { ascending: true });

  return (
    <div className="flex flex-col flex-1 min-h-0 overflow-y-auto" style={{ background: "#07080f" }}>
      <Topbar title="Kreyatè" />
      <div className="flex-1 p-5">
        <CreatorsClient creators={creators ?? []} pendingPayouts={payouts ?? []} />
      </div>
    </div>
  );
}
