export const metadata = { title: "Delete Account — Gran Boulva" };

export default function DeleteAccountPage() {
  return (
    <div style={{ minHeight: "100vh", background: "#0a0a0f", color: "#e2e8f0", fontFamily: "system-ui, sans-serif" }}>
      {/* Header */}
      <div style={{ background: "#0e0f1e", borderBottom: "1px solid #2e3060", padding: "16px 24px" }}>
        <span style={{ color: "#94a3b8", fontSize: 13 }}>granboulva.com</span>
      </div>

      <div style={{ maxWidth: 600, margin: "0 auto", padding: "48px 24px 80px" }}>
        {/* Title */}
        <div style={{ marginBottom: 40 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 12, marginBottom: 16 }}>
            <div style={{
              width: 44, height: 44, borderRadius: 12,
              background: "rgba(239,68,68,0.12)",
              display: "flex", alignItems: "center", justifyContent: "center",
              fontSize: 22,
            }}>🗑️</div>
            <h1 style={{ fontSize: 26, fontWeight: 800, color: "#D4D4D4", margin: 0 }}>
              Efase Kont / Delete Account
            </h1>
          </div>
          <p style={{ color: "#94a3b8", fontSize: 14, lineHeight: 1.7, margin: 0 }}>
            You can request permanent deletion of your Gran Boulva account and all associated data. This action is irreversible.
            <br /><br />
            <span style={{ color: "#6b7280", fontSize: 13 }}>
              Ou ka mande efasman pèmanan kont Gran Boulva ou ak tout done ki asosye. Aksyon sa a pa ka defèt.
            </span>
          </p>
        </div>

        {/* Option 1 — In-app */}
        <div style={{
          background: "#0e0f1e",
          border: "1px solid #2e3060",
          borderRadius: 16,
          padding: "24px",
          marginBottom: 16,
        }}>
          <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 12 }}>
            <span style={{
              background: "#A855F7", color: "#fff",
              fontSize: 11, fontWeight: 700, padding: "3px 9px",
              borderRadius: 99, letterSpacing: 0.5,
            }}>RECOMMENDED / REKÒMANDE</span>
          </div>
          <h2 style={{ fontSize: 16, fontWeight: 700, color: "#D4D4D4", margin: "0 0 8px" }}>
            Delete from within the app
          </h2>
          <p style={{ color: "#94a3b8", fontSize: 14, lineHeight: 1.7, margin: "0 0 16px" }}>
            The fastest way. Your account and data are deleted immediately.
            <br />
            <span style={{ color: "#6b7280", fontSize: 13 }}>Fason ki pi vit. Kont ou ak done ou yo efase imedyatman.</span>
          </p>
          <ol style={{ margin: 0, paddingLeft: 20, display: "flex", flexDirection: "column", gap: 8 }}>
            {[
              { en: "Open the Gran Boulva app", ht: "Louvri aplikasyon Gran Boulva" },
              { en: "Tap the Menu tab (bottom right)", ht: "Tape tab Meni an (anba adwat)" },
              { en: "Go to Settings / Anviwònman", ht: "Al nan Anviwònman" },
              { en: "Scroll to Danger Zone / Zòn danjere", ht: "Desann rive Zòn danjere" },
              { en: "Tap \"Efase kont mwen\" and confirm", ht: "Tape \"Efase kont mwen\" epi konfime" },
            ].map((step, i) => (
              <li key={i} style={{ color: "#94a3b8", fontSize: 14, lineHeight: 1.6 }}>
                {step.en}
                <span style={{ color: "#6b7280", fontSize: 12, display: "block" }}>{step.ht}</span>
              </li>
            ))}
          </ol>
        </div>

        {/* Option 2 — Email */}
        <div style={{
          background: "#0e0f1e",
          border: "1px solid #2e3060",
          borderRadius: 16,
          padding: "24px",
          marginBottom: 32,
        }}>
          <h2 style={{ fontSize: 16, fontWeight: 700, color: "#D4D4D4", margin: "0 0 8px" }}>
            Request by email
          </h2>
          <p style={{ color: "#94a3b8", fontSize: 14, lineHeight: 1.7, margin: "0 0 16px" }}>
            If you no longer have access to the app, email us and we will delete your account within 30 days.
            <br />
            <span style={{ color: "#6b7280", fontSize: 13 }}>
              Si ou pa ka jwenn aksè nan aplikasyon an, voye nou yon imel epi nou pral efase kont ou nan 30 jou.
            </span>
          </p>
          <a
            href="mailto:support@granboulva.com?subject=Account%20Deletion%20Request&body=Username%3A%20%5Byour%20username%5D%0AEmail%20address%20used%20to%20sign%20up%3A%20%5Byour%20email%5D%0A%0APlease%20delete%20my%20Gran%20Boulva%20account%20and%20all%20associated%20data."
            style={{
              display: "inline-block",
              background: "rgba(239,68,68,0.10)",
              border: "1px solid rgba(239,68,68,0.30)",
              color: "#f87171",
              padding: "10px 20px",
              borderRadius: 10,
              fontSize: 14,
              fontWeight: 600,
              textDecoration: "none",
            }}
          >
            support@granboulva.com
          </a>
          <p style={{ color: "#6b7280", fontSize: 12, margin: "12px 0 0", lineHeight: 1.6 }}>
            Include your username and the email address used to sign up.
            <br />Mete non itilizatè ou ak adrès imel ou te itilize pou enskri.
          </p>
        </div>

        {/* What gets deleted */}
        <div style={{
          background: "rgba(168,85,247,0.06)",
          border: "1px solid rgba(168,85,247,0.18)",
          borderRadius: 16,
          padding: "20px 24px",
          marginBottom: 32,
        }}>
          <h3 style={{ fontSize: 14, fontWeight: 700, color: "#c4b5fd", margin: "0 0 12px" }}>
            What gets deleted / Sa k ap efase
          </h3>
          <ul style={{ margin: 0, paddingLeft: 18, display: "flex", flexDirection: "column", gap: 6 }}>
            {[
              "Your profile, username, and avatar",
              "All votes, arguments, replies, and reactions",
              "Your coin balance and transaction history",
              "Your badges, streak, and prediction history",
              "All follows and followers",
            ].map((item, i) => (
              <li key={i} style={{ color: "#94a3b8", fontSize: 13, lineHeight: 1.6 }}>{item}</li>
            ))}
          </ul>
          <p style={{ color: "#6b7280", fontSize: 12, margin: "12px 0 0", lineHeight: 1.6 }}>
            Payment transaction records may be retained for up to 7 years as required by financial compliance law.
            <br />Dosye tranzaksyon pèman ka konsève pou jiska 7 ane jan lwa konfòmite finansye egzije.
          </p>
        </div>

        <p style={{ color: "#4b5563", fontSize: 12, textAlign: "center", lineHeight: 1.6 }}>
          Questions? Contact us at{" "}
          <a href="mailto:support@granboulva.com" style={{ color: "#A855F7", textDecoration: "none" }}>
            support@granboulva.com
          </a>
          {" "}· <a href="/privacy" style={{ color: "#6b7280", textDecoration: "none" }}>Privacy Policy</a>
        </p>
      </div>
    </div>
  );
}
