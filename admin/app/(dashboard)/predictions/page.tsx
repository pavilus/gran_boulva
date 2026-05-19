import { createAdminClient } from "@/lib/supabase/admin";
import Topbar from "@/components/Topbar";
import PredictionList from "./PredictionList";

export default async function PredictionsPage() {
  const supabase = createAdminClient();

  const [{ data: predictions }, { data: categories }, { data: predictionDrafts }] = await Promise.all([
    supabase
      .from("predictions")
      .select("id, title_ht, title_en, option_a, option_b, deadline_at, status, winning_option, total_votes, category_id, created_at, category:categories(name_ht)")
      .order("created_at", { ascending: false })
      .limit(200),
    supabase.from("categories").select("id, name_ht, name_en").order("name_ht"),
    supabase
      .from("ai_generated_drafts")
      .select("id, title_ht, title_en, option_a, option_b, description_ht, deadline_at, combined_score, category_id, source_platform, risk_level, status, created_at, selection_reason, category:categories(name_ht)")
      .eq("type", "prediction")
      .eq("status", "pending")
      .order("combined_score", { ascending: false }),
  ]);

  return (
    <div className="flex flex-col flex-1 min-h-0 overflow-y-auto" style={{ background: "#07080f" }}>
      <Topbar
        title="Prediksyon"
        subtitle={predictionDrafts && predictionDrafts.length > 0 ? `${predictionDrafts.length} sijèsyon scout k ap tann` : undefined}
      />
      <div className="flex-1 p-5">
        <PredictionList
          predictions={predictions ?? []}
          categories={categories ?? []}
          predictionDrafts={predictionDrafts ?? []}
        />
      </div>
    </div>
  );
}
