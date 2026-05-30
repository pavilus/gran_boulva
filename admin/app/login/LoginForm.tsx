"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { Eye, EyeOff, LogIn, Loader2 } from "lucide-react";

export default function LoginForm() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPw, setShowPw] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    setLoading(true);
    const supabase = createClient();
    const { error: authError } = await supabase.auth.signInWithPassword({
      email,
      password,
    });
    if (authError) {
      setError("Email oswa modpas ou a pa kòrèk.");
      setLoading(false);
      return;
    }
    router.push("/");
    router.refresh();
  }

  const inputStyle: React.CSSProperties = {
    width: "100%",
    background: "#0e0f1e",
    border: "1px solid #1e2040",
    borderRadius: 10,
    padding: "11px 14px",
    color: "white",
    fontSize: 13,
    outline: "none",
  };

  return (
    <form
      onSubmit={handleSubmit}
      className="rounded-2xl p-6 space-y-4"
      style={{ background: "#0e0f1e", border: "1px solid #1e2040" }}
    >
      <div>
        <div style={{ color: "#94a3b8", fontSize: 12, marginBottom: 6 }}>Adrès Email</div>
        <input
          type="email"
          required
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          placeholder="admin@granboulva.com"
          style={inputStyle}
        />
      </div>

      <div>
        <div style={{ color: "#94a3b8", fontSize: 12, marginBottom: 6 }}>Modpas</div>
        <div className="relative">
          <input
            type={showPw ? "text" : "password"}
            required
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder="••••••••"
            style={{ ...inputStyle, paddingRight: 40 }}
          />
          <button
            type="button"
            onClick={() => setShowPw(!showPw)}
            className="absolute right-3 top-1/2 -translate-y-1/2"
            style={{ color: "#94a3b8" }}
          >
            {showPw ? <EyeOff size={15} /> : <Eye size={15} />}
          </button>
        </div>
      </div>

      {error && (
        <div
          className="text-xs px-3 py-2 rounded-lg"
          style={{ background: "rgba(239,68,68,0.12)", color: "#f87171", border: "1px solid rgba(239,68,68,0.2)" }}
        >
          {error}
        </div>
      )}

      <button
        type="submit"
        disabled={loading}
        className="w-full flex items-center justify-center gap-2 py-3 rounded-xl font-semibold text-sm text-white"
        style={{
          background: loading ? "#2d1b69" : "linear-gradient(90deg,#7c3aed,#a855f7)",
          boxShadow: loading ? "none" : "0 0 20px rgba(124,58,237,0.4)",
          cursor: loading ? "not-allowed" : "pointer",
        }}
      >
        {loading ? <Loader2 size={16} className="animate-spin" /> : <LogIn size={16} />}
        {loading ? "Koneksyon..." : "Konekte"}
      </button>
    </form>
  );
}
