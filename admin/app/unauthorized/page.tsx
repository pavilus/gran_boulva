import Link from "next/link";

export default function UnauthorizedPage() {
  return (
    <main
      className="min-h-screen flex items-center justify-center px-6"
      style={{ background: "#07080f", color: "#e2e8f0" }}
    >
      <div className="w-full max-w-md text-center">
        <div className="text-white text-2xl font-bold mb-3">Aksè pa otorize</div>
        <p className="text-sm leading-6 mb-6" style={{ color: "#94a3b8" }}>
          Kont sa a konekte, men li pa gen wòl admin pou antre nan panèl la.
        </p>
        <Link
          href="/login"
          className="inline-flex items-center justify-center rounded-lg px-4 py-2 text-sm font-semibold"
          style={{ background: "#7c3aed", color: "white" }}
        >
          Tounen sou login
        </Link>
      </div>
    </main>
  );
}
