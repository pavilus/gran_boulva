"use client";

import { useState } from "react";
import { ShieldOff, Shield, UserX, UserCheck } from "lucide-react";

type User = {
  id: string; full_name: string; username: string; email: string; role: string;
  avatar_url?: string; influence_score: number; participation_count: number;
  coin_balance: number; created_at: string;
};

const ROLE_COLORS: Record<string, string> = {
  admin: "#a78bfa", owner: "#ec4899", moderator: "#67e8f9",
  user: "#94a3b8", suspended: "#ef4444",
};

function fmtDate(d: string) {
  return new Date(d).toLocaleDateString("fr-HT", { month: "short", day: "numeric", year: "numeric" });
}

async function doAction(id: string, action: string) {
  await fetch("/api/users/action", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ id, action }),
  });
}

export default function UserList({ users: initial }: { users: User[] }) {
  const [users, setUsers] = useState(initial);
  const [search, setSearch] = useState("");
  const [loading, setLoading] = useState<string | null>(null);
  const [filters, setFilters] = useState({
    user: "",
    email: "",
    role: "",
    influence: "",
    votes: "",
    date: "",
  });

  const filtered = users.filter((u) => {
    const q = search.toLowerCase();
    if (q && !`${u.username} ${u.email} ${u.full_name} ${u.role}`.toLowerCase().includes(q)) return false;
    if (filters.user && !`${u.full_name} ${u.username}`.toLowerCase().includes(filters.user.toLowerCase())) return false;
    if (filters.email && !u.email.toLowerCase().includes(filters.email.toLowerCase())) return false;
    if (filters.role && !u.role.toLowerCase().includes(filters.role.toLowerCase())) return false;
    if (filters.influence && !String(u.influence_score ?? 0).includes(filters.influence)) return false;
    if (filters.votes && !String(u.participation_count ?? 0).includes(filters.votes)) return false;
    if (filters.date && !fmtDate(u.created_at).toLowerCase().includes(filters.date.toLowerCase())) return false;
    return true;
  });

  const act = async (id: string, action: string) => {
    setLoading(`${id}-${action}`);
    await doAction(id, action);
    setUsers((prev) => prev.map((u) => {
      if (u.id !== id) return u;
      if (action === "suspend") return { ...u, role: "suspended" };
      if (action === "unsuspend") return { ...u, role: "user" };
      if (action === "make_moderator") return { ...u, role: "moderator" };
      if (action === "remove_moderator") return { ...u, role: "user" };
      return u;
    }));
    setLoading(null);
  };

  return (
    <div className="space-y-4">
      <div className="flex items-center gap-3">
        <input
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="Chèche pa non, email…"
          className="px-3 py-2 rounded-lg text-sm text-white outline-none flex-1 max-w-sm"
          style={{ background: "#0e0f1e", border: "1px solid #2e3060" }}
        />
        <div style={{ color: "#94a3b8", fontSize: 13 }}>{filtered.length} itilizatè</div>
      </div>

      <div className="rounded-xl overflow-hidden" style={{ border: "1px solid #2e3060" }}>
        <table className="w-full text-sm">
          <thead>
            <tr style={{ background: "#0a0b18", borderBottom: "1px solid #2e3060" }}>
              {["Itilizatè", "Email", "Wòl", "Enfliyans", "Vòt", "Manm depi", "Aksyon"].map((h) => (
                <th key={h} className="px-4 py-3 text-left text-xs font-semibold uppercase" style={{ color: "#94a3b8" }}>{h}</th>
              ))}
            </tr>
            <tr style={{ background: "#0a0b18", borderBottom: "1px solid #2e3060" }}>
              {[
                ["user", "Filtre itilizatè"],
                ["email", "Filtre email"],
                ["role", "Filtre wòl"],
                ["influence", "Filtre enfliyans"],
                ["votes", "Filtre vòt"],
                ["date", "Filtre dat"],
              ].map(([key, placeholder]) => (
                <th key={key} className="px-4 pb-3">
                  <input
                    value={filters[key as keyof typeof filters]}
                    onChange={(e) => setFilters((prev) => ({ ...prev, [key]: e.target.value }))}
                    placeholder={placeholder}
                    className="w-full px-2 py-1.5 rounded-md text-xs text-white outline-none"
                    style={{ background: "#0e0f1e", border: "1px solid #2e3060" }}
                  />
                </th>
              ))}
              <th className="px-4 pb-3">
                <button onClick={() => setFilters({ user: "", email: "", role: "", influence: "", votes: "", date: "" })}
                  className="px-2 py-1.5 rounded-md text-xs font-semibold"
                  style={{ color: "#94a3b8", border: "1px solid #2e3060" }}>Reset</button>
              </th>
            </tr>
          </thead>
          <tbody>
            {filtered.length === 0 && (
              <tr><td colSpan={7} className="px-4 py-12 text-center" style={{ color: "#94a3b8" }}>Pa gen itilizatè</td></tr>
            )}
            {filtered.map((u) => (
              <tr key={u.id} style={{ borderBottom: "1px solid #2e3060", background: "#0e0f1e" }}>
                <td className="px-4 py-3">
                  <div className="flex items-center gap-2">
                    <div
                      className="flex items-center justify-center rounded-full text-xs font-bold text-white shrink-0"
                      style={{ width: 32, height: 32, background: "linear-gradient(135deg,#7c3aed,#ec4899)" }}
                    >
                      {(u.full_name || u.username || "?").charAt(0).toUpperCase()}
                    </div>
                    <div>
                      <div className="text-white font-medium">{u.full_name || u.username}</div>
                      <div style={{ color: "#94a3b8", fontSize: 11 }}>@{u.username}</div>
                    </div>
                  </div>
                </td>
                <td className="px-4 py-3" style={{ color: "#94a3b8" }}>{u.email}</td>
                <td className="px-4 py-3">
                  <span className="px-2 py-0.5 rounded-full text-xs font-semibold capitalize"
                    style={{ background: `${ROLE_COLORS[u.role] ?? "#94a3b8"}22`, color: ROLE_COLORS[u.role] ?? "#94a3b8" }}>
                    {u.role}
                  </span>
                </td>
                <td className="px-4 py-3 font-semibold" style={{ color: "#a78bfa" }}>{u.influence_score}</td>
                <td className="px-4 py-3 text-white">{u.participation_count}</td>
                <td className="px-4 py-3" style={{ color: "#94a3b8" }}>{fmtDate(u.created_at)}</td>
                <td className="px-4 py-3">
                  <div className="flex items-center gap-1">
                    {u.role !== "moderator" && u.role !== "admin" && u.role !== "suspended" && (
                      <button onClick={() => act(u.id, "make_moderator")} disabled={!!loading} title="Fè Modérateur"
                        className="p-1.5 rounded-lg" style={{ color: "#67e8f9", background: "rgba(103,232,249,0.1)" }}>
                        <Shield size={14} />
                      </button>
                    )}
                    {u.role === "moderator" && (
                      <button onClick={() => act(u.id, "remove_moderator")} disabled={!!loading} title="Retire Modérateur"
                        className="p-1.5 rounded-lg" style={{ color: "#94a3b8", background: "rgba(148,163,184,0.1)" }}>
                        <ShieldOff size={14} />
                      </button>
                    )}
                    {u.role !== "suspended" && u.role !== "admin" && (
                      <button onClick={() => { if (confirm(`Suspann @${u.username}?`)) act(u.id, "suspend"); }}
                        disabled={!!loading} title="Suspann"
                        className="p-1.5 rounded-lg" style={{ color: "#ef4444", background: "rgba(239,68,68,0.08)" }}>
                        <UserX size={14} />
                      </button>
                    )}
                    {u.role === "suspended" && (
                      <button onClick={() => act(u.id, "unsuspend")} disabled={!!loading} title="Reaktive"
                        className="p-1.5 rounded-lg" style={{ color: "#22c55e", background: "rgba(34,197,94,0.1)" }}>
                        <UserCheck size={14} />
                      </button>
                    )}
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
