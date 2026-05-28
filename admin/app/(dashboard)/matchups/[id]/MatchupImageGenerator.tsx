"use client";

import { useRef, useState } from "react";
import { Download, ImagePlus, Loader2, Upload } from "lucide-react";

type Slot = "option_a" | "option_b" | "poster" | "share";

interface ImageState {
  option_a: string;
  option_b: string;
  poster: string;
  share: string;
}

export default function MatchupImageGenerator({
  matchupId,
  initialPoster,
  initialShare,
  initialOptionA,
  initialOptionB,
}: {
  matchupId: string;
  initialPoster?: string | null;
  initialShare?: string | null;
  initialOptionA?: string | null;
  initialOptionB?: string | null;
}) {
  const [images, setImages] = useState<ImageState>({
    option_a: initialOptionA ?? "",
    option_b: initialOptionB ?? "",
    poster: initialPoster ?? "",
    share: initialShare ?? "",
  });
  const [generating, setGenerating] = useState(false);
  const [genStarted, setGenStarted] = useState(false);
  const [uploading, setUploading] = useState<Partial<Record<Slot, boolean>>>({});
  const [genError, setGenError] = useState("");
  const [slotErrors, setSlotErrors] = useState<Partial<Record<Slot, string>>>({});

  // ── AI generation (A + B + composite attempt) ──────────────────────────────
  async function generate() {
    setGenerating(true);
    setGenStarted(false);
    setGenError("");
    try {
      const res = await fetch("/api/matchups/images/generate", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ matchup_id: matchupId }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error ?? "Jenerasyon echwe");
      setGenStarted(true);
    } catch (e) {
      setGenError(e instanceof Error ? e.message : "Jenerasyon echwe");
    } finally {
      setGenerating(false);
    }
  }

  // ── Individual slot upload ─────────────────────────────────────────────────
  async function uploadSlot(slot: Slot, file: File) {
    setUploading((p) => ({ ...p, [slot]: true }));
    setSlotErrors((p) => ({ ...p, [slot]: "" }));
    try {
      const fd = new FormData();
      fd.append("matchup_id", matchupId);
      fd.append("slot", slot);
      fd.append("image", file);
      const res = await fetch("/api/matchups/images/upload", { method: "POST", body: fd });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error ?? "Upload echwe");
      setImages((p) => ({ ...p, [slot]: data.url }));
    } catch (e) {
      setSlotErrors((p) => ({ ...p, [slot]: e instanceof Error ? e.message : "Erè" }));
    } finally {
      setUploading((p) => ({ ...p, [slot]: false }));
    }
  }

  return (
    <section className="rounded-xl p-5" style={{ background: "#0e0f1e", border: "1px solid #1e2040" }}>
      {/* Header */}
      <div className="mb-5 flex flex-wrap items-start justify-between gap-3">
        <div>
          <h2 className="text-sm font-semibold" style={{ color: "#D4D4D4" }}>Imaj Matchup</h2>
          <p className="mt-1 text-xs leading-relaxed" style={{ color: "#64748b" }}>
            IA jenere Opsyon A & B. Upload Poster ak Share manyèlman (Canva, etc.).
          </p>
        </div>
        <button
          onClick={generate}
          disabled={generating}
          className="inline-flex items-center gap-2 rounded-lg px-4 py-2 text-xs font-semibold disabled:opacity-60"
          style={{ color: "#ffffff", background: "linear-gradient(90deg,#7c3aed,#ec4899)" }}
        >
          {generating ? <Loader2 size={14} className="animate-spin" /> : <ImagePlus size={14} />}
          {generating ? "Ap jenere…" : "Jenere ak IA"}
        </button>
      </div>

      {genStarted && (
        <div className="mb-4 flex items-center gap-3 rounded-xl px-4 py-3" style={{ background: "rgba(168,85,247,0.08)", border: "1px solid rgba(168,85,247,0.2)" }}>
          <Loader2 size={14} className="animate-spin shrink-0" style={{ color: "#a855f7" }} />
          <div>
            <div className="text-xs font-semibold" style={{ color: "#a855f7" }}>Imaj ap jenere nan background…</div>
            <div className="text-xs mt-0.5" style={{ color: "#64748b" }}>Rafraîchi paj la nan 2–3 minit pou wè yo.</div>
          </div>
        </div>
      )}

      {genError && (
        <div className="mb-4 rounded-lg px-3 py-2 text-xs" style={{ color: "#fca5a5", background: "rgba(239,68,68,.1)" }}>
          {genError}
        </div>
      )}

      {/* 4 image zones */}
      <div className="grid gap-4" style={{ gridTemplateColumns: "1fr 1fr 1fr 1fr" }}>
        <SlotZone
          slot="option_a" label="Opsyon A" hint="Jenere oswa upload" aspect="4 / 5"
          url={images.option_a} uploading={!!uploading.option_a} error={slotErrors.option_a ?? ""}
          onFile={(f) => uploadSlot("option_a", f)}
        />
        <SlotZone
          slot="option_b" label="Opsyon B" hint="Jenere oswa upload" aspect="4 / 5"
          url={images.option_b} uploading={!!uploading.option_b} error={slotErrors.option_b ?? ""}
          onFile={(f) => uploadSlot("option_b", f)}
        />
        <SlotZone
          slot="poster" label="Poster 4:5" hint="1080 × 1350 px — upload manyèl" aspect="4 / 5"
          url={images.poster} uploading={!!uploading.poster} error={slotErrors.poster ?? ""}
          onFile={(f) => uploadSlot("poster", f)}
        />
        <SlotZone
          slot="share" label="Share OG" hint="1200 × 630 px — upload manyèl" aspect="1200 / 630"
          url={images.share} uploading={!!uploading.share} error={slotErrors.share ?? ""}
          onFile={(f) => uploadSlot("share", f)}
        />
      </div>

      {/* Download links */}
      {(images.option_a || images.option_b || images.poster || images.share) && (
        <div className="mt-4 flex flex-wrap gap-2">
          {(["option_a", "option_b", "poster", "share"] as Slot[]).map((s) =>
            images[s] ? (
              <a
                key={s}
                href={images[s]}
                download
                className="inline-flex items-center gap-1.5 rounded-lg px-3 py-1.5 text-xs font-semibold"
                style={{ color: "#94a3b8", border: "1px solid #1e2040" }}
              >
                <Download size={12} />
                {{ option_a: "Opsyon A", option_b: "Opsyon B", poster: "Poster", share: "Share" }[s]}
              </a>
            ) : null
          )}
          <a href="/matchup-images" className="rounded-lg px-3 py-1.5 text-xs font-semibold"
            style={{ color: "#475569", border: "1px solid #1e2040" }}>
            Louvri galri
          </a>
        </div>
      )}
    </section>
  );
}

