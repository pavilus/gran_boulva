# Gran Boulva — Setup & iPhone Deployment Guide

## Prerequisites (all already met on your machine)
- Flutter 3.41.9 ✓
- Xcode installed ✓  
- iPhone connected (GPavilus, iOS 18.7.7) ✓
- Supabase account needed at https://supabase.com

---

## STEP 1: Create Your Supabase Project

1. Go to https://supabase.com → New Project
2. Name: `gran-boulva`
3. Database password: (save this!)
4. Region: pick closest to Haiti (us-east-1 or similar)
5. Wait ~2 minutes for project to initialize

---

## STEP 2: Run Database Migrations

In Supabase Dashboard → SQL Editor → New Query, run each file IN ORDER:

```
File 1: /Users/gpavilus/GranBoulva/supabase/migrations/001_schema.sql
File 2: /Users/gpavilus/GranBoulva/supabase/migrations/002_rls_policies.sql
File 3: /Users/gpavilus/GranBoulva/supabase/migrations/003_functions_triggers.sql
File 4: /Users/gpavilus/GranBoulva/supabase/migrations/004_seed_data.sql
```

Copy each file's contents and paste into the SQL Editor, then click "Run".

---

## STEP 3: Get Your Supabase Keys

1. Supabase Dashboard → Settings → API
2. Copy:
   - **Project URL** → `SUPABASE_URL`
   - **anon / public key** → `SUPABASE_ANON_KEY`

---

## STEP 4: Configure .env File

Edit `/Users/gpavilus/gran_boulva/.env`:

```
SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
STRIPE_PUBLISHABLE_KEY=pk_test_...
```

Replace the placeholder values with your real credentials.
For now you can leave `STRIPE_PUBLISHABLE_KEY` as `pk_test_placeholder` to test without payments.

---

## STEP 5: Deploy Supabase Edge Functions (Optional for MVP)

Install Supabase CLI if needed:
```bash
brew install supabase/tap/supabase
supabase login
supabase link --project-ref YOUR_PROJECT_REF
```

Deploy functions:
```bash
cd /Users/gpavilus/GranBoulva
supabase functions deploy create-user-profile
supabase functions deploy submit-vote-and-argument
supabase functions deploy get-home-feed
supabase functions deploy get-arguments
supabase functions deploy approve-ai-draft
supabase functions deploy boost-argument
supabase functions deploy create-coin-purchase
supabase functions deploy confirm-coin-purchase
supabase functions deploy get-notifications
supabase functions deploy close-expired-predictions

# Set secrets
supabase secrets set ANTHROPIC_API_KEY=sk-ant-...
supabase secrets set BRAVE_SEARCH_API_KEY=BSA...
supabase secrets set STRIPE_SECRET_KEY=sk_test_...
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=...
```

**Note:** The Flutter app has fallback queries that work without edge functions. You can skip this step for initial testing.

---

## STEP 6: Run on iPhone

Your iPhone (GPavilus) is already connected and trusted. Run:

```bash
cd /Users/gpavilus/gran_boulva
flutter run -d 00008030-001A41513A88C02E
```

Or simply (Flutter will find your iPhone):
```bash
cd /Users/gpavilus/gran_boulva
flutter run
```

The first build takes 3-5 minutes (compiling Swift/Objective-C). Hot reload works after that.

---

## STEP 7: Create Admin Account

1. Launch the app on your iPhone
2. Tap "Kreye yon kont" and create your account
3. In Supabase Dashboard → Table Editor → users
4. Find your row and change `role` from `user` to `admin`
5. The Admin Dashboard will now appear when you navigate to it

---

## STEP 8: Create First Matchup (as Admin)

The seed data already created 6 matchups. To create more:
1. Open the app → bottom nav → Profile → Menu
2. (Admin only) Tab bar shows Admin section
3. Or navigate directly to `/admin` in the app

---

## Common Issues

### Build fails with "No development team"
```bash
open /Users/gpavilus/gran_boulva/ios/Runner.xcworkspace
```
In Xcode: Runner → Signing & Capabilities → Team → Select your Apple ID

### "Could not find device"  
Make sure your iPhone is unlocked and trusted. Re-run:
```bash
flutter devices
```

### Supabase connection error
Check your .env file has the correct URL and anon key. Make sure there's no trailing slash on SUPABASE_URL.

### flutter_stripe error
If Stripe causes build failures during initial testing, comment out these lines in `main.dart`:
```dart
// Stripe.publishableKey = StripeConfig.publishableKey;
// await Stripe.instance.applySettings();
```

---

## Quick Commands Reference

```bash
# Run on iPhone
cd /Users/gpavilus/gran_boulva && flutter run

# Run with verbose output (shows build errors)
flutter run -v

# Hot reload (while app is running)
Press 'r' in terminal

# Hot restart (while app is running)
Press 'R' in terminal

# Build release IPA (for TestFlight)
flutter build ipa

# Clean build
flutter clean && flutter pub get && flutter run

# Check for issues
flutter doctor
flutter analyze
```
