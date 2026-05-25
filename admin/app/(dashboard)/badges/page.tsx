import { createAdminClient } from "@/lib/supabase/admin";
import Topbar from "@/components/Topbar";
import BadgesClient from "./BadgesClient";

export default async function BadgesPage() {
  const supabase = createAdminClient();

  const [badgesRes, levelsRes, userBadgesRes] = await Promise.all([
    supabase.from("badges").select("*").order("sort_order"),
    supabase.from("badge_levels").select("*").order("level", { ascending: true }),
    supabase.from("user_badges").select("badge_id").gt("current_level", 0),
  ]);

  // Surface query errors clearly
  const errors = [
    badgesRes.error && `badges: ${badgesRes.error.message}`,
    levelsRes.error && `badge_levels: ${levelsRes.error.message}`,
    userBadgesRes.error && `user_badges: ${userBadgesRes.error.message}`,
  ].filter(Boolean);

  if (errors.length > 0) {
    return (
      <div className="flex flex-col flex-1 min-h-0 overflow-y-auto" style={{ background: "#07080f" }}>
        <Topbar title="Badj" />
        <div className="p-6">
          <div style={{ background: "rgba(239,68,68,0.08)", border: "1px solid rgba(239,68,68,0.3)", borderRadius: 12, padding: 20 }}>
            <p style={{ color: "#f87171", fontWeight: 700, marginBottom: 8 }}>Erè baz done:</p>
            {errors.map((e, i) => (
              <p key={i} style={{ color: "#fca5a5", fontSize: 13, fontFamily: "monospace" }}>{e}</p>
            ))}
          </div>
        </div>
      </div>
    );
  }

  // Count users who have earned each badge (level > 0)
  const countMap: Record<string, number> = {};
  for (const ub of userBadgesRes.data ?? []) {
    countMap[ub.badge_id] = (countMap[ub.badge_id] ?? 0) + 1;
  }

  const badgesWithLevels = (badgesRes.data ?? []).map((b) => ({
    ...b,
    levels: (levelsRes.data ?? []).filter((l) => l.badge_id === b.id),
    user_count: countMap[b.id] ?? 0,
  }));

  return (
    <div className="flex flex-col flex-1 min-h-0 overflow-y-auto" style={{ background: "#07080f" }}>
      <Topbar title="Badj" />
      <div className="flex-1 p-5">
        {badgesWithLevels.length === 0 ? (
          <div style={{ background: "#0e0f1e", border: "1px solid #1e2040", borderRadius: 12, padding: 32, textAlign: "center" }}>
            <p style={{ color: "#64748b", fontSize: 14 }}>
              Okenn badj jwenn. Tabèl <code style={{ color: "#a855f7" }}>badges</code> ka vid oswa dezaktive.
            </p>
          </div>
        ) : (
          <BadgesClient badges={badgesWithLevels} />
        )}
      </div>
    </div>
  );
}