// ── Individual slot upload zone ────────────────────────────────────────────────

function SlotZone({
  label, hint, aspect, url, uploading, error, onFile,
}: {
  slot: Slot;
  label: string;
  hint: string;
  aspect: string;
  url: string;
  uploading: boolean;
  error: string;
  onFile: (file: File) => void;
}) {
  const ref = useRef<HTMLInputElement>(null);

  return (
    <div>
      {/* Label + download */}
      <div className="mb-1 flex items-center justify-between">
        <span className="text-xs font-semibold" style={{ color: "#94a3b8" }}>{label}</span>
        {url && (
          <a href={url} download className="text-xs" style={{ color: "#475569" }}>
            <Download size={11} />
          </a>
        )}
      </div>

      {/* Zone */}
      <div
        className="group relative overflow-hidden rounded-xl"
        style={{
          aspectRatio: aspect,
          background: "#080916",
          border: `1px dashed ${error ? "#ef4444" : "#1e2040"}`,
          cursor: "pointer",
        }}
        onClick={() => ref.current?.click()}
      >
        <input
          ref={ref}
          type="file"
          accept="image/png,image/jpeg,image/webp"
          className="sr-only"
          onChange={(e) => {
            const f = e.currentTarget.files?.[0];
            if (f) onFile(f);
            e.currentTarget.value = "";
          }}
        />

        {/* Current image */}
        {url && !uploading && (
          // eslint-disable-next-line @next/next/no-img-element
          <img src={url} alt={label} className="h-full w-full object-cover" />
        )}

        {/* Overlay: spinner while uploading, upload icon on hover or when empty */}
        <div
          className="absolute inset-0 flex flex-col items-center justify-center gap-1.5 transition-opacity"
          style={{ background: url ? "rgba(0,0,0,0.6)" : "transparent", opacity: uploading || !url ? 1 : 0 }}
        >
          <style>{`.group:hover > div { opacity: 1 !important; }`}</style>
          {uploading ? (
            <Loader2 size={20} className="animate-spin" style={{ color: "#a78bfa" }} />
          ) : (
            <>
              <Upload size={15} style={{ color: url ? "#D4D4D4" : "#475569" }} />
              <span className="text-xs" style={{ color: url ? "#D4D4D4" : "#64748b" }}>
                {url ? "Chanje" : "Upload"}
              </span>
              <span style={{ color: "#475569", fontSize: 10 }}>{hint}</span>
            </>
          )}
        </div>
      </div>

      {error && <p className="mt-1 text-xs" style={{ color: "#fca5a5" }}>{error}</p>}
    </div>
  );
}
