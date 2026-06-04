import LegalPage from "@/components/LegalPage";

export const metadata = { title: "Cookie Policy — Gran Boulva" };

export default function CookiesPage() {
  return (
    <LegalPage
      title="Cookie Policy"
      subtitle="Règleman sou Koki / Cookie Policy"
      effectiveDate="May 17, 2026"
      sections={[
        {
          title: "What Are Cookies / Kisa Koki Ye",
          content: `Cookies are small text files stored on your device by a website or application when you visit it. They help websites remember information about your visit, such as your login status and preferences.

This policy explains how Gran Boulva uses cookies on its website (granboulva.com). The Gran Boulva mobile app uses equivalent technologies (secure local storage and session tokens) which are covered by the same principles.`,
        },
        {
          title: "Cookies We Use / Koki Nou Itilize",
          content: `Gran Boulva uses only essential cookies — we do not use advertising cookies or third-party tracking pixels.

Essential / Strictly Necessary Cookies:
These cookies are required for the website to function. They cannot be disabled.

• sb-access-token — Supabase authentication session token. Keeps you logged in to the admin dashboard. Expires when you log out or after the session timeout.
• sb-refresh-token — Supabase token used to refresh your session automatically. Expires after 60 days of inactivity.
• sb-auth-event — Short-lived cookie used by Supabase to coordinate auth state between browser tabs. Expires within seconds.

No advertising, analytics, or social media tracking cookies are used on granboulva.com.`,
        },
        {
          title: "Mobile App Local Storage / Estokaj Lokal nan Aplikasyon",
          content: `The Gran Boulva mobile app stores the following data locally on your device using Flutter's secure storage and SharedPreferences:

• Authentication tokens (encrypted, managed by Supabase Flutter SDK) — used to keep you logged in.
• Language preference (Haitian Creole or English) — stored in SharedPreferences and synced to your user profile.
• Onboarding completion state — a flag indicating whether you have completed app onboarding.

This data is stored locally on your device and is not shared with third parties. It is deleted when you log out or uninstall the app.`,
        },
        {
          title: "Third-Party Services / Sèvis Tyes Pati",
          content: [
            "Supabase: sets authentication cookies necessary to manage your login session. Supabase's privacy policy applies to data processed by their infrastructure.",
            "Stripe: if you make a coin purchase, Stripe may set cookies on their payment pages to prevent fraud and process your payment securely. Stripe's cookie policy applies on Stripe-hosted pages.",
            "Gran Boulva does not use Google Analytics, Facebook Pixel, or any advertising network cookies.",
          ],
        },
        {
          title: "Managing Cookies / Jere Koki Yo",
          content: `You can control cookies through your browser settings:

• Chrome: Settings → Privacy and security → Cookies and other site data
• Safari: Preferences → Privacy → Manage Website Data
• Firefox: Settings → Privacy & Security → Cookies and Site Data
• Edge: Settings → Cookies and site permissions

Note: disabling essential cookies will prevent you from logging into the Gran Boulva admin dashboard. The mobile app does not rely on browser cookies.

To clear local app data on your phone, go to your device's app settings and select "Clear Data" or uninstall and reinstall the app.`,
        },
        {
          title: "Changes to This Policy / Chanjman",
          content: `We will update this Cookie Policy if we introduce new technologies or change our use of existing ones. Changes will be posted on this page with an updated effective date.

Contact: support@granboulva.com`,
        },
      ]}
    />
  );
}
