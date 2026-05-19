import { createAdminClient } from "@/lib/supabase/admin";
import Topbar from "@/components/Topbar";
import UserList from "./UserList";

export default async function UsersPage() {
  const supabase = createAdminClient();

  const { data: users } = await supabase
    .from("users")
    .select("id, full_name, username, email, role, avatar_url, influence_score, participation_count, coin_balance, created_at")
    .order("created_at", { ascending: false })
    .limit(200);

  return (
    <div className="flex flex-col flex-1 min-h-0 overflow-y-auto" style={{ background: "#07080f" }}>
      <Topbar title="Itilizatè" />
      <div className="flex-1 p-5">
        <UserList users={users ?? []} />
      </div>
    </div>
  );
}
