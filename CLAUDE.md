# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## What This Is
A Haitian-focused social debate & prediction app. Users vote on matchups (A vs B), post arguments, support each other with coins, and earn badges. Content is sourced from real-time Haitian news trends via an AI Scout. Haitian Creole is the primary language; English is secondary.

---

## Architecture Overview

| Layer | Tech |
|-------|------|
| Mobile app | Flutter 3.41.9, Riverpod (state), GoRouter (nav) |
| Backend | Supabase (Postgres + Auth + Storage + Edge Functions) |
| Payments | Stripe (Flutter Stripe 10.1.1 + Edge Functions) |
| AI | OpenAI GPT-4 + Search API (in `run-scout` Edge Function) |
| Admin dashboard | Next.js 16.2.6 + Supabase SSR (in `/admin/`) |

---

## Commands

```bash
# Deploy to iPhone (device ID is fixed — use flutter install, NOT flutter run in background)
# iOS 14+ debug apps only run while Flutter tooling is attached; install lets user tap to launch
flutter install --device-id 00008030-001A41513A88C02E

# Run with live reload (foreground only — do NOT background this)
flutter run -d 00008030-001A41513A88C02E

# Analyze for errors
flutter analyze

# Clean build (use when seeing Xcode/build cache issues)
flutter clean && flutter pub get

# Admin dashboard
cd admin && npm run dev

# Apply unapplied migrations to remote Supabase
supabase db push

# Deploy an edge function
supabase functions deploy <function-name>
```

---

## Project Structure

```
gran_boulva/
├── lib/
│   ├── main.dart                 # App entry: Supabase init, Stripe, orientation lock
│   ├── config/
│   │   ├── app_router.dart       # All routes (GoRouter, shell + bottom nav)
│   │   ├── app_theme.dart        # Dark theme only; primary purple #A855F7
│   │   └── app_colors.dart       # Color constants (bg0: #0a0a0f, etc.)
│   ├── models/
│   │   └── models.dart           # All data models (UserModel, MatchupModel, etc.)
│   ├── services/
│   │   └── supabase_service.dart # All business logic (12 service classes)
│   └── screens/                  # 27 screens total
├── supabase/
│   ├── migrations/               # Timestamped SQL migrations
│   └── functions/                # Deno Edge Functions (4 total)
├── admin/                        # Next.js admin dashboard (separate app)
│   ├── app/(dashboard)/          # Protected pages (matchups, scout, payments, etc.)
│   ├── app/login/                # Admin login page
│   └── components/Sidebar.tsx    # Collapsible sidebar with logo, user profile, logout
└── assets/
    ├── images/                   # logo.png, favicon.png, badge images, etc.
    └── icons/                    # SVG icons
```

---

## Navigation / Routes

Bottom navigation shell (4 tabs):
- `/home` → HomeScreen
- `/notifications` → NotificationsScreen
- `/profile` → ProfileScreen
- `/menu` → MenuScreen

Full-screen routes (no bottom nav):
- `/splash`, `/login`, `/create-account`, `/forgot-password`
- `/matchup/:id` — voting + arguments
- `/prediction/:id`
- `/user/:username` — public profile
- `/boost/:argumentId` → `/payment`
- `/coins`, `/invite`, `/badges`
- `/admin` — role-gated (requires `users.role = 'admin'`)
- `/personal-info`, `/security`, `/notification-settings`, `/help`

---

## Service Classes (`lib/services/supabase_service.dart`)

All 12 service classes live in a single file. Services use an **RPC-first pattern**: try Supabase RPC/edge function, fall back to direct table query.

| Class | Responsibility |
|-------|---------------|
| `AuthService` | Sign up/in/out, password reset |
| `UserService` | Profiles, avatars (`uploadAvatar` → stores full public URL), follows, top voices |
| `MatchupService` | Feed, categories, voting, arguments, saves |
| `ArgumentService` | CRUD, reactions, replies, visibility scoring, reports |
| `CoinService` | Balance, transactions, Stripe purchases, transfers |
| `BadgeService` | XP events, 10-level tiers |
| `PredictionService` | Feed, voting, deadline tracking |
| `NotificationService` | Get/mark/send — `send()` inserts into `notifications` table (fire-and-forget, no await needed) |
| `BoostService` | Boost arguments with credits or coins |
| `AdminService` | AI draft approval, matchup/prediction CRUD, category mgmt, user list |

