import LegalPage from "@/components/LegalPage";

export const metadata = { title: "Moderation Policy — Gran Boulva" };

export default function ModerationPolicyPage() {
  return (
    <LegalPage
      title="Moderation Policy"
      subtitle="Politik Moderasyon / Moderation Policy"
      effectiveDate="June 4, 2026"
      sections={[
        {
          title: "Our Commitment / Angajman Nou",
          content: `Gran Boulva is a debate platform built around Haitian culture and community. We are committed to maintaining a space where passionate, honest, and respectful debate can thrive. This Moderation Policy explains what content is prohibited, how we enforce our rules, and what options users have when they disagree with a moderation decision.

Gran Boulva se yon platfòm debat ki bati sou kilti ak kominote ayisyen. Nou angaje pou kenbe yon espas kote debat pasyone, onèt, ak respektye ka fleri. Politik Moderasyon sa a eksplike ki kontni ki entèdi, kijan nou aplike règ nou yo, ak ki opsyon itilizatè yo genyen lè yo pa dakò ak yon desizyon moderasyon.`,
        },
        {
          title: "Prohibited Content / Kontni Entèdi",
          content: [
            "Hate speech targeting any person or group based on race, ethnicity, religion, gender, sexual orientation, disability, or national origin. | Diskou rayisab kont nenpòt moun oswa gwoup ki baze sou ras, etnisite, relijyon, sèks, oryantasyon seksyèl, andikap, oswa orijin nasyonal.",
            "Harassment, threats, or targeted abuse of any user. | Asisman, menas, oswa abi sible kont nenpòt itilizatè.",
            "Child sexual abuse material (CSAM) or any content that sexualizes minors. | Materyèl abi seksyèl timoun (CSAM) oswa nenpòt kontni ki seksyalize minè.",
            "Doxxing — sharing private personal information of another person without consent. | Doxxing — pataje enfòmasyon pèsonèl prive yon lòt moun san konsantman.",
            "Spam, coordinated inauthentic behavior, or artificial manipulation of votes and rankings. | Spam, konpòtman kowòdone inotantik, oswa manipilasyon atifisyèl vòt ak klase.",
            "Misinformation presented as fact that could cause real-world harm. | Dezenfòmasyon prezante kòm reyalite ki ka koze dòmaj reyèl.",
            "Impersonation of any person, brand, or organization. | Izurpasyon idantite nenpòt moun, mak, oswa òganizasyon.",
            "Any content that violates applicable law, including copyright infringement. | Nenpòt kontni ki vyole lwa ki aplikab, enkli vyolasyon dwa otè.",
          ],
        },
        {
          title: "How We Moderate / Kijan Nou Modere",
          content: `Gran Boulva uses a combination of automated detection and human review:

• Automated filters flag content matching known patterns of harmful speech before it is published.
• User reports are reviewed by our moderation team within 24 hours. Reports involving minors or imminent threats are escalated immediately.
• Moderators review flagged content in context — we do not take action on content out of context.
• Repeated minor violations result in escalating consequences. Severe violations result in immediate action.

Gran Boulva itilize yon kombinasyon deteksyon otomatik ak revizyon imen.`,
        },
        {
          title: "Enforcement Actions / Aksyon Aplikatif",
          content: [
            "Content removal — the violating post, argument, or reply is deleted. | Retire kontni — pòs, agiman, oswa repons ki vyole a efase.",
            "Warning — a formal notice sent to the account. | Avètisman — yon avi fòmèl voye bay kont lan.",
            "Temporary suspension — account access restricted for 1–30 days depending on severity. | Sispansyon tanporè — aksè kont restreint pou 1–30 jou depann sou gravite.",
            "Permanent ban — account permanently disabled. Applied for severe violations including CSAE, doxxing, or repeated serious violations. | Entèdiksyon pèmanan — kont dezaktive pèmananman.",
            "Legal referral — content and account data reported to law enforcement for criminal violations including CSAM. | Referans legal — kontni ak done kont rapòte bay otorite jidisyè.",
          ],
        },
        {
          title: "How to Report / Kijan Pou Rapòte",
          content: `To report a post, argument, or user:
• Tap the three-dot (⋯) menu on any post or profile → Report → select a category.
• Email: support@granboulva.com

All reports are confidential. We will not notify the reported user of who filed the report. We will notify you of the outcome within 7 days.

Pou rapòte yon pòs, agiman, oswa itilizatè:
• Tape menu twa pwen (⋯) sou nenpòt pòs oswa pwofil → Rapòte → chwazi yon kategori.
• Imel: support@granboulva.com`,
        },
        {
          title: "Appeals / Apèl",
          content: `If you believe a moderation action was taken in error, you may appeal within 30 days of the action.

To appeal:
• Email support@granboulva.com with your username, the content or action in question, and your reason for appeal.
• Appeals are reviewed by a senior moderator not involved in the original decision within 14 days.
• The appeal decision is final.

Si ou kwè yon aksyon moderasyon te fèt nan erè, ou ka fè apèl nan 30 jou apre aksyon an.`,
        },
        {
          title: "Contact / Kontak",
          content: `Moderation team: support@granboulva.com
Appeals: support@granboulva.com
Child safety: support@granboulva.com

Gran Boulva — granboulva.com`,
        },
      ]}
    />
  );
}
