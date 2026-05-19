import { createAdminClient } from "@/lib/supabase/admin";
import Topbar from "@/components/Topbar";
import ScoutList from "./ScoutList";

export default async function ScoutPage() {
  const supabase = createAdminClient();

  const [{ data: drafts }, { data: categories }] = await Promise.all([
    supabase
      .from("ai_generated_drafts")
      .select("id, type, title_ht, title_en, option_a, option_b, description_ht, image_url_a, image_url_b, deadline_at, combined_score, trend_score, debate_score, safety_score, popularity_score, virality_score, uniqueness_score, relevance_score, prediction_score, risk_level, status, created_at, category_id, source_links, source_platform, trending_keywords, detected_entities, selection_reason, category:categories(name_ht)")
      .in("status", ["pending", "approved", "rejected"])
      .order("created_at", { ascending: false })
      .limit(50),
    supabase
      .from("categories")
      .select("id, name_ht, name_en")
      .order("name_ht"),
  ]);

  const pending = (drafts ?? []).filter((d) => d.status === "pending");
  const approved = (drafts ?? []).filter((d) => d.status === "approved");
  const rejected = (drafts ?? []).filter((d) => d.status === "rejected");

  return (
    <div className="flex flex-col flex-1 min-h-0 overflow-y-auto" style={{ background: "#07080f" }}>
      <Topbar
        title="AI Boulva Scout"
        subtitle={pending.length > 0 ? `${pending.length} k ap tann revizyon` : undefined}
      />
      <div className="flex-1 p-5">
        <ScoutList
          pending={pending}
          approved={approved}
          rejected={rejected}
          categories={categories ?? []}
        />
      </div>
    </div>
  );
}