---

## Database Schema Key Points

**users** — `auth_user_id` links to Supabase auth (use this for joins, not `id`). `avatar_url` stores a full public storage URL (returned by `getPublicUrl()`). `role` → `user` | `admin` | `moderator`.

**matchups** — `status` → `draft` | `published` | `closed` | `archived`

**matchup_options** — has `image_url` column (added in migration 000007). Stored in `matchup-images` bucket (public).

**arguments** — voter-gated: users can only see arguments after voting. Enforced via `get_matchup_arguments_for_voter()` RPC + RLS.

**Storage buckets** — both `avatars` and `matchup-images` are public with read policies. Service role manages matchup images; authenticated users manage avatars.

### Key DB Functions
- `get_matchup_arguments_for_voter()` — voter-gated argument visibility
- `record_badge_event()` — award badge XP
- `support_argument()` — coin transfer to argument author
- `transfer_coins()` — user-to-user transfer (with fee)
- `boost_argument()` — boost with credits or coins
- `get_recommended_home_feed()` — Phase 1 personalized home feed with interest/trending/diversity scoring
- `record_behavior_event()` — recommendation signal tracking; safe fire-and-forget from app services
- `submit_vote_and_argument_with_coins()` / `change_vote_with_coins()` — DB-enforced vote/argument spending rules
- `support_argument_checked()` — prevents self-support before calling support logic
- `get_daily_coin_claim_status()` / `claim_daily_coin_reward()` — secure daily coin claim and streak rewards

---

## Migration Naming — Critical Gotcha

Migrations use timestamp prefixes (`20260514000001_...`). **Timestamps must be unique.** If two migration files share the same timestamp, `supabase db push` only applies the first one alphabetically — the second is silently skipped. Always use a new unique timestamp when creating migrations.

Current applied migrations (in order):
```
20260514000001_...  schema
20260514000002_...  rls_policies
20260514000003_...  functions_triggers
20260514000004_...  seed_data
20260514000005_...  ai_drafts_enhanced_scores
20260514000006_...  (any gap)
20260514000007_arguments_visibility_and_matchup_images  — RPC + image_url column
20260514000008_storage_matchup_images_public           — public bucket policies
```

---

## Admin Dashboard (`/admin/`)

Separate Next.js 16.2.6 app with App Router. Supabase URL: `ewltfxsevaofqdooldkw.supabase.co`.

**Sidebar** (`components/Sidebar.tsx`): collapsible, shows logo (`/public/logo.png`), nav links, user profile picture (fetched from `users.avatar_url` via `auth_user_id`), display name, and logout button.

**Admin pages:**
| Route | Purpose |
|-------|---------|
| `/` | Overview dashboard |
| `/matchups` | Matchup list with column filters, sort, status tabs |
| `/scout` | Review AI-generated drafts (approve/reject) |
| `/payments` | Coin transactions + payment history |
| `/audit` | Moderation action logs |
| `/login` | Supabase auth login |

Admin users: set `users.role = 'admin'` in Supabase Table Editor after account creation.

**Current admin controls added later:**
- `/settings` includes Boulva coin economy controls: vote cost, argument cost, transfer fee, support amounts, coin packs, boost tiers, signup bonus, daily claim base, streak bonus, and daily claim max.
- `/settings` also includes recommendation controls: personalization ratio, discovery ratio, perspective ratio, freshness decay, trending weight, interest weight, and diversity weight.

---

## Edge Functions (Deno + TypeScript)

### `approve-ai-draft`
Input: `draft_id`, `action` (approve/reject), optional edits. On approve: creates `matchup` + 2 `matchup_options`.

### `create-coin-purchase`
Input: `coin_amount`, `usd_cents` (min $0.50). Creates Stripe PaymentIntent, inserts pending `coin_purchase`.

