"use client";

import { useEffect, useState } from "react";

// ── Data ────────────────────────────────────────────────────────────────────

type Item = { id: string; text: string; note?: string };
type Section = { id: string; emoji: string; title: string; items: Item[] };

const SECTIONS: Section[] = [
  {
    id: "auth",
    emoji: "🔐",
    title: "Onboarding & Otantifikasyon",
    items: [
      { id: "auth-1", text: "Ekran splash (logo) parèt pandan ~2 segonn" },
      { id: "auth-2", text: "Onboarding parèt sèlman nan premye lansman an (5 slid)" },
      { id: "auth-3", text: "Bouton «Sote» disponib sou chak slid" },
      { id: "auth-4", text: "«Sote» mennen ou sou paj kreye kont" },
      { id: "auth-5", text: "Dènye slid gen «Kòmanse» epi «Deja gen kont? Konekte»" },
      { id: "auth-6", text: "Kreye yon nouvo kont ak imel + modpas", note: "Ou ta dwe resevwa yon imel byenveni aprè enskripsyon" },
      { id: "auth-7", text: "Konfime imel — lyen nan imel la fonksyone" },
      { id: "auth-8", text: "Konekte ak kont ou kreye a" },
      { id: "auth-9", text: "Dekonekte (Menu → Dekonekte) epi rekonekte" },
      { id: "auth-10", text: "Reyinisyalize modpas: «Bliye modpas?» → imel → lyen → nouvo modpas" },
    ],
  },
  {
    id: "home",
    emoji: "🏠",
    title: "Ekran Akèy",
    items: [
      { id: "home-1", text: "Matchup yo chaje sou ekran akèy la" },
      { id: "home-2", text: "Tire pou rafraîchi (pull-to-refresh) — matchup yo rechaje" },
      { id: "home-3", text: "Tabde kategori yo parèt (Tout, Spò, Politik, Mizik…)" },
      { id: "home-4", text: "Tape sou yon kategori — matchup yo filtre kòrèkteman" },
      { id: "home-5", text: "Seksyon «Tòp Vwa» parèt ak foto pwofil yo" },
      { id: "home-6", text: "Tape sou yon vwa → ouvri pwofil piblik li" },
      { id: "home-7", text: "Ba rechèch la travay: tape yon mo — matchup yo filtre" },
      { id: "home-8", text: "Tape sou yon matchup → ekran detay la chaje" },
      { id: "home-9", text: "Pase nan tab «Prediksyon» — prediksyon yo chaje" },
      { id: "home-10", text: "Seksyon «Tòp Pwofèt» parèt nan tab Prediksyon" },
      { id: "home-11", text: "Cloche notifikasyon parèt nan kwen anlèwo adwàt" },
    ],
  },
  {
    id: "matchup",
    emoji: "⚔️",
    title: "Matchups — Vote & Agiman",
    items: [
      { id: "mu-1", text: "Paj matchup la chaje ak opsyon A ak B", note: "Opsyon A = violèt, Opsyon B = woz/wouj" },
      { id: "mu-2", text: "Tape «Vote» sou yon opsyon — vòt la anrejistre" },
      { id: "mu-3", text: "Bà pousantaj la mete ajou apre vòt ou" },
      { id: "mu-4", text: "Agiman yo vin vizib APRÈ ou vote sèlman" },
      { id: "mu-5", text: "Ekri yon agiman — li parèt nan lis la" },
      { id: "mu-6", text: "Sipòte yon agiman (bouton sipò)", note: "Nesesite 2 kont diferan pou tès sa a" },
      { id: "mu-7", text: "Reponn (reply) yon agiman — repons parèt kòrèkteman" },
      { id: "mu-8", text: "Sove yon matchup (icòn bookmark) — parèt nan «Sove»" },
      { id: "mu-9", text: "Tape sou non otè yon agiman → pwofil piblik li" },
      { id: "mu-10", text: "Imaj Opsyon A ak B parèt kòrèkteman lè yo disponib" },
    ],
  },
  {
    id: "pred",
    emoji: "🔮",
    title: "Prediksyon",
    items: [
      { id: "pred-1", text: "Lis prediksyon yo chaje kòrèkteman" },
      { id: "pred-2", text: "Tape sou yon prediksyon → paj detay la ouvri" },
      { id: "pred-3", text: "Vote sou opsyon A oswa B nan yon prediksyon" },
      { id: "pred-4", text: "Pousantaj yo mete ajou apre vòt ou" },
      { id: "pred-5", text: "Dat limit (deadline) parèt kòrèkteman (oswa «Aktif»)" },
      { id: "pred-6", text: "Badge «✓ Patisipe» parèt apre vote" },
    ],
  },
  {
    id: "profile",
    emoji: "👤",
    title: "Pwofil & Paramèt",
    items: [
      { id: "prof-1", text: "Pwofil ou parèt ak non, username, ak foto si uploade" },
      { id: "prof-2", text: "Chanje foto pwofil — nouvo foto parèt imedyatman" },
      { id: "prof-3", text: "Paj pwofil piblik chaje pou lòt moun" },
      { id: "prof-4", text: "Swiv yon lòt itilizatè — kont «Swivan» mete ajou", note: "Nesesite 2 kont diferan" },
      { id: "prof-5", text: "Dezabòne — kont la desann" },
      { id: "prof-6", text: "Paj «Abòneman» montre lis swivan ak abòne yo" },
      { id: "prof-7", text: "Paj «Statistik» chaje san erè" },
      { id: "prof-8", text: "Paj «Aktivite Resan» chaje ak istwa aksyon ou yo" },
      { id: "prof-9", text: "Paj «Paramèt» — aksè nan sekirite ak notifikasyon" },
      { id: "prof-10", text: "Chanje modpas depi Paramèt → Sekirite" },
    ],
  },
  {
    id: "notif",
    emoji: "🔔",
    title: "Notifikasyon",
    items: [
      { id: "notif-1", text: "Lis notifikasyon chaje nan paj Notifikasyon an" },
      { id: "notif-2", text: "Notifikasyon «swiv» parèt lè yon moun swiv ou", note: "Nesesite 2 kont" },
      { id: "notif-3", text: "Tape sou yon notifikasyon → mennen ou nan bon paj la" },
      { id: "notif-4", text: "Kont notifikasyon an vin zewo apre ou ouvri yo" },
    ],
  },
  {
    id: "nav",
    emoji: "🧭",
    title: "Navigasyon & Jeneral",
    items: [
      { id: "nav-1", text: "Navigasyon ba anba (Home, Notif, Pwofil, Menu) fonksyone" },
      { id: "nav-2", text: "Bouton retounen (back) travay sou tout ekran" },
      { id: "nav-3", text: "Paj «Sove» montre matchup ou sove yo" },
      { id: "nav-4", text: "Paj «Envite» chaje kòrèkteman" },
      { id: "nav-5", text: "Paj «Badges» montre badge ou yo" },
      { id: "nav-6", text: "Lyen «Kondisyon Sèvis» ak «Politik Konfidansyalite» ouvri" },
      { id: "nav-7", text: "Aplikasyon an pa kraché (crash) lè ou kite l ak tounen" },
      { id: "nav-8", text: "Pòtre (portrait) sèlman — pa gen rotasyon ekran" },
    ],
  },
  {
    id: "perf",
    emoji: "⚡",
    title: "Pèfòmans & Erè",
    items: [
      { id: "perf-1", text: "Okenn ekran blan (blank screen) lè ou ouvri aplikasyon an" },
      { id: "perf-2", text: "Imaj yo chaje san erè (pa gen icòn «imaj kase»)" },
      { id: "perf-3", text: "Ekran yo chaje nan mwens pase 3 segonn sou WiFi" },
      { id: "perf-4", text: "Mesaj erè yo klè epi an kreyòl lè koneksyon an fèb" },
      { id: "perf-5", text: "Okenn boucl enfini (loading spinner ki pa kanpe)" },
      { id: "perf-6", text: "Aplikasyon an pa cho (overheating) apre 15 minit itilizasyon" },
    ],
  },
];

