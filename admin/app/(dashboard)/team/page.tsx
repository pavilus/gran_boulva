import { createAdminClient } from "@/lib/supabase/admin";
import Topbar from "@/components/Topbar";

const ROLE_COLORS: Record<string, string> = {
  admin: "#a78bfa",
  owner: "#ec4899",
  moderator: "#67e8f9",
  user: "#475569",
};

function fmtDate(d: string) {
  return new Date(d).toLocaleDateString("fr-HT", { month: "short", day: "numeric", year: "numeric" });
}

export default async function TeamPage() {
  const supabase = createAdminClient();

  const { data: admins } = await supabase
    .from("users")
    .select("id, full_name, username, email, role, avatar_url, created_at")
    .in("role", ["admin", "moderator", "owner"])
    .order("role");

  return (
    <div className="flex flex-col flex-1 min-h-0 overflow-y-auto" style={{ background: "#07080f" }}>
      <Topbar title="Ekip & Pèmisyon" />
      <div className="flex-1 p-5">
        <div className="grid gap-4" style={{ gridTemplateColumns: "repeat(auto-fill, minmax(280px, 1fr))" }}>
          {(admins ?? []).length === 0 && (
            <div className="col-span-full text-center py-16" style={{ color: "#94a3b8" }}>Pa gen manm ekip yo</div>
          )}
          {(admins ?? []).map((u) => (
            <div key={u.id} className="rounded-xl p-5 flex items-center gap-4" style={{ background: "#0e0f1e", border: "1px solid #2e3060" }}>
              <div
                className="flex items-center justify-center rounded-full shrink-0 text-white font-bold text-lg"
                style={{ width: 48, height: 48, background: "linear-gradient(135deg,#7c3aed,#ec4899)" }}
              >
                {(u.full_name || u.username || "?").charAt(0).toUpperCase()}
              </div>
              <div className="flex-1 min-w-0">
                <div className="text-white font-semibold truncate">{u.full_name || u.username}</div>
                <div style={{ color: "#94a3b8", fontSize: 12 }}>@{u.username}</div>
                <div style={{ color: "#94a3b8", fontSize: 11 }}>{u.email}</div>
                <div className="flex items-center gap-2 mt-2">
                  <span
                    className="px-2 py-0.5 rounded-full text-xs font-semibold capitalize"
                    style={{ background: `${ROLE_COLORS[u.role] ?? "#475569"}22`, color: ROLE_COLORS[u.role] ?? "#475569" }}
                  >
                    {u.role}
                  </span>
                  <span style={{ color: "#94a3b8", fontSize: 11 }}>manm depi {fmtDate(u.created_at)}</span>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
