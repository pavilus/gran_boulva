import { createAdminClient } from "@/lib/supabase/admin";
import Topbar from "@/components/Topbar";
import BoostTable from "./BoostTable";

export default async function BoostsPage() {
  const supabase = createAdminClient();

  const { data: boosts } = await supabase
    .from("boosts")
    .select("*, argument:arguments(body, user:users(username)), argument_id")
    .order("created_at", { ascending: false })
    .limit(100);

  const active = (boosts ?? []).filter((b) => {
    if (!b.expires_at) return false;
    return new Date(b.expires_at) > new Date();
  });

  return (
    <div className="flex flex-col flex-1 min-h-0 overflow-y-auto" style={{ background: "#07080f" }}>
      <Topbar title="Boosts" subtitle={active.length > 0 ? `${active.length} aktif` : undefined} />
      <div className="flex-1 p-5">
        <BoostTable boosts={boosts ?? []} />
      </div>
    </div>
  );
}
