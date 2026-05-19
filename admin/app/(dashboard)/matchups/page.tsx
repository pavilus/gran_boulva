import { createAdminClient } from "@/lib/supabase/admin";
import Topbar from "@/components/Topbar";
import MatchupList from "./MatchupList";

export default async function MatchupsPage() {
  const supabase = createAdminClient();

  const [{ data: matchups }, { data: categories }] = await Promise.all([
    supabase
      .from("matchups")
      .select(
        "id, title_ht, title_en, status, total_votes, engagement_score, created_at, published_at, expires_at, category_id, category:categories(name_ht), options:matchup_options(id, option_label, option_name, vote_count, image_url)"
      )
      .order("created_at", { ascending: false })
      .limit(200),
    supabase.from("categories").select("id, name_ht, name_en").order("name_ht"),
  ]);

  const draftCount = (matchups ?? []).filter((m) => m.status === "draft").length;

  return (
    <div className="flex flex-col flex-1 min-h-0 overflow-y-auto" style={{ background: "#07080f" }}>
      <Topbar
        title="Matchups"
        subtitle={draftCount > 0 ? `${draftCount} draft an atant` : undefined}
      />
      <div className="flex-1 p-5">
        <MatchupList matchups={matchups ?? []} categories={categories ?? []} />
      </div>
    </div>
  );
}
