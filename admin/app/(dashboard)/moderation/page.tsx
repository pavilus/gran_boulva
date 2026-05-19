import { createAdminClient } from "@/lib/supabase/admin";
import Topbar from "@/components/Topbar";
import ModerationList from "./ModerationList";

export default async function ModerationPage() {
  const supabase = createAdminClient();

  const { data: args } = await supabase
    .from("arguments")
    .select("id, body, status, like_count, dislike_count, reply_count, created_at, matchup_id, user_id, option_id, matchup:matchups(title_ht), user:users(username, avatar_url)")
    .order("created_at", { ascending: false })
    .limit(200);

  const flaggedCount = (args ?? []).filter((a) => a.status === "flagged").length;

  return (
    <div className="flex flex-col flex-1 min-h-0 overflow-y-auto" style={{ background: "#07080f" }}>
      <Topbar
        title="Agiman & Modération"
        subtitle={flaggedCount > 0 ? `${flaggedCount} flagged` : undefined}
      />
      <div className="flex-1 p-5">
        <ModerationList args={args ?? []} />
      </div>
    </div>
  );
}
