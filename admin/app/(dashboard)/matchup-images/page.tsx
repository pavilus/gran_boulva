import Topbar from "@/components/Topbar";
import { createAdminClient } from "@/lib/supabase/admin";
import Link from "next/link";

type ImageSet = {
  id: string;
  matchup_id: string;
  option_a_image_url: string;
  option_b_image_url: string;
  poster_image_url: string | null;
  share_image_url: string | null;
  model: string;
  created_at: string;
  matchup?: { title_ht?: string } | Array<{ title_ht?: string }> | null;
};

function titleFor(imageSet: ImageSet) {
  const matchup = Array.isArray(imageSet.matchup)
    ? imageSet.matchup[0]
    : imageSet.matchup;
  return matchup?.title_ht ?? "Matchup";
}

/** Proxy URL so the browser triggers a real file download (cross-origin `download` attr is ignored) */
function dlUrl(imageUrl: string, filename: string) {
  return `/api/download?url=${encodeURIComponent(imageUrl)}&filename=${encodeURIComponent(filename)}`;
}

export default async function MatchupImagesPage() {
  const supabase = createAdminClient();
  const { data } = await supabase
    .from("matchup_image_sets")
    .select(
      "id, matchup_id, option_a_image_url, option_b_image_url, poster_image_url, share_image_url, model, created_at, matchup:matchups(title_ht)",
    )
    .order("created_at", { ascending: false })
    .limit(100);

  const imageSets = (data ?? []) as ImageSet[];

  return (
    <div
      className="flex flex-col flex-1 min-h-0 overflow-y-auto"
      style={{ background: "#07080f" }}
    >
      <Topbar
        title="Imaj Matchup"
        subtitle={`${imageSets.length} jenerasyon resan`}
      />
      <div className="grid gap-3 p-5" style={{ gridTemplateColumns: "repeat(auto-fill,minmax(174px,1fr))" }}>
        {imageSets.map((imageSet) => {
          const title = titleFor(imageSet);
          const slug = title.slice(0, 30).replace(/\s+/g, "-").toLowerCase();
          return (
            <article
              key={imageSet.id}
              className="overflow-hidden rounded-xl"
              style={{ background: "#0e0f1e", border: "1px solid #1e2040" }}
            >
              {/* Preview: poster if available, otherwise side-by-side option images */}
              {imageSet.poster_image_url ? (
                // eslint-disable-next-line @next/next/no-img-element
                <img
                  src={imageSet.poster_image_url}
                  alt={title}
                  className="w-full"
                  style={{ aspectRatio: "4 / 5", objectFit: "cover" }}
                />
              ) : (
                <div className="flex w-full overflow-hidden" style={{ aspectRatio: "4 / 5" }}>
                  {/* eslint-disable-next-line @next/next/no-img-element */}
                  <img
                    src={imageSet.option_a_image_url}
                    alt="Opsyon A"
                    className="h-full w-1/2"
                    style={{ objectFit: "cover" }}
                  />
                  {/* eslint-disable-next-line @next/next/no-img-element */}
                  <img
                    src={imageSet.option_b_image_url}
                    alt="Opsyon B"
                    className="h-full w-1/2"
                    style={{ objectFit: "cover" }}
                  />
                </div>
              )}

              <div className="space-y-2 p-3">
                <div>
                  <h2 className="line-clamp-2 text-sm font-semibold text-white">{title}</h2>
                  <p className="mt-1 text-xs" style={{ color: "#94a3b8" }}>
                    {new Date(imageSet.created_at).toLocaleString("fr-HT")} · {imageSet.model}
                  </p>
                </div>

                <div className="flex flex-wrap gap-2">
                  {imageSet.poster_image_url && (
                    <a
                      href={dlUrl(imageSet.poster_image_url, `${slug}-poster.png`)}
                      className="rounded-lg px-2 py-1 text-xs font-semibold"
                      style={{ color: "#ffffff", background: "linear-gradient(90deg,#7c3aed,#a855f7)" }}
                    >
                      ↓ Poster
                    </a>
                  )}
                  {imageSet.share_image_url && (
                    <a
                      href={dlUrl(imageSet.share_image_url, `${slug}-share.png`)}
                      className="rounded-lg px-2 py-1 text-xs font-semibold"
                      style={{ color: "#a78bfa", border: "1px solid #31205b" }}
                    >
                      ↓ OG Share
                    </a>
                  )}
                  <a
                    href={dlUrl(imageSet.option_a_image_url, `${slug}-option-a.png`)}
                    className="rounded-lg px-2 py-1 text-xs font-semibold"
                    style={{ color: "#94a3b8", border: "1px solid #1e2040" }}
                  >
                    ↓ Opsyon A
                  </a>
                  <a
                    href={dlUrl(imageSet.option_b_image_url, `${slug}-option-b.png`)}
                    className="rounded-lg px-2 py-1 text-xs font-semibold"
                    style={{ color: "#94a3b8", border: "1px solid #1e2040" }}
                  >
                    ↓ Opsyon B
                  </a>
                  <Link
                    href={`/matchups/${imageSet.matchup_id}`}
                    className="rounded-lg px-2 py-1 text-xs font-semibold"
                    style={{ color: "#94a3b8", border: "1px solid #1e2040" }}
                  >
                    Matchup →
                  </Link>
                </div>
              </div>
            </article>
          );
        })}

        {imageSets.length === 0 && (
          <div
            className="rounded-xl p-8 text-sm"
            style={{ color: "#94a3b8", border: "1px solid #1e2040" }}
          >
            Pa gen imaj jenerasyon ankò.
          </div>
        )}
      </div>
    </div>
  );
}
