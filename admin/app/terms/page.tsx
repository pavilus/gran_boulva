import LegalPage from "@/components/LegalPage";

export const metadata = { title: "Terms of Service — Gran Boulva" };

export default function TermsPage() {
  return (
    <LegalPage
      title="Terms of Service"
      subtitle="Tèm ak Kondisyon / Terms of Service"
      effectiveDate="May 17, 2026"
      sections={[
        {
          title: "Acceptance of Terms / Akseptasyon Tèm Yo",
          content: `By creating an account or using the Gran Boulva application (the "Service"), you agree to be bound by these Terms of Service ("Terms"). If you do not agree, do not use the Service.

Gran Boulva is operated by Gran Boulva ("we", "us", "our"). These Terms constitute a legally binding agreement between you and Gran Boulva. We may update these Terms from time to time; continued use of the Service after changes are posted constitutes your acceptance.`,
        },
        {
          title: "Eligibility / Kondisyon pou Itilize",
          content: [
            "You must be at least 13 years old to use Gran Boulva. If you are under 16 and located in the European Union, you must have verifiable parental consent.",
            "By creating an account, you represent that all information you provide is accurate, current, and complete.",
            "You may not create more than one account. Creating duplicate accounts to evade a suspension or ban is prohibited.",
            "Accounts are personal and non-transferable. You may not sell, gift, or transfer your account to another person.",
          ],
        },
        {
          title: "Account Responsibilities / Responsabilite Kont Ou",
          content: `You are responsible for maintaining the confidentiality of your login credentials and for all activity that occurs under your account.

You agree to:
• Choose a username that does not impersonate another person or entity.
• Notify us immediately at support@granboulva.com if you suspect unauthorized access to your account.
• Not share your password with anyone.

Gran Boulva is not liable for any loss or damage arising from your failure to safeguard your account credentials.`,
        },
        {
          title: "The Gran Boulva Platform / Platfòm Gran Boulva",
          content: `Gran Boulva is a social debate and prediction platform focused on Haitian culture, news, sports, and entertainment. The Service allows users to:

• Vote on matchups (A vs. B debate topics).
• Post arguments in support of their chosen side.
• React to and reply to other users' arguments.
• Vote on and discuss prediction markets (future events).
• Earn and spend Gran Boulva Coins.
• Earn badges and build influence through participation.

Gran Boulva does not endorse any opinion, argument, or prediction posted by its users.`,
        },
        {
          title: "Gran Boulva Coins / Monnen Gran Boulva",
          content: [
            "Gran Boulva Coins ('Coins') are a virtual in-app currency used to boost arguments, support other users' arguments, and transfer between users.",
            "Coins have no monetary value and cannot be exchanged for cash, goods, or services outside the Gran Boulva platform.",
            "Coins are purchased through the in-app store via Stripe. All purchases are final and non-refundable except where required by applicable law.",
            "Gran Boulva reserves the right to modify the price, availability, or functionality of Coins at any time.",
            "Coins in your account may be forfeited without refund if your account is terminated for violating these Terms.",
            "Coins cannot be transferred or used outside of Gran Boulva and have no value if the Service is discontinued.",
          ],
        },
        {
          title: "User-Generated Content / Kontni Itilizatè",
          content: `You retain ownership of the content you post on Gran Boulva (arguments, replies, profile information). By posting content, you grant Gran Boulva a worldwide, non-exclusive, royalty-free license to use, display, reproduce, adapt, and distribute your content in connection with operating and promoting the Service.

You represent and warrant that:
• You own or have the right to post the content.
• Your content does not infringe any third-party intellectual property rights.
• Your content complies with our Acceptable Use Policy.

You may delete your arguments or replies at any time. Deleted content will be removed from display, though copies may persist in backups for a limited period.`,
        },
        {
          title: "Prohibited Conduct / Konpòtman Entèdi",
          content: `You agree not to:
• Violate any applicable local, national, or international law or regulation.
• Post content that violates our Acceptable Use Policy (granboulva.com/aup).
• Attempt to gain unauthorized access to any part of the Service or its infrastructure.
• Interfere with or disrupt the integrity or performance of the Service.
• Use automated scripts, bots, or scraping tools on the Service without prior written consent.
• Reverse engineer, decompile, or disassemble any part of the Service.
• Use the Service to transmit spam, phishing attempts, or unsolicited advertising.
• Manipulate votes, coins, or influence scores through fraudulent means.

Violations may result in immediate account suspension or permanent ban without refund of any Coins.`,
        },
        {
          title: "Termination / Fèmti Kont",
          content: `Gran Boulva may suspend or permanently terminate your account at any time, with or without notice, for:
• Violation of these Terms or our Acceptable Use Policy.
• Conduct we determine is harmful to other users, third parties, or Gran Boulva.
• Extended inactivity (accounts inactive for 24+ months may be purged).

You may delete your account at any time from the app settings. Upon deletion, your profile and personal data will be removed in accordance with our Privacy Policy.

Sections of these Terms that by their nature should survive termination (including intellectual property, disclaimers, and limitation of liability) will survive.`,
        },
        {
          title: "Disclaimers / Negasyon Responsabilite",
          content: `THE SERVICE IS PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTIES OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT.

Gran Boulva does not warrant that:
• The Service will be uninterrupted, timely, secure, or error-free.
• Any content on the Service is accurate, reliable, or complete.
• Any defects in the Service will be corrected.

User opinions, predictions, and arguments are solely those of the users who post them and do not represent the views of Gran Boulva.`,
        },
        {
          title: "Limitation of Liability / Limit Responsabilite",
          content: `TO THE MAXIMUM EXTENT PERMITTED BY LAW, GRAN BOULVA AND ITS OFFICERS, DIRECTORS, EMPLOYEES, AND AGENTS SHALL NOT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, INCLUDING LOSS OF DATA, LOSS OF PROFITS, OR LOSS OF GOODWILL, ARISING FROM YOUR USE OF OR INABILITY TO USE THE SERVICE.

IN NO EVENT WILL GRAN BOULVA'S TOTAL LIABILITY TO YOU EXCEED THE GREATER OF (A) THE AMOUNT YOU PAID TO GRAN BOULVA IN THE 12 MONTHS PRECEDING THE CLAIM, OR (B) $100 USD.`,
        },
        {
          title: "Governing Law / Lwa ki Aplike",
          content: `These Terms are governed by and construed in accordance with the laws of the State of Florida, United States, without regard to its conflict-of-law provisions.

Any dispute arising from these Terms or your use of the Service shall be resolved by binding individual arbitration under the rules of the American Arbitration Association (AAA), except that either party may seek injunctive relief in a court of competent jurisdiction to prevent irreparable harm.

YOU WAIVE YOUR RIGHT TO PARTICIPATE IN A CLASS ACTION LAWSUIT OR CLASS-WIDE ARBITRATION.`,
        },
        {
          title: "Contact / Kontakte Nou",
          content: `For questions about these Terms, contact us at:

Email: legal@granboulva.com
Platform: granboulva.com`,
        },
      ]}
    />
  );
}
