import { NextResponse } from "next/server";
import { requireAdmin } from "@/lib/auth/admin";
import { createAdminClient } from "@/lib/supabase/admin";

export async function POST(request: Request) {
  const unauthorized = await requireAdmin();
  if (unauthorized) return unauthorized;

  const body = await request.json();
  const { action } = body as { action: string };
  const supabase = createAdminClient();

  if (action === "create") {
    const {
      name_ht,
      name_en,
      description_ht,
      price_coins,
      rarity,
      category_id,
      is_active,
    } = body as {
      name_ht: string;
      name_en: string;
      description_ht: string;
      price_coins: number;
      rarity: string;
      category_id: string;
      is_active: boolean;
    };

    if (!name_ht?.trim()) {
      return NextResponse.json({ error: "name_ht obligatwa" }, { status: 400 });
    }

    // Generate a key from the Haitian name
    const key =
      "item_" +
      name_ht
        .toLowerCase()
        .normalize("NFD")
        .replace(/[̀-ͯ]/g, "")
        .replace(/[^a-z0-9]+/g, "_")
        .replace(/^_+|_+$/g, "") +
      "_" +
      Date.now();

    const { data: item, error } = await supabase
      .from("cosmetic_items")
      .insert({
        key,
        name_ht: name_ht.trim(),
        name_en: (name_en ?? "").trim(),
        description_ht: description_ht?.trim() || null,
        price_coins: Math.max(0, Math.round(Number(price_coins) || 0)),
        rarity: rarity ?? "common",
        category_id,
        is_active: Boolean(is_active),
      })
      .select(
        "id, key, name_ht, name_en, description_ht, price_coins, rarity, is_active, created_at, category_id, cosmetic_categories(key, name_ht)"
      )
      .single();

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 });
    }

    return NextResponse.json({ item });
  }

  if (action === "toggle") {
    const { id, is_active } = body as { id: string; is_active: boolean };

    if (!id) {
      return NextResponse.json({ error: "id obligatwa" }, { status: 400 });
    }

    const { error } = await supabase
      .from("cosmetic_items")
      .update({ is_active: Boolean(is_active) })
      .eq("id", id);

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 });
    }

    return NextResponse.json({ ok: true });
  }

  return NextResponse.json({ error: "Aksyon enkoni" }, { status: 400 });
}
