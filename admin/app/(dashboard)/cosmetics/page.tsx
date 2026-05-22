import { createAdminClient } from "@/lib/supabase/admin";
import Topbar from "@/components/Topbar";
import CosmeticsClient, { type CosmeticItem, type Category } from "./CosmeticsClient";

export default async function CosmeticsPage() {
  const supabase = createAdminClient();

  const [{ data: categoriesRaw }, { data: itemsRaw }] = await Promise.all([
    supabase
      .from("cosmetic_categories")
      .select("id, key, name_ht, name_en, sort_order")
      .order("sort_order"),
    supabase
      .from("cosmetic_items")
      .select(
        "id, key, name_ht, name_en, description_ht, price_coins, rarity, is_active, created_at, category_id, cosmetic_categories(key, name_ht)"
      )
      .order("created_at", { ascending: false }),
  ]);

  // Supabase returns joined relations as arrays; normalise to object | null
  const items: CosmeticItem[] = (itemsRaw ?? []).map((row) => ({
    ...(row as Omit<typeof row, "cosmetic_categories">),
    cosmetic_categories: Array.isArray(row.cosmetic_categories)
      ? (row.cosmetic_categories[0] as { key: string; name_ht: string } | undefined) ?? null
      : (row.cosmetic_categories as { key: string; name_ht: string } | null),
  }));

  return (
    <div className="flex flex-col flex-1 min-h-0 overflow-y-auto" style={{ background: "#07080f" }}>
      <Topbar title="Kosmetik" />
      <div className="flex-1 p-5">
        <CosmeticsClient
          items={items}
          categories={(categoriesRaw ?? []) as Category[]}
        />
      </div>
    </div>
  );
}