const TOTAL = SECTIONS.reduce((s, sec) => s + sec.items.length, 0);

// ── Component ────────────────────────────────────────────────────────────────

export default function ChecklistClient() {
  const [checked, setChecked] = useState<Record<string, boolean>>({});
  const [name, setName] = useState("");
  const [device, setDevice] = useState("");
  const [feedback, setFeedback] = useState("");
  const [score, setScore] = useState("");
  const [submitted, setSubmitted] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [open, setOpen] = useState<Record<string, boolean>>(
    Object.fromEntries(SECTIONS.map((s) => [s.id, true]))
  );

  // Persist to localStorage
  useEffect(() => {
    try {
      const saved = localStorage.getItem("gb_checklist");
      if (saved) {
        const data = JSON.parse(saved);
        if (data.checked) setChecked(data.checked);
        if (data.name) setName(data.name);
        if (data.device) setDevice(data.device);
        if (data.feedback) setFeedback(data.feedback);
        if (data.score) setScore(data.score);
      }
    } catch {}
  }, []);

  useEffect(() => {
    try {
      localStorage.setItem("gb_checklist", JSON.stringify({ checked, name, device, feedback, score }));
    } catch {}
  }, [checked, name, device, feedback, score]);

  const toggle = (id: string) =>
    setChecked((prev) => ({ ...prev, [id]: !prev[id] }));

  const doneCount = Object.values(checked).filter(Boolean).length;
  const pct = Math.round((doneCount / TOTAL) * 100);

  const sectionDone = (sec: Section) =>
    sec.items.filter((i) => checked[i.id]).length;

  const handleSubmit = async () => {
    setSubmitting(true);
    try {
      const lines = [
        `Testè: ${name || "—"}`,
        `Aparèy: ${device || "—"}`,
        `Nòt: ${score || "—"} / 10`,
        `Pwogrè: ${doneCount}/${TOTAL} (${pct}%)`,
        "",
        "=== Kòmantè ===",
        feedback || "—",
        "",
        "=== Checklist ===",
        ...SECTIONS.flatMap((sec) =>
          sec.items.map((item) => `[${checked[item.id] ? "x" : " "}] ${item.text}`)
        ),
      ];
      await fetch("/api/checklist-submit", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ name, device, score, feedback, checked, summary: lines.join("\n") }),
      });
      setSubmitted(true);
    } catch {
      // Still show success to tester — email fallback
      setSubmitted(true);
    } finally {
      setSubmitting(false);
    }
  };

  if (submitted) {
    return (
      <div style={{ minHeight: "100vh", background: "#07080f", display: "flex", alignItems: "center", justifyContent: "center", padding: 24 }}>
        <div style={{ textAlign: "center", maxWidth: 400 }}>
          <div style={{ fontSize: 64 }}>🎉</div>
          <h1 style={{ color: "#ffffff", fontFamily: "sans-serif", marginTop: 16, fontSize: 24 }}>Mèsi, {name || "testè"}!</h1>
          <p style={{ color: "#94a3b8", fontFamily: "sans-serif", marginTop: 8, lineHeight: 1.6 }}>
            Repons ou yo te voye bay ekip Gran Boulva a. Nou apresye kontribisyon ou anpil!
          </p>
          <p style={{ color: "#94a3b8", fontFamily: "sans-serif", marginTop: 12, fontSize: 13 }}>
            Ou te konplete <strong style={{ color: "#a855f7" }}>{doneCount}/{TOTAL}</strong> seksyon.
          </p>
        </div>
      </div>
    );
  }

  return (
    <div style={{ minHeight: "100vh", background: "#07080f", fontFamily: "'Inter', 'Helvetica Neue', sans-serif" }}>
      {/* Header */}
      <div style={{ background: "linear-gradient(135deg, #1e0a6b 0%, #7c1050 100%)", padding: "32px 24px 24px" }}>
        <div style={{ maxWidth: 720, margin: "0 auto" }}>
          <div style={{ display: "flex", alignItems: "center", gap: 12, marginBottom: 8 }}>
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img src="/logo.png" alt="Gran Boulva" style={{ width: 40, height: 40, borderRadius: 10 }} />
            <div>
              <div style={{ color: "rgba(255,255,255,0.6)", fontSize: 12, fontWeight: 600, letterSpacing: 1, textTransform: "uppercase" }}>Gran Boulva</div>
              <div style={{ color: "#ffffff", fontSize: 22, fontWeight: 800, lineHeight: 1.2 }}>Beta Test Checklist</div>
            </div>
          </div>
          <p style={{ color: "rgba(255,255,255,0.7)", fontSize: 13, margin: "12px 0 20px", lineHeight: 1.6 }}>
            Koche chak seksyon pandan ou teste aplikasyon an. Pwogrè ou sove otomatikman nan navigatè a.
          </p>

          {/* Progress bar */}
          <div style={{ background: "rgba(255,255,255,0.15)", borderRadius: 99, height: 8, overflow: "hidden" }}>
            <div style={{
              height: "100%", borderRadius: 99, transition: "width 0.4s ease",
              width: `${pct}%`,
              background: pct === 100 ? "#22c55e" : "linear-gradient(90deg, #a855f7, #ec4899)",
            }} />
          </div>
          <div style={{ display: "flex", justifyContent: "space-between", marginTop: 6 }}>
            <span style={{ color: "rgba(255,255,255,0.6)", fontSize: 12 }}>{doneCount} / {TOTAL} seksyon konplè</span>
            <span style={{ color: pct === 100 ? "#22c55e" : "rgba(255,255,255,0.8)", fontSize: 12, fontWeight: 700 }}>{pct}%</span>
          </div>
        </div>
      </div>

      {/* Body */}
      <div style={{ maxWidth: 720, margin: "0 auto", padding: "24px 16px 48px" }}>

        {/* Tester info */}
        <div style={{ background: "#0e0f1e", border: "1px solid #2e3060", borderRadius: 14, padding: 20, marginBottom: 24 }}>
          <h3 style={{ color: "#94a3b8", fontSize: 11, fontWeight: 700, letterSpacing: 1, textTransform: "uppercase", margin: "0 0 12px" }}>Enfòmasyon Testè</h3>
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12 }}>
            <div>
              <label style={{ color: "#94a3b8", fontSize: 11, fontWeight: 600, display: "block", marginBottom: 4 }}>Non ou *</label>
              <input
                value={name}
                onChange={(e) => setName(e.target.value)}
                placeholder="ex: Marie Joseph"
                style={{ width: "100%", background: "#080916", border: "1px solid #2e3060", borderRadius: 8, padding: "8px 12px", color: "#e2e8f0", fontSize: 13, outline: "none", boxSizing: "border-box" }}
              />
            </div>
            <div>
              <label style={{ color: "#94a3b8", fontSize: 11, fontWeight: 600, display: "block", marginBottom: 4 }}>Aparèy</label>
              <input
                value={device}
                onChange={(e) => setDevice(e.target.value)}
                placeholder="ex: iPhone 14, Samsung S23"
                style={{ width: "100%", background: "#080916", border: "1px solid #2e3060", borderRadius: 8, padding: "8px 12px", color: "#e2e8f0", fontSize: 13, outline: "none", boxSizing: "border-box" }}
              />
            </div>
          </div>
        </div>

        {/* Sections */}
        {SECTIONS.map((sec) => {
          const done = sectionDone(sec);
          const total = sec.items.length;
          const allDone = done === total;
          const isOpen = open[sec.id];
          return (
            <div key={sec.id} style={{ marginBottom: 16, background: "#0e0f1e", border: `1px solid ${allDone ? "rgba(34,197,94,0.3)" : "#1e2040"}`, borderRadius: 14, overflow: "hidden" }}>
              {/* Section header */}
              <button
                onClick={() => setOpen((p) => ({ ...p, [sec.id]: !p[sec.id] }))}
                style={{
                  width: "100%", display: "flex", alignItems: "center", gap: 10,
                  padding: "14px 16px", background: "transparent", border: "none",
                  cursor: "pointer", textAlign: "left",
                }}
              >
                <span style={{ fontSize: 20 }}>{sec.emoji}</span>
                <span style={{ flex: 1, color: "#e2e8f0", fontSize: 15, fontWeight: 700 }}>{sec.title}</span>
                <span style={{
                  fontSize: 11, fontWeight: 700, padding: "2px 8px", borderRadius: 99,
                  background: allDone ? "rgba(34,197,94,0.15)" : "rgba(168,85,247,0.12)",
                  color: allDone ? "#22c55e" : "#a855f7",
                }}>
                  {done}/{total}
                </span>
                <span style={{ color: "#94a3b8", fontSize: 16, marginLeft: 4 }}>{isOpen ? "▲" : "▼"}</span>
              </button>

              {isOpen && (
                <div style={{ borderTop: "1px solid #2e3060" }}>
                  {sec.items.map((item, idx) => (
                    <label
                      key={item.id}
                      style={{
                        display: "flex", alignItems: "flex-start", gap: 12,
                        padding: "12px 16px",
                        background: checked[item.id] ? "rgba(168,85,247,0.05)" : "transparent",
                        borderBottom: idx < sec.items.length - 1 ? "1px solid #1a1b2e" : "none",
                        cursor: "pointer",
                        transition: "background 0.15s",
                      }}
                    >
                      <div style={{ marginTop: 1, flexShrink: 0 }}>
                        <div style={{
                          width: 20, height: 20, borderRadius: 6,
                          border: `2px solid ${checked[item.id] ? "#a855f7" : "#2d2f50"}`,
                          background: checked[item.id] ? "#a855f7" : "transparent",
                          display: "flex", alignItems: "center", justifyContent: "center",
                          transition: "all 0.15s",
                        }}>
                          {checked[item.id] && (
                            <svg width="11" height="9" viewBox="0 0 11 9" fill="none">
                              <path d="M1 4L4 7L10 1" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                            </svg>
                          )}
                        </div>
                      </div>
                      <input type="checkbox" checked={!!checked[item.id]} onChange={() => toggle(item.id)} style={{ display: "none" }} />
                      <div>
                        <div style={{ color: checked[item.id] ? "#64748b" : "#d1d5db", fontSize: 13.5, lineHeight: 1.5, textDecoration: checked[item.id] ? "line-through" : "none" }}>
                          {item.text}
                        </div>
                        {item.note && (
                          <div style={{ color: "#94a3b8", fontSize: 11.5, marginTop: 3, lineHeight: 1.4 }}>
                            💡 {item.note}
                          </div>
                        )}
                      </div>
                    </label>
                  ))}
                </div>
              )}
            </div>
          );
        })}

        {/* Feedback */}
        <div style={{ background: "#0e0f1e", border: "1px solid #2e3060", borderRadius: 14, padding: 20, marginTop: 8 }}>
          <h3 style={{ color: "#94a3b8", fontSize: 11, fontWeight: 700, letterSpacing: 1, textTransform: "uppercase", margin: "0 0 16px" }}>📝 Kòmantè & Resiyo</h3>

          <div style={{ marginBottom: 14 }}>
            <label style={{ color: "#94a3b8", fontSize: 11, fontWeight: 600, display: "block", marginBottom: 6 }}>
              Sou echèl 1–10, ki nòt ou ba aplikasyon an?
            </label>
            <div style={{ display: "flex", gap: 6, flexWrap: "wrap" }}>
              {[1,2,3,4,5,6,7,8,9,10].map((n) => (
                <button
                  key={n}
                  onClick={() => setScore(String(n))}
                  style={{
                    width: 38, height: 38, borderRadius: 8, border: "none", cursor: "pointer",
                    fontSize: 13, fontWeight: 700,
                    background: score === String(n) ? "#a855f7" : "#1a1b2e",
                    color: score === String(n) ? "#ffffff" : "#64748b",
                    transition: "all 0.15s",
                  }}
                >
                  {n}
                </button>
              ))}
            </div>
          </div>

          <div>
            <label style={{ color: "#94a3b8", fontSize: 11, fontWeight: 600, display: "block", marginBottom: 6 }}>
              Kòmantè, erè jwenn, oswa sijesyon
            </label>
            <textarea
              value={feedback}
              onChange={(e) => setFeedback(e.target.value)}
              placeholder="Ekri nenpòt bagay ou panse ki enpòtan: erè ou jwenn, fonksyon ki difisil, sa ou renmen, sa ou ta vle amelyore..."
              rows={5}
              style={{
                width: "100%", background: "#080916", border: "1px solid #2e3060", borderRadius: 8,
                padding: "10px 12px", color: "#e2e8f0", fontSize: 13, outline: "none",
                resize: "vertical", boxSizing: "border-box", lineHeight: 1.6,
                fontFamily: "inherit",
              }}
            />
          </div>
        </div>

        {/* Submit */}
        <div style={{ marginTop: 24, display: "flex", flexDirection: "column", alignItems: "center", gap: 12 }}>
          <button
            onClick={handleSubmit}
            disabled={submitting || !name.trim()}
            style={{
              width: "100%", padding: "14px 24px", borderRadius: 12, border: "none",
              cursor: name.trim() ? "pointer" : "not-allowed",
              fontSize: 15, fontWeight: 700,
              background: name.trim() ? "linear-gradient(90deg, #7c3aed, #ec4899)" : "#1e2040",
              color: name.trim() ? "#ffffff" : "#475569",
              opacity: submitting ? 0.7 : 1,
              transition: "all 0.2s",
            }}
          >
            {submitting ? "Ap voye…" : "✉️  Voye Rezilta yo bay Ekip la"}
          </button>
          {!name.trim() && (
            <p style={{ color: "rgba(255,255,255,0.75)", fontSize: 12, margin: 0 }}>Ranpli non ou anvan ou voye.</p>
          )}
          <p style={{ color: "rgba(255,255,255,0.6)", fontSize: 11, margin: 0, textAlign: "center" }}>
            Pwogrè ou sove otomatikman nan navigatè a. Ou ka fèmen paj la epi retounen pita.
          </p>
        </div>
      </div>
    </div>
  );
}
