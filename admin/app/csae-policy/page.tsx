import LegalPage from "@/components/LegalPage";

export const metadata = { title: "CSAE Policy — Gran Boulva" };

export default function CsaePolicyPage() {
  return (
    <LegalPage
      title="Child Safety Policy"
      subtitle="Politik Pwoteksyon Timoun / Child Safety & CSAE Policy"
      effectiveDate="June 4, 2026"
      sections={[
        {
          title: "Zero Tolerance / Toljerans Zewo",
          content: `Gran Boulva has a strict zero-tolerance policy toward any content that sexually exploits or abuses minors (CSAE — Child Sexual Abuse and Exploitation). This includes, but is not limited to:

• Child sexual abuse material (CSAM) of any kind
• Content that sexualizes minors in any way
• Any attempt to groom, exploit, or solicit minors
• Links, references, or descriptions that facilitate CSAE

Any account found sharing, distributing, or facilitating such content will be immediately and permanently banned. We will report all identified CSAM and related content to the National Center for Missing and Exploited Children (NCMEC) and cooperate fully with law enforcement.`,
        },
        {
          title: "How to Report / Kijan Pou Rapòte",
          content: [
            "In-app: tap the three-dot menu on any post or profile → Report → select the appropriate category.",
            "By email: send a detailed report to safety@granboulva.com with the username, content description, and any screenshots.",
            "To report CSAM directly to authorities: use the NCMEC CyberTipline at www.missingkids.org/gethelpnow/cybertipline.",
            "All reports are reviewed by our moderation team within 24 hours. Reports involving minors are escalated immediately.",
          ],
        },
        {
          title: "Enforcement / Aplikasyon",
          content: [
            "Immediate removal of any reported content pending review.",
            "Permanent account termination for any confirmed CSAE violation — no warnings, no appeals.",
            "Mandatory reporting to NCMEC and relevant law enforcement for any confirmed CSAM.",
            "Preservation and disclosure of account data to law enforcement upon valid legal request.",
            "Proactive scanning of uploaded media using industry-standard hash-matching tools to detect known CSAM.",
          ],
        },
        {
          title: "Age Requirements / Kondisyon Laj",
          content: `Gran Boulva is not directed to children under the age of 13. Users must be at least 13 years old to create an account. Users in the European Union must be at least 16 years old or have verifiable parental consent.

We do not knowingly allow anyone under 13 to create an account. If we discover an underage user, we will immediately delete the account and all associated data. To report a potentially underage user, contact us at safety@granboulva.com.`,
        },
        {
          title: "Contact / Kontak",
          content: `For child safety concerns, contact us at:

Email: safety@granboulva.com
Response time: within 24 hours for all reports; immediate escalation for confirmed CSAE.

To report CSAM to authorities:
• NCMEC CyberTipline: www.missingkids.org/gethelpnow/cybertipline
• FBI: tips.fbi.gov
• Internet Crimes Against Children Task Force: www.icactaskforce.org`,
        },
      ]}
    />
  );
}
