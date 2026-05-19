import { NextRequest, NextResponse } from "next/server";
import { requireAdmin } from "@/lib/auth/admin";
import { createAdminClient } from "@/lib/supabase/admin";
import sharp from "sharp";

export const runtime = "nodejs";

const MAX_UPLOAD_BYTES = 10 * 1024 * 1024;
const ALLOWED_TYPES = new Set(["image/jpeg", "image/jpg", "image/png", "image/webp", "image/gif"]);

function withTimeout<T>(promise: Promise<T>, ms: number, message: string): Promise<T> {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error(message)), ms);
    promise
      .then(resolve, reject)
      .finally(() => clearTimeout(timer));
  });
}

export async function POST(req: NextRequest) {
  const forbidden = await requireAdmin();
  if (forbidden) return forbidden;

  const formData = await req.formData();
  const file = formData.get("file") as File | null;
  if (!file) return NextResponse.json({ error: "No file" }, { status: 400 });
  if (!ALLOWED_TYPES.has(file.type)) {
    return NextResponse.json({ error: "Unsupported image type" }, { status: 400 });
  }
  if (file.size > MAX_UPLOAD_BYTES) {
    return NextResponse.json({ error: "Image is larger than 10MB" }, { status: 400 });
  }

  const raw = Buffer.from(await file.arrayBuffer());

  let compressed: Buffer;
  try {
    compressed = await withTimeout(
      sharp(raw, { animated: false, limitInputPixels: 24_000_000 })
        .rotate()
        .resize(800, 900, { fit: "inside", withoutEnlargement: true })
        .webp({ quality: 80 })
        .toBuffer(),
      15_000,
      "Image compression timed out"
    );
  } catch (err) {
    console.error("matchup image compression failed", err);
    return NextResponse.json(
      { error: err instanceof Error ? err.message : "Image compression failed" },
      { status: 500 }
    );
  }

  const path = `options/${Date.now()}-${crypto.randomUUID()}.webp`;
  const supabase = createAdminClient();

  const { error } = await supabase.storage
    .from("matchup-images")
    .upload(path, compressed, { contentType: "image/webp", upsert: true });

  if (error) return NextResponse.json({ error: error.message }, { status: 500 });

  const { data: { publicUrl } } = supabase.storage
    .from("matchup-images")
    .getPublicUrl(path);

  return NextResponse.json({ url: publicUrl });
}
