import { redirect } from "next/navigation";
import Sidebar from "@/components/Sidebar";
import { createAdminClient } from "@/lib/supabase/admin";
import { createClient } from "@/lib/supabase/server";

const ADMIN_ROLES = new Set(["admin", "owner", "moderator"]);

export default async function DashboardLayout({ children }: { children: React.ReactNode }) {
  const sessionClient = await createClient();
  const {
    data: { user },
  } = await sessionClient.auth.getUser();

  if (!user) redirect("/login");

  const admin = createAdminClient();
  const { data: profile } = await admin
    .from("users")
    .select("role")
    .eq("auth_user_id", user.id)
    .maybeSingle();

  if (!profile || !ADMIN_ROLES.has(profile.role)) redirect("/unauthorized");

  return (
    <div className="flex h-full" style={{ background: "#07080f" }}>
      <Sidebar />
      <div className="flex flex-col flex-1 min-w-0 min-h-0 overflow-hidden">
        {children}
      </div>
    </div>
  );
}
