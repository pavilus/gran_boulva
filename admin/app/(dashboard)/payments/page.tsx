import { createAdminClient } from "@/lib/supabase/admin";
import Topbar from "@/components/Topbar";
import PaymentTables from "./PaymentTables";

export default async function PaymentsPage() {
  const supabase = createAdminClient();

  const [{ data: purchases }, { data: coins }] = await Promise.all([
    supabase
      .from("coin_purchases")
      .select("id, coin_amount, usd_cents, status, created_at, user_id, user:users(username)")
      .order("created_at", { ascending: false })
      .limit(100),
    supabase
      .from("coin_transactions")
      .select("id, amount, fee, transaction_type, status, created_at, user_id, user:users(username)")
      .order("created_at", { ascending: false })
      .limit(100),
  ]);

  const totalRev = (purchases ?? [])
    .filter((p) => p.status === "succeeded")
    .reduce((s, p) => s + (p.usd_cents ?? 0), 0);

  const totalCoins = (purchases ?? [])
    .filter((p) => p.status === "succeeded")
    .reduce((s, p) => s + (p.coin_amount ?? 0), 0);

  return (
    <div className="flex flex-col flex-1 min-h-0 overflow-y-auto" style={{ background: "#07080f" }}>
      <Topbar title="Pèman & Referans" />
      <div className="flex-1 p-5 space-y-5">
        <div className="grid grid-cols-2 gap-4">
          <div className="rounded-xl p-5" style={{ background: "#0e0f1e", border: "1px solid #2e3060" }}>
            <div style={{ color: "#6ee7b7", fontSize: 12 }}>Revni Total (USD)</div>
            <div className="text-3xl font-bold text-white mt-1">${(totalRev / 100).toFixed(2)}</div>
          </div>
          <div className="rounded-xl p-5" style={{ background: "#0e0f1e", border: "1px solid #2e3060" }}>
            <div style={{ color: "#fcd34d", fontSize: 12 }}>Coins Achte</div>
            <div className="text-3xl font-bold text-white mt-1">{totalCoins.toLocaleString()}</div>
          </div>
        </div>

        <PaymentTables purchases={purchases ?? []} coins={coins ?? []} />
      </div>
    </div>
  );
}
