"use client";

import { useState } from "react";
import { Download, ImagePlus, Loader2, Share2, Upload } from "lucide-react";

type GeneratedSet = {
  option_a_image_url: string;
  option_b_image_url: string;
  poster_image_url: string;
  share_image_url: string;
};

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
  const [images, setImages] = useState<GeneratedSet>({
    option_a_image_url: initialOptionA ?? "",
    option_b_image_url: initialOptionB ?? "",
    poster_image_url: initialPoster ?? "",
    share_image_url: initialShare ?? "",
  });
  const [generating, setGenerating] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [posterFile, setPosterFile] = useState<File | null>(null);
  const [shareFile, setShareFile] = useState<File | null>(null);
  const [error, setError] = useState("");

  async function generate() {
    setGenerating(true);
    setError("");
    try {
      const response = await fetch("/api/matchups/images/generate", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ matchup_id: matchupId }),
      });
      const data = await response.json();
      if (!response.ok) throw new Error(data.error ?? "Jenerasyon echwe");
      setImages({
        option_a_image_url: data.option_a_image_url,
        option_b_image_url: data.option_b_image_url,
        poster_image_url: data.poster_image_url,
        share_image_url: data.share_image_url,
      });
    } catch (err) {
      setError(err instanceof Error ? err.message : "Jenerasyon echwe");
    } finally {
      setGenerating(false);
    }
  }

  async function uploadManualImages() {
    if (!posterFile || !shareFile) return;
    setUploading(true);
    setError("");
    try {
      const payload = new FormData();
      payload.append("matchup_id", matchupId);
      payload.append("poster", posterFile);
      payload.append("share", shareFile);
      const response = await fetch("/api/matchups/images/upload", {
        method: "POST",
        body: payload,
      });
      const data = await response.json();
      if (!response.ok) throw new Error(data.error ?? "Upload echwe");
      setImages({
        option_a_image_url: data.option_a_image_url,
        option_b_image_url: data.option_b_image_url,
        poster_image_url: data.poster_image_url,
        share_image_url: data.share_image_url,
      });
      setPosterFile(null);
      setShareFile(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Upload echwe");
    } finally {
      setUploading(false);
    }
  }

  return (
    <section
      className="rounded-xl p-5"
      style={{ background: "#0e0f1e", border: "1px solid #1e2040" }}
    >
      <div className="mb-4 flex flex-wrap items-start justify-between gap-3">
        <div>
          <h2 className="text-sm font-semibold text-white">Imaj Matchup</h2>
          <p className="mt-1 max-w-2xl text-xs leading-relaxed" style={{ color: "#64748b" }}>
            Kreye de imaj kat la ak yon composite maketing/share. Composite la
            antre nan galri admin lan epi paj share la itilize vèsyon OG li.
          </p>
        </div>
        <button
          onClick={generate}
          disabled={generating}
          className="inline-flex items-center gap-2 rounded-lg px-4 py-2 text-xs font-semibold disabled:opacity-60"
          style={{
            color: "#ffffff",
            background: "linear-gradient(90deg,#7c3aed,#ec4899)",
          }}
        >
          {generating ? (
            <Loader2 size={14} className="animate-spin" />
          ) : (
            <ImagePlus size={14} />
          )}
          {generating ? "Ap jenere..." : images.poster_image_url ? "Rejenere" : "Jenere imaj"}
        </button>
      </div>

      {error && (
        <div
          className="mb-4 rounded-lg px-3 py-2 text-xs"
          style={{ color: "#fca5a5", background: "rgba(239,68,68,.1)" }}
        >
          {error}
        </div>
      )}

      <div className="grid gap-3" style={{ gridTemplateColumns: "1fr 1fr minmax(180px,.8fr)" }}>
        <Preview label="Opsyon A" src={images.option_a_image_url} ratio="4 / 5" />
        <Preview label="Opsyon B" src={images.option_b_image_url} ratio="4 / 5" />
        <Preview label="Composite" src={images.poster_image_url} ratio="4 / 5" />
      </div>

      {(images.option_a_image_url || images.option_b_image_url || images.poster_image_url) && (
        <div className="mt-4 flex flex-wrap gap-2">
          {images.option_a_image_url && (
            <DownloadLink href={images.option_a_image_url} label="Opsyon A" />
          )}
          {images.option_b_image_url && (
            <DownloadLink href={images.option_b_image_url} label="Opsyon B" />
          )}
          {images.poster_image_url && (
            <a
              href={images.poster_image_url}
              download
              className="inline-flex items-center gap-1.5 rounded-lg px-3 py-1.5 text-xs font-semibold"
              style={{ color: "#D4D4D4", border: "1px solid #3a2669" }}
            >
              <Download size={13} />
              Poster 4:5
            </a>
          )}
          {images.share_image_url && (
            <a
              href={images.share_image_url}
              download
              className="inline-flex items-center gap-1.5 rounded-lg px-3 py-1.5 text-xs font-semibold"
              style={{ color: "#a78bfa", border: "1px solid #31205b" }}
            >
              <Share2 size={13} />
              Preview share
            </a>
          )}
          <a
            href="/matchup-images"
            className="rounded-lg px-3 py-1.5 text-xs font-semibold"
            style={{ color: "#94a3b8", border: "1px solid #1e2040" }}
          >
            Louvri galri
          </a>
        </div>
      )}

      <div
        className="mt-4 rounded-xl p-4"
        style={{ background: "#080916", border: "1px solid #1e2040" }}
      >
        <div className="mb-3">
          <h3 className="text-xs font-semibold text-white">Upload Canva</h3>
          <p className="mt-1 text-xs leading-relaxed" style={{ color: "#64748b" }}>
            Telechaje opsyon A/B, fini poster la nan Canva, epi remete poster PNG
            1080 x 1350 ak share PNG 1200 x 630 la isit la.
          </p>
        </div>
        <div className="grid gap-3 md:grid-cols-2">
          <UploadField
            label="Poster 4:5"
            value={posterFile}
            onChange={setPosterFile}
          />
          <UploadField
            label="Share OG"
            value={shareFile}
            onChange={setShareFile}
          />
        </div>
        <button
          onClick={uploadManualImages}
          disabled={uploading || !posterFile || !shareFile}
          className="mt-3 inline-flex items-center gap-2 rounded-lg px-4 py-2 text-xs font-semibold disabled:opacity-50"
          style={{ color: "#ffffff", border: "1px solid #3a2669" }}
        >
          {uploading ? <Loader2 size={14} className="animate-spin" /> : <Upload size={14} />}
          {uploading ? "Ap upload..." : "Upload poster ak share"}
        </button>
      </div>
    </section>
  );
}

