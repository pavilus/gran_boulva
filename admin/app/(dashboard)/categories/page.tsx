import { createAdminClient } from "@/lib/supabase/admin";
import Topbar from "@/components/Topbar";
import CategoriesClient from "./CategoriesClient";

export default async function CategoriesPage() {
  const supabase = createAdminClient();

  const [{ data: categories }, { data: counts }] = await Promise.all([
    supabase.from("categories").select("id, name_ht, name_en, icon").order("name_ht"),
    supabase.from("matchups").select("category_id"),
  ]);

  const countMap: Record<string, number> = {};
  for (const m of counts ?? []) {
    if (m.category_id) countMap[m.category_id] = (countMap[m.category_id] ?? 0) + 1;
  }

  return (
    <div className="flex flex-col flex-1 min-h-0 overflow-y-auto" style={{ background: "#07080f" }}>
      <Topbar title="Kategorì" />
      <div className="flex-1 p-5">
        <CategoriesClient categories={categories ?? []} countMap={countMap} />
      </div>
    </div>
  );
}
