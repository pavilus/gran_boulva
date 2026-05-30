import Link from "next/link";

type MatchupOption = { id: string; option_name: string; vote_count: number };
type Matchup = {
  id: string;
  title_ht: string;
  status: string;
  published_at: string | null;
  category: { name_ht: string }[] | { name_ht: string } | null;
  options: MatchupOption[];
};

function fmt(n: number): string {
  if (n >= 1_000_000) return `${(n / 1_000_000).toFixed(1)}M`;
  if (n >= 1_000) return `${(n / 1_000).toFixed(1)}K`;
  return n.toString();
}

export default function RecentMatchups({ matchups }: { matchups: Matchup[] }) {
  return (
    <div
      className="rounded-xl p-5"
      style={{ background: "#0e0f1e", border: "1px solid #1e2040" }}
    >
      <div className="flex items-center justify-between mb-4">
        <div className="text-white font-semibold text-sm">Matchups dènye yo</div>
        <Link href="/matchups" style={{ color: "#a78bfa", fontSize: 11, textDecoration: "none" }}>Wè tout →</Link>
      </div>
      <div className="space-y-2">
        {matchups.length === 0 && (
          <div className="text-center py-6" style={{ color: "#94a3b8", fontSize: 12 }}>
            Pa gen matchups pou kounye a
          </div>
        )}
        {matchups.map((m, i) => {
          const totalVotes = (m.options ?? []).reduce((s, o) => s + (o.vote_count ?? 0), 0);
          const topVotes = (m.options ?? []).reduce((max, o) => Math.max(max, o.vote_count ?? 0), 0);
          const pctA = totalVotes > 0 ? Math.round((topVotes / totalVotes) * 100) : 50;
          return (
          <Link
            key={m.id}
            href={`/matchups/${m.id}`}
            className="flex items-center gap-3 p-3 rounded-lg"
            style={{ background: "#13152a", textDecoration: "none", display: "flex" }}
          >
            <div
              className="rounded-lg shrink-0 flex items-center justify-center text-xs font-bold"
              style={{
                width: 36,
                height: 36,
                background: "linear-gradient(135deg,#7c3aed,#ec4899)",
                color: "#D4D4D4",
              }}
            >
              {i + 1}
            </div>
            <div className="flex-1 min-w-0">
              <div className="text-white text-xs font-medium leading-tight line-clamp-1">
                {m.title_ht}
              </div>
              <div className="flex items-center gap-2 mt-1">
                <span
                  className="text-xs px-1.5 py-0.5 rounded"
                  style={{ background: "rgba(124,58,237,0.15)", color: "#a78bfa", fontSize: 10 }}
                >
                  {(Array.isArray(m.category) ? m.category[0]?.name_ht : m.category?.name_ht) ?? "—"}
                </span>
              </div>
            </div>
            <div className="shrink-0 text-right">
              <div className="text-white text-xs font-bold">{fmt(totalVotes)}</div>
              <div style={{ color: "#94a3b8", fontSize: 10 }}>vòt</div>
            </div>
            <div className="shrink-0" style={{ width: 48 }}>
              <div className="rounded-full overflow-hidden" style={{ height: 4, background: "#1e2040" }}>
                <div
                  className="h-full rounded-full"
                  style={{
                    width: `${pctA}%`,
                    background: "linear-gradient(90deg,#7c3aed,#ec4899)",
                  }}
                />
              </div>
              <div className="flex justify-between mt-0.5">
                <span style={{ color: "#7c3aed", fontSize: 9 }}>{pctA}%</span>
                <span style={{ color: "#ec4899", fontSize: 9 }}>{100 - pctA}%</span>
              </div>
            </div>
          </Link>
          );
        })}
      </div>
    </div>
  );
}