function DownloadLink({ href, label }: { href: string; label: string }) {
  return (
    <a
      href={href}
      download
      className="inline-flex items-center gap-1.5 rounded-lg px-3 py-1.5 text-xs font-semibold"
      style={{ color: "#c4b5fd", border: "1px solid #31205b" }}
    >
      <Download size={13} />
      {label}
    </a>
  );
}

function UploadField({
  label,
  value,
  onChange,
}: {
  label: string;
  value: File | null;
  onChange: (file: File | null) => void;
}) {
  return (
    <label
      className="block rounded-lg px-3 py-2 text-xs"
      style={{ color: "#94a3b8", border: "1px solid #1e2040" }}
    >
      <span className="mb-1 block font-semibold text-white">{label}</span>
      <input
        type="file"
        accept="image/png,image/jpeg,image/webp"
        onChange={(event) => onChange(event.currentTarget.files?.[0] ?? null)}
        className="block w-full text-xs"
      />
      <span className="mt-1 block truncate" style={{ color: "#64748b" }}>
        {value?.name ?? "PNG, JPEG, oswa WebP"}
      </span>
    </label>
  );
}

function Preview({
  label,
  src,
  ratio,
}: {
  label: string;
  src: string;
  ratio: string;
}) {
  return (
    <div>
      <div className="mb-1 text-xs font-semibold" style={{ color: "#94a3b8" }}>
        {label}
      </div>
      <div
        className="flex items-center justify-center overflow-hidden rounded-xl text-xs"
        style={{
          aspectRatio: ratio,
          color: "#475569",
          background: "#080916",
          border: "1px solid #1e2040",
        }}
      >
        {src ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img src={src} alt={label} className="h-full w-full object-cover" />
        ) : (
          "Poko gen imaj"
        )}
      </div>
    </div>
  );
}
