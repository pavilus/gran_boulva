import { NextRequest, NextResponse } from "next/server";
import { requireAdmin } from "@/lib/auth/admin";
import { createAdminClient } from "@/lib/supabase/admin";

export const runtime = "nodejs";

const acceptedTypes = new Set(["image/png", "image/jpeg", "image/webp"]);

async function uploadImage(
  supabase: ReturnType<typeof createAdminClient>,
  folder: string,
  file: File,
) {
  const extension = file.type === "image/jpeg" ? "jpg" : file.type.split("/")[1];
  const path = `${folder}/${Date.now()}-${crypto.randomUUID()}.${extension}`;
  const { error } = await supabase.storage
    .from("matchup-images")
    .upload(path, Buffer.from(await file.arrayBuffer()), { contentType: file.type, upsert: false });
  if (error) throw new Error(error.message);
  const { data: { publicUrl } } = supabase.storage.from("matchup-images").getPublicUrl(path);
  return publicUrl;
}

function getFile(formData: FormData, key: string): File {
  const value = formData.get(key);
  if (!(value instanceof File) || value.size === 0) throw new Error(`${key} image required`);
  if (!acceptedTypes.has(value.type)) throw new Error(`${key} must be PNG, JPEG, or WebP`);
  return value;
}

export async function POST(req: NextRequest) {
  const forbidden = await requireAdmin();
  if (forbidden) return forbidden;

  try {
    const formData = await req.formData();
    const matchupId = formData.get("matchup_id");
    if (typeof matchupId !== "string" || !matchupId)
      return NextResponse.json({ error: "matchup_id required" }, { status: 400 });

    const supabase = createAdminClient();

    // ── Single-slot upload ─────────────────────────────────────────────────────
    // slot: "option_a" | "option_b" | "poster" | "share"
    const slot = formData.get("slot") as string | null;
    if (slot) {
      const file = getFile(formData, "image");

      if (slot === "option_a" || slot === "option_b") {
        const label = slot === "option_a" ? "A" : "B";
        const { data: option, error: optErr } = await supabase
          .from("matchup_options").select("id")
          .eq("matchup_id", matchupId).eq("option_label", label).single();
        if (optErr || !option) throw new Error(`Option ${label} not found`);
        const url = await uploadImage(supabase, `options/${slot}`, file);
        const { error: upErr } = await supabase
          .from("matchup_options").update({ image_url: url }).eq("id", option.id);
        if (upErr) throw new Error(upErr.message);
        return NextResponse.json({ ok: true, slot, url });
      }

      if (slot === "poster" || slot === "share") {
        const field = slot === "poster" ? "poster_image_url" : "share_image_url";
        const folder = slot === "poster" ? "manual/posters" : "manual/share";
        const url = await uploadImage(supabase, folder, file);
        const { error: upErr } = await supabase
          .from("matchups").update({ [field]: url }).eq("id", matchupId);
        if (upErr) throw new Error(upErr.message);
        return NextResponse.json({ ok: true, slot, url });
      }

      return NextResponse.json({ error: "Unknown slot" }, { status: 400 });
    }

    // ── Legacy batch upload (poster + share together, Canva workflow) ──────────
    const poster = getFile(formData, "poster");
    const share = getFile(formData, "share");

    const { data: matchup, error: matchupLoadError } = await supabase
      .from("matchups").select("id, options:matchup_options(id, option_label, image_url)")
      .eq("id", matchupId).single();
    if (matchupLoadError || !matchup)
      return NextResponse.json({ error: matchupLoadError?.message ?? "Matchup not found" }, { status: 404 });

    const options = (matchup.options ?? []) as { id: string; option_label: string; image_url?: string | null }[];
    const optionA = options.find((o) => o.option_label === "A");
    const optionB = options.find((o) => o.option_label === "B");

    const [posterImageUrl, shareImageUrl] = await Promise.all([
      uploadImage(supabase, "manual/posters", poster),
      uploadImage(supabase, "manual/share", share),
    ]);

    const { error: matchupUpdateError } = await supabase
      .from("matchups").update({ poster_image_url: posterImageUrl, share_image_url: shareImageUrl })
      .eq("id", matchupId);
    if (matchupUpdateError) throw new Error(matchupUpdateError.message);

    if (optionA?.image_url && optionB?.image_url) {
      await supabase.from("matchup_image_sets").insert({
        matchup_id: matchupId,
        option_a_image_url: optionA.image_url,
        option_b_image_url: optionB.image_url,
        poster_image_url: posterImageUrl,
        share_image_url: shareImageUrl,
        model: "manual-canva",
      });
    }

    return NextResponse.json({
      ok: true,
      option_a_image_url: optionA?.image_url ?? "",
      option_b_image_url: optionB?.image_url ?? "",
      poster_image_url: posterImageUrl,
      share_image_url: shareImageUrl,
    });
  } catch (error) {
    console.error("matchup image upload failed", error);
    return NextResponse.json(
      { error: error instanceof Error ? error.message : "Upload failed" },
      { status: 500 },
    );
  }
}
