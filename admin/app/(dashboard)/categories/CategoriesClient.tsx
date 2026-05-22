"use client";

import { useState } from "react";
import { Plus, Pencil, Trash2, Check, X } from "lucide-react";

type Category = { id: string; name_ht: string; name_en: string; icon?: string };

async function callApi(body: object) {
  const res = await fetch("/api/categories/action", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  return res.json();
}

function EditRow({
  cat, onSave, onCancel,
}: {
  cat: Partial<Category>; onSave: (c: Partial<Category>) => void; onCancel: () => void;
}) {
  const [form, setForm] = useState(cat);
  const set = (k: keyof Category) => (e: React.ChangeEvent<HTMLInputElement>) =>
    setForm((f) => ({ ...f, [k]: e.target.value }));
  const inputStyle = { background: "#0a0b18", border: "1px solid #1e2040", color: "#D4D4D4" };

  return (
    <tr style={{ background: "#120d2a", borderBottom: "1px solid #1e2040" }}>
      <td className="px-4 py-2">
        <input value={form.icon ?? ""} onChange={set("icon")} placeholder="🏷️"
          className="w-16 px-2 py-1 rounded-lg text-sm outline-none text-center" style={inputStyle} />
      </td>
      <td className="px-4 py-2">
        <input value={form.name_ht ?? ""} onChange={set("name_ht")} placeholder="Non Kreyòl"
          className="w-full px-2 py-1 rounded-lg text-sm outline-none" style={inputStyle} />
      </td>
      <td className="px-4 py-2">
        <input value={form.name_en ?? ""} onChange={set("name_en")} placeholder="English name"
          className="w-full px-2 py-1 rounded-lg text-sm outline-none" style={inputStyle} />
      </td>
      <td className="px-4 py-2" />
      <td className="px-4 py-2">
        <div className="flex gap-1">
          <button onClick={() => onSave(form)} className="p-1.5 rounded-lg"
            style={{ color: "#22c55e", background: "rgba(34,197,94,0.1)" }}><Check size={14} /></button>
          <button onClick={onCancel} className="p-1.5 rounded-lg"
            style={{ color: "#ef4444", background: "rgba(239,68,68,0.08)" }}><X size={14} /></button>
        </div>
      </td>
    </tr>
  );
}

export default function CategoriesClient({
  categories: initial, countMap,
}: {
  categories: Category[]; countMap: Record<string, number>;
}) {
  const [cats, setCats] = useState(initial);
  const [editing, setEditing] = useState<string | null>(null);
  const [adding, setAdding] = useState(false);
  const [loading, setLoading] = useState(false);
  const [filters, setFilters] = useState({
    icon: "",
    nameHt: "",
    nameEn: "",
    matchups: "",
  });

  const filteredCats = cats.filter((c) => {
    if (filters.icon && !(c.icon ?? "").toLowerCase().includes(filters.icon.toLowerCase())) return false;
    if (filters.nameHt && !c.name_ht.toLowerCase().includes(filters.nameHt.toLowerCase())) return false;
    if (filters.nameEn && !c.name_en.toLowerCase().includes(filters.nameEn.toLowerCase())) return false;
    if (filters.matchups && !String(countMap[c.id] ?? 0).includes(filters.matchups)) return false;
    return true;
  });

  const save = async (form: Partial<Category>, id?: string) => {
    setLoading(true);
    if (id) {
      await callApi({ action: "update", id, ...form });
      setCats((prev) => prev.map((c) => (c.id === id ? { ...c, ...form } as Category : c)));
      setEditing(null);
    } else {
      const res = await callApi({ action: "create", ...form });
      if (res.id) setCats((prev) => [...prev, res as Category]);
      setAdding(false);
    }
    setLoading(false);
  };

  const del = async (id: string, name: string) => {
    if (!confirm(`Efase kategorì "${name}"? Sa pap kapab defèt.`)) return;
    setLoading(true);
    await callApi({ action: "delete", id });
    setCats((prev) => prev.filter((c) => c.id !== id));
    setLoading(false);
  };

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <div style={{ color: "#475569", fontSize: 13 }}>{filteredCats.length} / {cats.length} kategorì</div>
        {!adding && (
          <button
            onClick={() => setAdding(true)}
            className="flex items-center gap-2 px-4 py-2 rounded-lg text-xs font-semibold text-white"
            style={{ background: "linear-gradient(90deg,#7c3aed,#a855f7)" }}
          >
            <Plus size={14} /> Nouvo Kategorì
          </button>
        )}
      </div>

      <div className="rounded-xl overflow-hidden" style={{ border: "1px solid #1e2040" }}>
        <table className="w-full text-sm">
          <thead>
            <tr style={{ background: "#0a0b18", borderBottom: "1px solid #1e2040" }}>
              {["Ikòn", "Non (Kreyòl)", "Non (English)", "Matchup yo", "Aksyon"].map((h) => (
                <th key={h} className="px-4 py-3 text-left text-xs font-semibold uppercase" style={{ color: "#475569" }}>{h}</th>
              ))}
            </tr>
            <tr style={{ background: "#0a0b18", borderBottom: "1px solid #1e2040" }}>
              {[
                ["icon", "Filtre ikòn"],
                ["nameHt", "Filtre Kreyòl"],
                ["nameEn", "Filtre English"],
                ["matchups", "Filtre kantite"],
              ].map(([key, placeholder]) => (
                <th key={key} className="px-4 pb-3">
                  <input value={filters[key as keyof typeof filters]}
                    onChange={(e) => setFilters((prev) => ({ ...prev, [key]: e.target.value }))}
                    placeholder={placeholder}
                    className="w-full px-2 py-1.5 rounded-md text-xs text-white outline-none"
                    style={{ background: "#0e0f1e", border: "1px solid #1e2040" }} />
                </th>
              ))}
              <th className="px-4 pb-3">
                <button onClick={() => setFilters({ icon: "", nameHt: "", nameEn: "", matchups: "" })}
                  className="px-2 py-1.5 rounded-md text-xs font-semibold"
                  style={{ color: "#64748b", border: "1px solid #1e2040" }}>Reset</button>
              </th>
            </tr>
          </thead>
          <tbody>
            {adding && (
              <EditRow cat={{ name_ht: "", name_en: "", icon: "" }}
                onSave={(f) => save(f)}
                onCancel={() => setAdding(false)} />
            )}
            {filteredCats.map((c) =>
              editing === c.id ? (
                <EditRow key={c.id} cat={c}
                  onSave={(f) => save(f, c.id)}
                  onCancel={() => setEditing(null)} />
              ) : (
                <tr key={c.id} style={{ borderBottom: "1px solid #1e2040", background: "#0e0f1e" }}>
                  <td className="px-4 py-3">
                    {c.icon?.endsWith('.png') ? (
                      <img src={c.icon} alt={c.name_ht} className="w-8 h-8 object-contain" />
                    ) : (
                      <span className="text-2xl">{c.icon ?? "🏷️"}</span>
                    )}
                  </td>
                  <td className="px-4 py-3 text-white font-medium">{c.name_ht}</td>
                  <td className="px-4 py-3" style={{ color: "#94a3b8" }}>{c.name_en}</td>
                  <td className="px-4 py-3 font-semibold" style={{ color: "#a78bfa" }}>{countMap[c.id] ?? 0}</td>
                  <td className="px-4 py-3">
                    <div className="flex gap-1">
                      <button onClick={() => setEditing(c.id)} disabled={loading}
                        className="p-1.5 rounded-lg" style={{ color: "#94a3b8", background: "rgba(148,163,184,0.1)" }}>
                        <Pencil size={14} />
                      </button>
                      <button onClick={() => del(c.id, c.name_ht)} disabled={loading}
                        className="p-1.5 rounded-lg" style={{ color: "#ef4444", background: "rgba(239,68,68,0.08)" }}>
                        <Trash2 size={14} />
                      </button>
                    </div>
                  </td>
                </tr>
              )
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
