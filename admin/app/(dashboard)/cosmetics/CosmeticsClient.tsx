"use client";

import { useState } from "react";
import { Plus, ToggleLeft, ToggleRight } from "lucide-react";

export type Category = {
  id: string;
  key: string;
  name_ht: string;
  name_en: string;
  sort_order: number;
};

export type CosmeticItem = {
  id: string;
  key: string;
  name_ht: string;
  name_en: string;
  description_ht: string | null;
  price_coins: number;
  rarity: "common" | "rare" | "epic" | "legendary" | "founder";
  is_active: boolean;
  created_at: string;
  category_id: string;
  cosmetic_categories: { key: string; name_ht: string } | null;
};

const RARITY_COLORS: Record<string, string> = {
  common: "#94A3B8",
  rare: "#60A5FA",
  epic: "#A855F7",
  legendary: "#FBBF24",
  founder: "#EC4899",
};

const RARITY_LABELS: Record<string, string> = {
  common: "Kouran",
  rare: "Rare",
  epic: "Epik",
  legendary: "Lejandè",
  founder: "Fondate",
};

type Props = {
  items: CosmeticItem[];
  categories: Category[];
};

export default function CosmeticsClient({ items: initialItems, categories }: Props) {
  const [items, setItems] = useState<CosmeticItem[]>(initialItems);
  const [selectedCategory, setSelectedCategory] = useState("all");
  const [showCreate, setShowCreate] = useState(false);
  const [creating, setCreating] = useState(false);
  const [toggling, setToggling] = useState<string | null>(null);

  // Create form state
  const [form, setForm] = useState({
    name_ht: "",
    name_en: "",
    description_ht: "",
    price_coins: 0,
    rarity: "common" as CosmeticItem["rarity"],
    category_id: categories[0]?.id ?? "",
    is_active: true,
  });

  const filteredItems =
    selectedCategory === "all"
      ? items
      : items.filter((i) => i.cosmetic_categories?.key === selectedCategory);

  async function handleCreate() {
    setCreating(true);
    try {
      const res = await fetch("/api/cosmetics/action", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ action: "create", ...form }),
      });
      const json = await res.json();
      if (!res.ok) throw new Error(json.error ?? "Erè");
      // Optimistically add the new item to state
      setItems((prev) => [json.item, ...prev]);
      setShowCreate(false);
      setForm({
        name_ht: "",
        name_en: "",
        description_ht: "",
        price_coins: 0,
        rarity: "common",
        category_id: categories[0]?.id ?? "",
        is_active: true,
      });
    } catch (err) {
      alert(err instanceof Error ? err.message : "Erè enkoni");
    } finally {
      setCreating(false);
    }
  }

  async function handleToggle(item: CosmeticItem) {
    setToggling(item.id);
    try {
      const res = await fetch("/api/cosmetics/action", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ action: "toggle", id: item.id, is_active: !item.is_active }),
      });
      if (!res.ok) throw new Error("Erè");
      setItems((prev) =>
        prev.map((i) => (i.id === item.id ? { ...i, is_active: !i.is_active } : i))
      );
    } catch (err) {
      alert(err instanceof Error ? err.message : "Erè enkoni");
    } finally {
      setToggling(null);
    }
  }

  return (
    <div>
      {/* Header */}
      <div className="flex items-center justify-between mb-5">
        <div>
          <h2 className="text-white font-bold text-xl" style={{ fontFamily: "Poppins, sans-serif" }}>
            Kosmetik
          </h2>
          <p style={{ color: "#94a3b8", fontSize: 13 }}>{items.length} item total</p>
        </div>
        <button
          onClick={() => setShowCreate(true)}
          className="flex items-center gap-2 px-4 py-2 rounded-xl text-sm font-semibold transition-colors"
          style={{ background: "#7c3aed", color: "#fff" }}
        >
          <Plus size={15} />
          Kreye Item
        </button>
      </div>

      {/* Category filter tabs */}
      <div className="flex gap-2 flex-wrap mb-5">
        {[{ key: "all", name_ht: "Tout" }, ...categories].map((cat) => {
          const active = selectedCategory === cat.key;
          return (
            <button
              key={cat.key}
              onClick={() => setSelectedCategory(cat.key)}
              className="px-3 py-1.5 rounded-full text-xs font-medium transition-all"
              style={{
                background: active ? "#7c3aed" : "#10122a",
                color: active ? "#fff" : "#64748b",
                border: `1px solid ${active ? "#7c3aed" : "#1e2040"}`,
              }}
            >
              {cat.name_ht}
            </button>
          );
        })}
      </div>

      {/* Table */}
      <div
        className="rounded-2xl overflow-hidden"
        style={{ border: "1px solid #2e3060", background: "#0a0b18" }}
      >
        <table className="w-full text-sm">
          <thead>
            <tr style={{ borderBottom: "1px solid #2e3060" }}>
              {["Non (HT)", "Kategori", "Pri (Monè)", "Rarète", "Aktif"].map((h) => (
                <th
                  key={h}
                  className="px-4 py-3 text-left text-xs font-semibold"
                  style={{ color: "#94a3b8" }}
                >
                  {h}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {filteredItems.length === 0 ? (
              <tr>
                <td colSpan={5} className="px-4 py-8 text-center" style={{ color: "#94a3b8" }}>
                  Pa gen item.
                </td>
              </tr>
            ) : (
              filteredItems.map((item, i) => (
                <tr
                  key={item.id}
                  style={{
                    borderBottom: i < filteredItems.length - 1 ? "1px solid #2e3060" : "none",
                    opacity: item.is_active ? 1 : 0.45,
                  }}
                >
                  <td className="px-4 py-3">
                    <div className="text-white font-medium">{item.name_ht}</div>
                    <div style={{ color: "#94a3b8", fontSize: 11 }}>{item.name_en}</div>
                  </td>
                  <td className="px-4 py-3" style={{ color: "#94a3b8" }}>
                    {item.cosmetic_categories?.name_ht ?? "—"}
                  </td>
                  <td className="px-4 py-3">
                    <span style={{ color: "#FBBF24", fontWeight: 700 }}>
                      {item.price_coins === 0 ? "Gratis" : `🪙 ${item.price_coins}`}
                    </span>
                  </td>
                  <td className="px-4 py-3">
                    <span
                      className="px-2 py-0.5 rounded-full text-xs font-bold"
                      style={{
                        color: RARITY_COLORS[item.rarity] ?? "#94a3b8",
                        background: `${RARITY_COLORS[item.rarity] ?? "#94a3b8"}22`,
                        border: `1px solid ${RARITY_COLORS[item.rarity] ?? "#94a3b8"}55`,
                      }}
                    >
                      {RARITY_LABELS[item.rarity] ?? item.rarity}
                    </span>
                  </td>
                  <td className="px-4 py-3">
                    <button
                      onClick={() => handleToggle(item)}
                      disabled={toggling === item.id}
                      className="transition-opacity"
                      style={{ color: item.is_active ? "#22c55e" : "#475569" }}
                      title={item.is_active ? "Dezaktive" : "Aktive"}
                    >
                      {item.is_active ? <ToggleRight size={22} /> : <ToggleLeft size={22} />}
                    </button>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      {/* Create modal */}
      {showCreate && (
        <div
          className="fixed inset-0 flex items-center justify-center z-50"
          style={{ background: "rgba(0,0,0,0.7)" }}
          onClick={(e) => e.target === e.currentTarget && setShowCreate(false)}
        >
          <div
            className="w-full max-w-md rounded-2xl p-6"
            style={{ background: "#0a0b18", border: "1px solid #2e3060" }}
          >
            <h3 className="text-white font-bold text-lg mb-4" style={{ fontFamily: "Poppins" }}>
              Kreye Nouvo Item
            </h3>

            <div className="space-y-3">
              <_Field label="Non (Kreyòl)">
                <input
                  value={form.name_ht}
                  onChange={(e) => setForm((f) => ({ ...f, name_ht: e.target.value }))}
                  placeholder="Neon Viyolèt"
                  style={inputStyle}
                />
              </_Field>

              <_Field label="Non (Angle)">
                <input
                  value={form.name_en}
                  onChange={(e) => setForm((f) => ({ ...f, name_en: e.target.value }))}
                  placeholder="Neon Violet"
                  style={inputStyle}
                />
              </_Field>

              <_Field label="Deskripsyon (Kreyòl)">
                <textarea
                  value={form.description_ht}
                  onChange={(e) => setForm((f) => ({ ...f, description_ht: e.target.value }))}
                  placeholder="Deskripsyon opsyonèl…"
                  rows={2}
                  style={{ ...inputStyle, resize: "vertical" }}
                />
              </_Field>

              <_Field label="Kategori">
                <select
                  value={form.category_id}
                  onChange={(e) => setForm((f) => ({ ...f, category_id: e.target.value }))}
                  style={inputStyle}
                >
                  {categories.map((c) => (
                    <option key={c.id} value={c.id}>
                      {c.name_ht}
                    </option>
                  ))}
                </select>
              </_Field>

              <div className="grid grid-cols-2 gap-3">
                <_Field label="Pri (Monè)">
                  <input
                    type="number"
                    min={0}
                    value={form.price_coins}
                    onChange={(e) =>
                      setForm((f) => ({ ...f, price_coins: parseInt(e.target.value) || 0 }))
                    }
                    style={inputStyle}
                  />
                </_Field>

                <_Field label="Rarète">
                  <select
                    value={form.rarity}
                    onChange={(e) =>
                      setForm((f) => ({ ...f, rarity: e.target.value as CosmeticItem["rarity"] }))
                    }
                    style={inputStyle}
                  >
                    {Object.entries(RARITY_LABELS).map(([val, label]) => (
                      <option key={val} value={val}>
                        {label}
                      </option>
                    ))}
                  </select>
                </_Field>
              </div>

              <label className="flex items-center gap-2 cursor-pointer">
                <input
                  type="checkbox"
                  checked={form.is_active}
                  onChange={(e) => setForm((f) => ({ ...f, is_active: e.target.checked }))}
                  className="rounded"
                />
                <span style={{ color: "#94a3b8", fontSize: 13 }}>Aktif imedyatman</span>
              </label>
            </div>

            <div className="flex gap-3 mt-5">
              <button
                onClick={() => setShowCreate(false)}
                className="flex-1 py-2.5 rounded-xl text-sm font-medium"
                style={{ background: "#10122a", color: "#94a3b8", border: "1px solid #2e3060" }}
              >
                Anile
              </button>
              <button
                onClick={handleCreate}
                disabled={creating || !form.name_ht.trim() || !form.category_id}
                className="flex-1 py-2.5 rounded-xl text-sm font-semibold transition-opacity disabled:opacity-50"
                style={{ background: "#7c3aed", color: "#fff" }}
              >
                {creating ? "Ap kreye…" : "Kreye"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

const inputStyle: React.CSSProperties = {
  width: "100%",
  background: "#10122a",
  border: "1px solid #2e3060",
  borderRadius: 10,
  color: "#e2e8f0",
  padding: "8px 12px",
  fontSize: 13,
  outline: "none",
};

function _Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div>
      <label className="block text-xs font-medium mb-1" style={{ color: "#94a3b8" }}>
        {label}
      </label>
      {children}
    </div>
  );
}
