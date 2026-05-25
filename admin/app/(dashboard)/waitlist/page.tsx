import { createAdminClient } from "@/lib/supabase/admin";
import Topbar from "@/components/Topbar";
import WaitlistClient from "./WaitlistClient";

export default async function WaitlistPage() {
  const supabase = createAdminClient();

  const { data, error } = await supabase
    .from("waitlist")
    .select("*")
    .order("created_at", { ascending: false });

  return (
    <div className="flex flex-col flex-1 min-h-0 overflow-y-auto" style={{ background: "#07080f" }}>
      <Topbar title="Lis Datant" />
      <div className="flex-1 p-5">
        {error ? (
          <div style={{ background: "rgba(239,68,68,0.08)", border: "1px solid rgba(239,68,68,0.3)", borderRadius: 12, padding: 20 }}>
            <p style={{ color: "#f87171", fontSize: 13, fontFamily: "monospace" }}>{error.message}</p>
          </div>
        ) : (
          <WaitlistClient entries={data ?? []} />
        )}
      </div>
    </div>
  );
}
