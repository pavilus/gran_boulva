"use client";

import { useState, useRef } from "react";
import { Pencil, Check, X, ChevronDown, ChevronRight, Upload } from "lucide-react";
import { createClient } from "@/lib/supabase/client";

type BadgeLevel = {
  id: string;
  badge_id: string;
  level: number;
  required_xp: number;
  title_ht: string;
  title_en: string;
  influence_reward: number;
};

type Badge = {
  id: string;
  key: string;
  name_ht: string;
  name_en: string;
  description_ht: string;
  description_en: string;
  icon_asset: string;
  color_hex: string;
  sort_order: number;
  is_active: boolean;
  levels: BadgeLevel[];
  user_count: number;
};

async function callApi(body: object) {
  const res = await fetch("/api/badges/action", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  return res.json();
}

const inputStyle = {
  background: "#0a0b18",
  border: "1px solid #1e2040",
  color: "#D4D4D4",
  borderRadius: 8,
  padding: "4px 10px",
  fontSize: 13,
  outline: "none",
  width: "100%",
};

function BadgeRow({ badge: initial }: { badge: Badge }) {
  const [badge, setBadge] = useState(initial);
  const [editing, setEditing] = useState(false);
  const [editingLevelId, setEditingLevelId] = useState<string | null>(null);
  const [expanded, setExpanded] = useState(false);
  const [form, setForm] = useState(initial);
  const [levelForm, setLevelForm] = useState<BadgeLevel | null>(null);
  const [saving, setSaving] = useState(false);
  const [uploading, setUploading] = useState(false);
  const fileRef = useRef<HTMLInputElement>(null);

  const uploadIcon = async (file: File) => {
    setUploading(true);
    try {
      const supabase = createClient();
      const ext = file.name.split(".").pop();
      const path = `${badge.key}-${Date.now()}.${ext}`;
      const { error: upErr } = await supabase.storage
        .from("badge-icons")
        .upload(path, file, { upsert: true });
      if (upErr) throw upErr;
      const { data: { publicUrl } } = supabase.storage
        .from("badge-icons")
        .getPublicUrl(path);
      await callApi({ action: "update_badge", id: badge.id, icon_asset: publicUrl });
      setBadge((b) => ({ ...b, icon_asset: publicUrl }));
      setForm((f) => ({ ...f, icon_asset: publicUrl }));
    } catch (e) {
      alert("Upload échoué: " + (e instanceof Error ? e.message : e));
    } finally {
      setUploading(false);
    }
  };

  const setF = (k: keyof Badge) => (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) =>
    setForm((f) => ({ ...f, [k]: e.target.value }));

  const saveBadge = async () => {
    setSaving(true);
    await callApi({
      action: "update_badge",
      id: badge.id,
      name_ht: form.name_ht,
      name_en: form.name_en,
      description_ht: form.description_ht,
      description_en: form.description_en,
      color_hex: form.color_hex,
      is_active: form.is_active,
    });
    setBadge((b) => ({ ...b, ...form }));
    setEditing(false);
    setSaving(false);
  };

  const saveLevel = async () => {
    if (!levelForm) return;
    setSaving(true);
    await callApi({
      action: "update_level",
      id: levelForm.id,
      required_xp: Number(levelForm.required_xp),
      title_ht: levelForm.title_ht,
      title_en: levelForm.title_en,
      influence_reward: Number(levelForm.influence_reward),
    });
    setBadge((b) => ({
      ...b,
      levels: b.levels.map((l) => (l.id === levelForm.id ? levelForm : l)),
    }));
    setEditingLevelId(null);
    setLevelForm(null);
    setSaving(false);
  };

  const color = badge.color_hex || "#a855f7";

  return (
    <div
      style={{
        background: "#0e0f1e",
        border: `1px solid ${editing ? color + "55" : "#1e2040"}`,
        borderRadius: 16,
        marginBottom: 14,
        overflow: "hidden",
        transition: "border-color 0.2s",
      }}
    >
      {/* ── Badge header ── */}
      <div className="flex items-start gap-4 p-5">
        {/* Icon — click to upload */}
        <div
          onClick={() => fileRef.current?.click()}
          title="Klike pou chanje icon"
          style={{
            width: 58,
            height: 58,
            borderRadius: 14,
            background: color + "22",
            border: `2px solid ${color}44`,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            flexShrink: 0,
            cursor: "pointer",
            overflow: "hidden",
            position: "relative",
          }}
        >
          {badge.icon_asset?.startsWith("http") ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img src={badge.icon_asset} alt={badge.name_ht} style={{ width: "100%", height: "100%", objectFit: "cover" }} />
          ) : (
            <span style={{ fontSize: 24 }}>🏅</span>
          )}
          {/* Upload overlay */}
          <div style={{
            position: "absolute", inset: 0, background: "rgba(0,0,0,0.55)",
            display: "flex", alignItems: "center", justifyContent: "center",
            opacity: uploading ? 1 : 0, transition: "opacity 0.15s",
          }}
            onMouseEnter={(e) => { if (!uploading) e.currentTarget.style.opacity = "1"; }}
            onMouseLeave={(e) => { if (!uploading) e.currentTarget.style.opacity = "0"; }}
          >
            {uploading
              ? <span style={{ color: "#fff", fontSize: 11 }}>…</span>
              : <Upload size={16} color="#fff" />}
          </div>
          <input
            ref={fileRef}
            type="file"
            accept="image/*"
            style={{ display: "none" }}
            onChange={(e) => { const f = e.target.files?.[0]; if (f) uploadIcon(f); }}
          />
        </div>

        {/* Info */}
        <div className="flex-1 min-w-0">
          {editing ? (
            <div className="flex flex-col gap-2">
              <div className="grid grid-cols-2 gap-2">
                <div>
                  <label style={{ color: "#64748b", fontSize: 11, marginBottom: 3, display: "block" }}>Non (HT)</label>
                  <input value={form.name_ht} onChange={setF("name_ht")} style={inputStyle} />
                </div>
                <div>
                  <label style={{ color: "#64748b", fontSize: 11, marginBottom: 3, display: "block" }}>Name (EN)</label>
                  <input value={form.name_en} onChange={setF("name_en")} style={inputStyle} />
                </div>
              </div>
              <div className="grid grid-cols-2 gap-2">
                <div>
                  <label style={{ color: "#64748b", fontSize: 11, marginBottom: 3, display: "block" }}>Deskripsyon (HT)</label>
                  <input value={form.description_ht} onChange={setF("description_ht")} style={inputStyle} />
                </div>
                <div>
                  <label style={{ color: "#64748b", fontSize: 11, marginBottom: 3, display: "block" }}>Description (EN)</label>
                  <input value={form.description_en} onChange={setF("description_en")} style={inputStyle} />
                </div>
              </div>
              <div className="flex items-center gap-3">
                <div>
                  <label style={{ color: "#64748b", fontSize: 11, marginBottom: 3, display: "block" }}>Koulè</label>
                  <div className="flex items-center gap-2">
                    <input type="color" value={form.color_hex} onChange={setF("color_hex")}
                      style={{ width: 36, height: 28, border: "none", background: "none", cursor: "pointer", padding: 0 }} />
                    <input value={form.color_hex} onChange={setF("color_hex")}
                      style={{ ...inputStyle, width: 110 }} placeholder="#a855f7" />
                  </div>
                </div>
                <div className="flex items-center gap-2 mt-4">
                  <label style={{ color: "#94a3b8", fontSize: 12 }}>Aktif</label>
                  <input type="checkbox" checked={form.is_active}
                    onChange={(e) => setForm((f) => ({ ...f, is_active: e.target.checked }))}
                    style={{ width: 16, height: 16, cursor: "pointer" }} />
                </div>
              </div>
            </div>
          ) : (
            <>
              <div className="flex items-center gap-2 flex-wrap">
                <span style={{ color: "#fff", fontWeight: 700, fontSize: 15 }}>{badge.name_ht}</span>
                <span style={{ color: "#64748b", fontSize: 13 }}>/ {badge.name_en}</span>
                <span style={{
                  fontSize: 10, fontWeight: 700, padding: "2px 7px", borderRadius: 20,
                  background: badge.is_active ? "rgba(34,197,94,0.12)" : "rgba(100,116,139,0.12)",
                  color: badge.is_active ? "#22c55e" : "#64748b",
                }}>
                  {badge.is_active ? "AKTIF" : "INAKTIF"}
                </span>
              </div>
              <p style={{ color: "#94a3b8", fontSize: 12, marginTop: 3 }}>{badge.description_ht}</p>
              <div className="flex items-center gap-3 mt-2">
                <span style={{ fontSize: 11, color: "#64748b" }}>
                  Kle: <code style={{ color: "#a855f7" }}>{badge.key}</code>
                </span>
                <span style={{ fontSize: 11, color: "#64748b" }}>
                  {badge.user_count} itilizatè gen badj sa
                </span>
                <span
                  style={{ width: 12, height: 12, borderRadius: "50%", background: color, display: "inline-block", border: "2px solid #1e2040" }}
                />
              </div>
            </>
          )}
        </div>

        {/* Actions */}
        <div className="flex gap-2 shrink-0">
          {editing ? (
            <>
              <button onClick={saveBadge} disabled={saving}
                className="flex items-center gap-1 px-3 py-1.5 rounded-lg text-xs font-semibold"
                style={{ background: "rgba(34,197,94,0.12)", color: "#22c55e" }}>
                <Check size={13} /> {saving ? "…" : "Sove"}
              </button>
              <button onClick={() => { setEditing(false); setForm(badge); }}
                className="flex items-center gap-1 px-3 py-1.5 rounded-lg text-xs font-semibold"
                style={{ background: "rgba(239,68,68,0.08)", color: "#ef4444" }}>
                <X size={13} /> Anile
              </button>
            </>
          ) : (
            <>
              <button onClick={() => setEditing(true)}
                className="flex items-center gap-1 px-3 py-1.5 rounded-lg text-xs font-semibold"
                style={{ background: "rgba(168,85,247,0.1)", color: "#a855f7", border: "1px solid rgba(168,85,247,0.2)" }}>
                <Pencil size={12} /> Edite
              </button>
              <button onClick={() => setExpanded((e) => !e)}
                className="flex items-center gap-1 px-3 py-1.5 rounded-lg text-xs font-semibold"
                style={{ background: "#12131f", color: "#94a3b8", border: "1px solid #1e2040" }}>
                {expanded ? <ChevronDown size={13} /> : <ChevronRight size={13} />}
                {badge.levels.length} nivo
              </button>
            </>
          )}
        </div>
      </div>

      {/* ── Levels ── */}
      {expanded && (
        <div style={{ borderTop: "1px solid #1e2040", padding: "12px 20px 16px" }}>
          <p style={{ color: "#64748b", fontSize: 11, fontWeight: 600, marginBottom: 10, textTransform: "uppercase", letterSpacing: "0.05em" }}>
            Nivo ak sèy XP
          </p>
          <table style={{ width: "100%", borderCollapse: "collapse" }}>
            <thead>
              <tr style={{ color: "#475569", fontSize: 11 }}>
                <th className="text-left pb-2 pr-3">Nivo</th>
                <th className="text-left pb-2 pr-3">XP requis</th>
                <th className="text-left pb-2 pr-3">Tit (HT)</th>
                <th className="text-left pb-2 pr-3">Title (EN)</th>
                <th className="text-left pb-2 pr-3">Enfliyans</th>
                <th className="pb-2" />
              </tr>
            </thead>
            <tbody>
              {badge.levels.map((lvl) => {
                const isEditingLevel = editingLevelId === lvl.id;
                const lf = isEditingLevel ? levelForm! : lvl;
                const cellStyle = { padding: "5px 12px 5px 0", borderBottom: "1px solid #1a1b2e", color: "#D4D4D4", fontSize: 13 };
                return (
                  <tr key={lvl.id}>
                    <td style={{ ...cellStyle, fontWeight: 700, color: color }}>
                      {lvl.level}
                    </td>
                    {isEditingLevel ? (
                      <>
                        <td style={cellStyle}>
                          <input type="number" value={lf.required_xp}
                            onChange={(e) => setLevelForm((f) => f && ({ ...f, required_xp: Number(e.target.value) }))}
                            style={{ ...inputStyle, width: 80 }} />
                        </td>
                        <td style={cellStyle}>
                          <input value={lf.title_ht}
                            onChange={(e) => setLevelForm((f) => f && ({ ...f, title_ht: e.target.value }))}
                            style={inputStyle} />
                        </td>
                        <td style={cellStyle}>
                          <input value={lf.title_en}
                            onChange={(e) => setLevelForm((f) => f && ({ ...f, title_en: e.target.value }))}
                            style={inputStyle} />
                        </td>
                        <td style={cellStyle}>
                          <input type="number" value={lf.influence_reward}
                            onChange={(e) => setLevelForm((f) => f && ({ ...f, influence_reward: Number(e.target.value) }))}
                            style={{ ...inputStyle, width: 70 }} />
                        </td>
                        <td style={cellStyle}>
                          <div className="flex gap-1">
                            <button onClick={saveLevel} disabled={saving}
                              className="p-1 rounded" style={{ color: "#22c55e", background: "rgba(34,197,94,0.1)" }}>
                              <Check size={13} />
                            </button>
                            <button onClick={() => { setEditingLevelId(null); setLevelForm(null); }}
                              className="p-1 rounded" style={{ color: "#ef4444", background: "rgba(239,68,68,0.08)" }}>
                              <X size={13} />
                            </button>
                          </div>
                        </td>
                      </>
                    ) : (
                      <>
                        <td style={cellStyle}>{lvl.required_xp.toLocaleString()} XP</td>
                        <td style={{ ...cellStyle, color: "#94a3b8" }}>{lvl.title_ht || "—"}</td>
                        <td style={{ ...cellStyle, color: "#94a3b8" }}>{lvl.title_en || "—"}</td>
                        <td style={{ ...cellStyle, color: "#22c55e" }}>+{lvl.influence_reward}</td>
                        <td style={cellStyle}>
                          <button onClick={() => { setEditingLevelId(lvl.id); setLevelForm({ ...lvl }); }}
                            className="p-1 rounded" style={{ color: "#a855f7", background: "rgba(168,85,247,0.08)" }}>
                            <Pencil size={12} />
                          </button>
                        </td>
                      </>
                    )}
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}

export default function BadgesClient({ badges }: { badges: Badge[] }) {
  return (
    <div>
      <div className="flex items-center justify-between mb-5">
        <p style={{ color: "#64748b", fontSize: 13 }}>
          {badges.length} badj • Klike sou &ldquo;Edite&rdquo; pou chanje non, deskripsyon oswa koulè. Klike sou &ldquo;nivo&rdquo; pou wè ak edite sèy XP.
        </p>
      </div>
      {badges.map((b) => (
        <BadgeRow key={b.id} badge={b} />
      ))}
    </div>
  );
}
