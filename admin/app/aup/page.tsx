import LegalPage from "@/components/LegalPage";

export const metadata = { title: "Acceptable Use Policy — Gran Boulva" };

export default function AupPage() {
  return (
    <LegalPage
      title="Acceptable Use Policy"
      subtitle="Règleman pou Bon Itilizasyon / Acceptable Use Policy"
      effectiveDate="May 17, 2026"
      sections={[
        {
          title: "Purpose / Bi",
          content: `Gran Boulva is a debate and prediction platform built around Haitian culture, news, sports, and entertainment. Our community thrives on honest, passionate, and respectful debate. This Acceptable Use Policy ("AUP") defines what behavior is and is not permitted on the platform.

This AUP is incorporated by reference into our Terms of Service. Violating this policy may result in content removal, account suspension, or permanent ban.`,
        },
        {
          title: "Hate Speech & Discrimination / Diskou Rayisab",
          content: [
            "You may not post content that attacks, dehumanizes, or calls for discrimination against any person or group based on race, ethnicity, national origin, religion, gender, sexual orientation, disability, or other protected characteristics.",
            "Haitian identity, culture, and diaspora communities are central to Gran Boulva. Content that demeans Haitian people, Haitian Creole, or any other cultural group is strictly prohibited.",
            "Debate is encouraged — hatred is not. Criticizing ideas, policies, or public figures is permitted; attacking people for who they are is not.",
          ],
        },
        {
          title: "Harassment & Threats / Asisman ak Menas",
          content: [
            "You may not target another user with repeated unwanted contact, insults, or hostile behavior.",
            "Threats of violence — direct or implied — against any person are prohibited.",
            "You may not post another person's private information (doxxing) such as home address, phone number, workplace, or family members without their consent.",
            "You may not encourage others to harass a specific person.",
          ],
        },
        {
          title: "Misinformation / Dezenfòmasyon",
          content: [
            "You may not deliberately post false factual claims presented as truth when you know them to be false and when the content could cause real-world harm.",
            "Predictions and opinions are permitted — factual fabrications are not.",
            "Content that falsely portrays the results of an ongoing matchup, election, or verified event to manipulate votes is prohibited.",
          ],
        },
        {
          title: "Spam & Manipulation / Spam ak Manipilasyon",
          content: [
            "You may not post the same argument, reply, or message repeatedly (spam).",
            "You may not use bots, scripts, or automated tools to vote, post arguments, or interact with the platform.",
            "You may not create multiple accounts to manipulate votes, influence scores, coin balances, or matchup outcomes.",
            "Coordinated inauthentic behavior — organizing groups to artificially boost or suppress content — is prohibited.",
            "Buying or selling Gran Boulva accounts, Coins, or influence scores through external channels is prohibited.",
          ],
        },
        {
          title: "Illegal Content / Kontni Ilegal",
          content: [
            "You may not post content that is illegal under applicable law, including but not limited to: child sexual abuse material (CSAM), content that facilitates terrorism or violence, and stolen or fraudulently obtained personal data.",
            "You may not use Gran Boulva to facilitate illegal transactions, money laundering, or financial fraud.",
            "You may not post content that infringes another person's copyright, trademark, or intellectual property rights. See our DMCA Policy (granboulva.com/dmca) for reporting procedures.",
          ],
        },
        {
          title: "Impersonation / Imèsonasyon",
          content: [
            "You may not impersonate any person (including other Gran Boulva users), public figure, celebrity, organization, or Gran Boulva itself.",
            "Parody and satire accounts are permitted only if the account name and bio clearly identify the account as parody.",
          ],
        },
        {
          title: "Graphic & Adult Content / Kontni Grafik",
          content: [
            "You may not post sexually explicit content, graphic violence, or gore.",
            "You may not post content designed to shock or disturb without any legitimate purpose.",
          ],
        },
        {
          title: "Enforcement / Aplikasyon Règleman",
          content: `Gran Boulva enforces this policy through a graduated response system:

Step 1 — Warning: A first violation (minor) results in a written warning and content removal.
Step 2 — Temporary Suspension: Repeated or more serious violations result in a temporary account suspension (24 hours to 30 days depending on severity).
Step 3 — Permanent Ban: Severe violations (hate speech, CSAM, doxxing, threats) or repeated policy violations after prior suspension result in a permanent ban with no refund of Coins.

Gran Boulva reserves the right to skip steps and permanently ban any account at its sole discretion for severe violations.

Reported content is reviewed by our moderation team. To report a violation, tap the "..." menu on any argument or matchup and select "Rapòte / Report".`,
        },
        {
          title: "Appeals / Apèl",
          content: `If you believe your content was removed or your account was suspended in error, you may appeal by emailing support@granboulva.com with the subject line "AUP Appeal" within 14 days of the enforcement action. Include your username and a description of why you believe the action was in error.

We will review appeals within 7 business days. Our decision on appeals is final.`,
        },
        {
          title: "Contact / Kontakte Nou",
          content: `To report a violation or for questions about this policy:
Email: support@granboulva.com`,
        },
      ]}
    />
  );
}
