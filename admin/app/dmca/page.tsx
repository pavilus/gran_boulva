import LegalPage from "@/components/LegalPage";

export const metadata = { title: "DMCA Policy — Gran Boulva" };

export default function DmcaPage() {
  return (
    <LegalPage
      title="DMCA Policy"
      subtitle="Règleman Dwa Otè / Copyright & DMCA Policy"
      effectiveDate="May 17, 2026"
      sections={[
        {
          title: "Overview / Apèsi",
          content: `Gran Boulva respects the intellectual property rights of others and expects our users to do the same. In accordance with the Digital Millennium Copyright Act of 1998 ("DMCA"), 17 U.S.C. § 512, Gran Boulva will respond to legitimate notices of copyright infringement and will remove or disable access to infringing content.

Gran Boulva has designated a DMCA Agent to receive notices of claimed infringement.`,
        },
        {
          title: "Designated DMCA Agent / Ajan DMCA Nou",
          content: `DMCA Agent: Gran Boulva Legal Team
Email: support@granboulva.com
Website: granboulva.com

All DMCA notices must be submitted in writing to the email address above.`,
        },
        {
          title: "How to File a Takedown Notice / Kijan pou Soumèt yon Notis",
          content: `If you believe content on Gran Boulva infringes your copyright, send a written notice to support@granboulva.com containing all of the following:

1. Identification of the copyrighted work: A description of the copyrighted work you claim has been infringed, or if multiple works are covered by a single notification, a representative list of such works.

2. Identification of the infringing material: A description of the material you claim is infringing and information reasonably sufficient to allow us to locate it (e.g., username, argument text, or URL).

3. Your contact information: Your name, address, telephone number, and email address.

4. Good faith statement: A statement that you have a good faith belief that the use of the material in the manner complained of is not authorized by the copyright owner, its agent, or the law.

5. Accuracy statement: A statement that the information in the notification is accurate and, under penalty of perjury, that you are authorized to act on behalf of the copyright owner.

6. Your physical or electronic signature.

Notices that do not include all required elements may not receive a response.`,
        },
        {
          title: "Counter-Notice Procedure / Pwosedi Kontrè-Notis",
          content: `If you believe content was removed from Gran Boulva as a result of a mistake or misidentification, you may file a counter-notice by sending a written statement to support@granboulva.com containing:

1. Identification of the removed material and the location where it appeared before it was removed.

2. A statement under penalty of perjury that you have a good faith belief that the material was removed or disabled as a result of mistake or misidentification.

3. Your name, address, and telephone number.

4. A statement that you consent to the jurisdiction of the Federal District Court for the judicial district in which your address is located (or, if outside the U.S., any judicial district in which Gran Boulva may be found), and that you will accept service of process from the person who provided the original DMCA notice.

5. Your physical or electronic signature.

Upon receiving a valid counter-notice, Gran Boulva will forward a copy to the original complainant and may restore the removed content no sooner than 10 and no later than 14 business days after receiving the counter-notice, unless our DMCA Agent receives notice that the complainant has filed an action seeking a court order to restrain infringement.`,
        },
        {
          title: "Repeat Infringer Policy / Règleman sou Kontrefaktè Reipete",
          content: `Gran Boulva has a policy of terminating, in appropriate circumstances, the accounts of users who are repeat infringers of intellectual property rights. We reserve the right to terminate any account upon receipt of a single DMCA notice if the circumstances warrant it.`,
        },
        {
          title: "User-Generated Content & Copyright / Kontni Itilizatè ak Dwa Otè",
          content: [
            "By posting content on Gran Boulva (arguments, replies, profile images), you represent that you own the content or have the rights to post it.",
            "Gran Boulva does not pre-screen user-generated content for copyright compliance. We act on valid DMCA notices after the fact.",
            "Matchup images and AI-generated content created by Gran Boulva's Scout system are sourced from public news and social media. We make good faith efforts to use only legitimately shareable material.",
          ],
        },
        {
          title: "Misrepresentation / Move Fwa",
          content: `Under 17 U.S.C. § 512(f), any person who knowingly materially misrepresents that material is infringing, or that material was removed by mistake, may be liable for damages, including costs and attorneys' fees.

Filing a false DMCA notice to suppress legitimate speech is a serious matter. Gran Boulva reserves the right to pursue legal remedies against anyone who submits fraudulent notices.`,
        },
        {
          title: "Contact / Kontakte Nou",
          content: `DMCA notices and counter-notices:
Email: support@granboulva.com

For all other questions:
Email: support@granboulva.com`,
        },
      ]}
    />
  );
}
