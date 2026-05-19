import LegalPage from "@/components/LegalPage";

export const metadata = { title: "Disclaimer — Gran Boulva" };

export default function DisclaimerPage() {
  return (
    <LegalPage
      title="Disclaimer"
      subtitle="Deklare / Disclaimer"
      effectiveDate="May 17, 2026"
      sections={[
        {
          title: "User-Generated Content / Kontni Itilizatè",
          content: `Gran Boulva is a platform for user-generated debate and opinion. All arguments, replies, votes, and predictions posted by users represent solely the views of the individual users who post them.

Gran Boulva does not endorse, verify, adopt, or take responsibility for any opinion, argument, claim, or statement made by its users. The presence of content on Gran Boulva does not constitute an endorsement of that content by Gran Boulva, its employees, officers, or affiliates.`,
        },
        {
          title: "No Professional Advice / Pa Konsèy Pwofesyonèl",
          content: `Nothing on Gran Boulva constitutes legal, financial, medical, psychological, or any other form of professional advice. Content on the platform — including matchups, arguments, and predictions — is provided for entertainment, debate, and community engagement purposes only.

Do not make legal, financial, health, or safety decisions based on content posted on Gran Boulva. Always consult a qualified professional for advice specific to your situation.`,
        },
        {
          title: "Predictions Are Entertainment Only / Prediksyon se pou Amizman Sèlman",
          content: `Gran Boulva's prediction markets are for entertainment purposes only. They do not constitute financial instruments, gambling, or any form of regulated wagering. Gran Boulva Coins used in predictions have no monetary value and cannot be redeemed for cash.

Past prediction outcomes on Gran Boulva do not guarantee future results. Gran Boulva makes no representation about the accuracy of any prediction.`,
        },
        {
          title: "AI-Generated Content / Kontni Jenere pa IA",
          content: `Gran Boulva uses artificial intelligence (OpenAI) to generate matchup ideas and content via the Scout feature. AI-generated content is reviewed by Gran Boulva administrators before publication, but we do not guarantee its accuracy, completeness, or fairness.

AI-generated matchup titles and descriptions are intended as prompts for debate, not as factual reporting. Users should independently verify any factual claims before relying on them.`,
        },
        {
          title: "External Links / Lyen Ekstèn",
          content: `Gran Boulva may display links to external websites (e.g., news sources that inspired a matchup). These links are provided for informational purposes only. Gran Boulva has no control over the content of external sites and accepts no responsibility for their content, privacy practices, or availability.`,
        },
        {
          title: "Availability of Service / Disponibilite Sèvis",
          content: `Gran Boulva is provided on an "as is" and "as available" basis. We do not guarantee uninterrupted or error-free operation of the platform. We reserve the right to modify, suspend, or discontinue any part of the Service at any time without notice.

Gran Boulva is not responsible for any loss of data, loss of Coins, or other harm resulting from service interruptions, downtime, or platform changes.`,
        },
        {
          title: "Limitation of Liability / Limit Responsabilite",
          content: `To the fullest extent permitted by applicable law, Gran Boulva shall not be liable for any direct, indirect, incidental, consequential, or punitive damages arising from your reliance on any content posted on the platform by users or by Gran Boulva's AI systems.

This disclaimer does not affect rights that cannot be excluded or limited under applicable law.`,
        },
        {
          title: "Contact / Kontakte Nou",
          content: `For questions about this Disclaimer:
Email: legal@granboulva.com`,
        },
      ]}
    />
  );
}
