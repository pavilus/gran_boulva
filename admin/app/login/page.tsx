import LoginForm from "./LoginForm";

export default function LoginPage() {
  return (
    <div
      className="flex items-center justify-center min-h-screen w-full"
      style={{ background: "#07080f" }}
    >
      {/* Background glow */}
      <div
        className="absolute inset-0 pointer-events-none"
        style={{
          background:
            "radial-gradient(ellipse 60% 50% at 50% 40%, rgba(124,58,237,0.12) 0%, transparent 70%)",
        }}
      />

      <div className="relative w-full max-w-sm px-4">
        {/* Logo */}
        <div className="flex flex-col items-center mb-8">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img
            src="/logo.png"
            alt="Gran Boulva"
            style={{ width: 72, height: 72, objectFit: "contain", marginBottom: 12, filter: "drop-shadow(0 0 24px rgba(124,58,237,0.5))" }}
          />
          <div className="text-white font-bold text-xl">Gran Boulva</div>
          <div style={{ color: "#6366f1", fontSize: 12, marginTop: 2 }}>Admin Dashboard</div>
        </div>

        <LoginForm />
      </div>
    </div>
  );
}
