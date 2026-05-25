import { createAdminClient } from "@/lib/supabase/admin";
import Topbar from "@/components/Topbar";
import BadgesClient from "./BadgesClient";

export default async function BadgesPage() {
  const supabase = createAdminClient();

  const [{ data: badges }, { data: levels }, { data: userBadges }] = await Promise.all([
    supabase.from("badges").select("*").order("sort_order"),
    supabase.from("badge_levels").select("*").order("level", { ascending: true }),
    supabase.from("user_badges").select("badge_id").gt("current_level", 0),
  ]);

  // Count users who have earned each badge (level > 0)
  const countMap: Record<string, number> = {};
  for (const ub of userBadges ?? []) {
    countMap[ub.badge_id] = (countMap[ub.badge_id] ?? 0) + 1;
  }

  const badgesWithLevels = (badges ?? []).map((b) => ({
    ...b,
    levels: (levels ?? []).filter((l) => l.badge_id === b.id),
    user_count: countMap[b.id] ?? 0,
  }));

  return (
    <div className="flex flex-col flex-1 min-h-0 overflow-y-auto" style={{ background: "#07080f" }}>
      <Topbar title="Badj" />
      <div className="flex-1 p-5">
        <BadgesClient badges={badgesWithLevels} />
      </div>
    </div>
  );
}