### `confirm-coin-purchase`
Input: `client_secret`. Verifies with Stripe, credits `coin_balance`, records `coin_transaction`.

### `run-scout`
Phase 1: parallel web searches targeting Haitian news sites. Phase 2: GPT-4 generates 25 drafts scored on 8 metrics, filters `uniqueness_score >= 6` + `safety_score >= 5`. Phase 3: inserts into `ai_generated_drafts` (status: `pending`).

---

## Environment Variables

### Flutter app (`.env` at project root)
```
SUPABASE_URL=https://ewltfxsevaofqdooldkw.supabase.co
SUPABASE_ANON_KEY=eyJ...
STRIPE_PUBLISHABLE_KEY=pk_test_...
```

### Admin dashboard (`admin/.env.local`)
```
NEXT_PUBLIC_SUPABASE_URL=https://ewltfxsevaofqdooldkw.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=...
SUPABASE_SERVICE_ROLE_KEY=...
```

### Edge Functions (Supabase Dashboard → Settings → Secrets)
```
SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY
STRIPE_SECRET_KEY
OPENAI_API_KEY
```

---

## Key Design Decisions

- **Voter-gated arguments:** Users cannot see arguments until they have voted — enforced at DB level.
- **Haitian Creole first:** All DB content has `_ht` and `_en` columns; UI defaults to `ht`.
- **Coin economy:** Purchased via Stripe, earned via referrals/admin/signup bonus/daily claim. Spent on boosts, argument support, and optionally voting/posting arguments. Transfers carry a fee. Admin controls live under `/admin/settings`.
- **Daily rewards:** Signup bonus defaults to 5 coins. Daily claim defaults to 2 coins, +1 streak bonus per consecutive day, capped at 10. Enforced by Supabase RPCs and tracked in `user_daily_coin_claims`.
- **Self-support blocked:** Users must not support their own arguments. UI hides the action and DB enforces via `support_argument_checked()`.
- **Recommendation Phase 1:** Home feed calls `get_recommended_home_feed()` first and falls back safely. The app records behavior events for matchup views, votes, argument posts, saves, likes, replies, follows, support, boosts, prediction votes, and notification clicks. Tables: `user_interests`, `user_behavior_events`, `content_recommendation_scores`, `trending_scores`.
- **AI Scout pipeline:** `run-scout` → `ai_generated_drafts` (pending) → admin approves → `approve-ai-draft` creates live matchup.
- **Boost visibility:** `boost_expires_at` timestamp on arguments; expired boosts lose elevated visibility automatically.
- **Border colors on argument cards:** Option A → purple, Option B → pink (defined in `AppColors`).
- **free_boost_credits column** on `users` table tracks free boosts; query with `.eq('auth_user_id', user.id)` not `.eq('id', user.id)`.

---

## Deployment Notes

- Supabase migrations can be pushed from local Codex with `supabase db push --linked`; this has been working.
- VPS admin deploy is currently manual because Codex cannot SSH non-interactively to `root@2.24.101.250` from this session.
- User performs VPS deploy manually:
```bash
cd /root/gran_boulva
git pull
cd admin
npm install
rm -rf .next
npm run build
pm2 restart gran-boulva-admin
```
- Do not commit security-sensitive files: `.env`, `.env.*`, `admin/.env.local`, `supabase/.temp/`, `.claude/settings.local.json`, `.next`, or `node_modules`.

---

## Platform Config

- **iOS device ID:** `00008030-001A41513A88C02E` (GPavilus)
- **Bundle ID (Android):** `com.granboulva.gran_boulva`
- **Orientation:** Portrait-only
- **Theme:** Dark only, primary purple `#A855F7`, background `#0a0a0f`

To fix Xcode "No development team" error:
```bash
open ios/Runner.xcworkspace
# Xcode → Runner → Signing & Capabilities → Team → select Apple ID
```

To fix Xcode timeout (CONFIGURATION_BUILD_DIR):
```bash
killall Xcode
flutter clean && flutter pub get
flutter install --device-id 00008030-001A41513A88C02E
```
