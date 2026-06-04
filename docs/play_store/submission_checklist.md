# Gran Boulva — Google Play Store Submission Checklist

---

## 1. BEFORE YOU BUILD

- [ ] Confirm `pubspec.yaml` version is correct
  - Current: `version: 1.0.0+1` → versionName=1.0.0, versionCode=1
  - Each Play Store upload requires a unique, incremented versionCode
- [ ] Confirm `android/key.properties` exists and points to `gran-boulva-release.jks`
- [ ] Confirm `gran-boulva-release.jks` is in `android/` directory
- [ ] Back up `gran-boulva-release.jks` securely (losing this key = you can never update the app)

---

## 2. BUILD THE SIGNED APP BUNDLE

```bash
cd /Users/gpavilus/gran_boulva

# Clean first (recommended for release builds)
flutter clean && flutter pub get

# Build the signed AAB (preferred over APK for Play Store)
flutter build appbundle --release

# Output file: build/app/outputs/bundle/release/app-release.aab
```

> Upload `app-release.aab` to Play Console → Production (or Internal Testing first).

---

## 3. GRAPHICS ASSETS — STATUS

| Asset | Size | Status | File |
|-------|------|--------|------|
| App icon (high-res) | 512×512 PNG, RGBA | ✅ Ready | `docs/play_store/icon_512.png` |
| Feature graphic | 1024×500 PNG | ❌ **Needs creation** | — |
| Phone screenshots | Min 2, max 8 (portrait, min 1080px tall) | ❌ **Needs screenshots** | — |
| Tablet screenshots | Optional (7" and 10") | Optional | — |
| Promo video | Optional (YouTube URL) | Optional | — |

### Feature Graphic (1024×500)
Create a 1024×500 PNG banner for the Play Store page. It should:
- Use the dark purple/black brand colors (#A855F7 purple, #0a0a0f background)
- Show the Gran Boulva logo
- Include a tagline, e.g., "Platfòm Debat Sosyal Ayiti" or "Haiti's Debate Platform"
- Tools: Canva, Figma, or Photoshop

### Phone Screenshots (at least 2, up to 8)
Required dimensions: at least 1080×1920 px (or 1080×2340, etc. — any modern phone ratio)

Recommended screens to capture:
1. Home feed (matchup cards)
2. Matchup voting screen (A vs B)
3. Argument debate screen (post-vote)
4. Profile / badge screen
5. Predictions feed
6. Onboarding slide (optional)

**How to take screenshots:**
```bash
# List connected Android devices
flutter devices

# Run on a real Android device (use the Android device ID from flutter devices)
flutter run -d <android_device_id>

# OR launch an Android emulator and run on it
flutter emulators --launch <emulator_id>
flutter run -d <emulator_id>
# Screenshot: Android Studio → Device Manager → Camera icon, or adb exec-out screencap -p > screen.png
```

---

## 4. PLAY CONSOLE SETUP

### 4a. Create the app
- Go to https://play.google.com/console
- Click "Create app"
- App name: **Gran Boulva**
- Default language: **Haitian Creole (ht)** (add English as secondary)
- App or Game: **App**
- Free or Paid: **Free** (with in-app purchases)
- Agree to policies → Create app

### 4b. Store listing
Copy text from `docs/play_store/store_listing.md`:
- App name: Gran Boulva
- Short description (EN + HT)
- Full description (EN + HT)
- Upload graphics (icon, feature graphic, screenshots)
- Category: **Social**
- Email: your support email
- Website: https://granboulva.com
- Privacy policy URL: https://granboulva.com/privacy  ← **must exist before submission**

### 4c. App content
Complete every section in "App content" (required for review):
- **Privacy policy**: Must be a live URL
- **Ads**: No
- **App access**: Provide reviewer login credentials (test account)
- **Content ratings**: Complete the IARC questionnaire
  - User-generated content: YES
  - In-app purchases: YES
  - All violence/sexual/drugs: NO
- **Target audience**: 13+ (due to social/UGC features)
- **Data safety**: Fill out the form (see below)

### 4d. Data safety form
Gran Boulva collects:
| Data type | Collected | Shared | Purpose |
|-----------|-----------|--------|---------|
| Name | Yes | No | Account creation |
| Email | Yes | No | Auth, account management |
| User ID | Yes | No | Core functionality |
| Phone number | Yes | No | Profile/demographics |
| Date of birth | Yes | No | Profile/demographics |
| Country | Yes | No | Profile/demographics |
| Photos/videos | Yes | No | Avatar upload |
| App interactions | Yes | No | Personalized feed / recommendations |
| In-app purchase history | Yes | No | Coin transactions |

Encryption in transit: YES (Supabase uses HTTPS/TLS)
Users can request deletion: YES (add this to settings or support email)

### 4e. Pricing & distribution
- Free
- Countries: All (or start with Haiti + diaspora countries: US, Canada, France, Dominican Republic)
- Consent to US export laws

---

## 5. IN-APP PURCHASES — PAYMENT POLICY WARNING

⚠️ **Critical: Read before submitting**

Gran Boulva uses **Stripe** for coin purchases, not Google Play Billing.

**Google Play policy**: Digital goods sold inside an Android app must use Google Play Billing in most regions (Google takes 15–30%). There are narrow exceptions:

Options:
1. **Add Google Play Billing** alongside Stripe (dual-billing). Complex but compliant.
2. **Move coin purchases to web only** (`granboulva.com/coins`) and remove the in-app purchase screen from the Android build. Users tap "Buy coins on web" → browser → Stripe checkout → back to app. This bypasses Play Store fees entirely.
3. **Submit without in-app purchases first** (remove coin purchase screen from Android build, add note "coin purchases via website") and add it later once you've decided.

Recommended: **Option 2** — move purchases to web for Android. Add a "Buy on web" button in the coins screen that opens `granboulva.com/coins` in a browser.

---

## 6. RELEASE TRACK RECOMMENDATION

Do not go straight to Production. Use this track progression:

1. **Internal testing** (up to 100 testers) — same-day review, test the build
2. **Closed testing / Beta** (invited testers) — broader testing
3. **Open testing** (public beta, optional)
4. **Production** — full review (typically 1–3 days for first-time submissions)

---

## 7. BEFORE HITTING SUBMIT

- [ ] Privacy policy page live at `granboulva.com/privacy`
- [ ] Test account created for Play reviewers
- [ ] All "App content" sections completed (no red X icons in Play Console)
- [ ] Feature graphic uploaded (1024×500)
- [ ] At least 2 phone screenshots uploaded
- [ ] Data safety form completed
- [ ] In-app purchase / payment strategy decided (see Section 5)
- [ ] `app-release.aab` built and uploaded
- [ ] Release notes written (EN + HT) — see `store_listing.md`

---

## 8. BUILD VERIFICATION COMMANDS

```bash
# Verify signing
cd /Users/gpavilus/gran_boulva
flutter build appbundle --release 2>&1 | tail -5

# Check the output AAB
ls -lh build/app/outputs/bundle/release/app-release.aab

# Verify AAB is signed (requires bundletool or apksigner)
# jarsigner -verify -verbose build/app/outputs/bundle/release/app-release.aab
```

---

## FILES PREPARED IN THIS CHECKLIST

| File | Purpose |
|------|---------|
| `docs/play_store/store_listing.md` | All listing text (EN + HT), metadata, coin products |
| `docs/play_store/icon_512.png` | 512×512 app icon for Play Console upload |
| `docs/play_store/submission_checklist.md` | This file |
| `android/app/src/main/AndroidManifest.xml` | Updated with INTERNET, CAMERA, RECORD_AUDIO, notifications permissions |
