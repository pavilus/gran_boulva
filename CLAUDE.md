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
| Backend | Supabase (Postgres + Auth + Storage + Realtime + Edge Functions) |
| Payments | Stripe (Flutter Stripe 10.1.1 + Edge Functions) |
| AI | OpenAI GPT-4 + Search API (in `run-scout` Edge Function) |
| Live video | Agora RTC (`agora_rtc_engine ^6.5.4` added to pubspec — **does not work on simulator**, real device only) |
| Recording storage | AWS S3 (`gran-boulva-battle-recordings` bucket, 24h lifecycle rule, **not yet created**) |
| Admin dashboard | Next.js 16.2.6 + Supabase SSR (in `/admin/`) |

---

## Commands

```bash
# ✅ PREFERRED: Run on iOS simulator (faster, no cable, easy reset)
# NOTE: agora_rtc_engine crashes on simulator (objective_c.dylib missing) — non-fatal,
# rest of app works. For battle video testing, use real device only.
flutter run -d iphone

# Boot a specific simulator by UDID if needed
xcrun simctl boot 90DD1705-B0B6-42A0-A7A8-4DF82E6C671A  # iPhone 17 Pro

# Deploy to real iPhone (debug — cannot launch from home screen on iOS 14+)
flutter install --device-id 00008030-001A41513A88C02E

# Deploy to real iPhone as RELEASE (stays after unplug, launchable from home screen)
# IMPORTANT: always build first, then install — flutter install --release alone fails silently
flutter build ios --release
flutter install --device-id 00008030-001A41513A88C02E --release

# Hot reload on real iPhone (attach to already-running debug build)
# 1. flutter install (debug, above)  2. Tap icon via Xcode or flutter run  3. attach:
flutter attach -d 00008030-001A41513A88C02E

# Run on real iPhone with live reload (foreground only — do NOT background this)
# WARNING: often hangs on "Installing and launching..." — prefer flutter install + attach
flutter run -d 00008030-001A41513A88C02E

# Run with Agora App ID (required for battle video — no-op if empty string)
flutter run -d 00008030-001A41513A88C02E --dart-define=AGORA_APP_ID=your_app_id_here

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
│   │   ├── app_colors.dart       # Color constants (bg0: #0a0a0f, etc.)
│   │   ├── auth_redirects.dart   # Deep-link URI: granboulva://auth-callback
│   │   └── supabase_config.dart  # Supabase project constants
│   ├── models/
│   │   └── models.dart           # All data models (UserModel, MatchupModel, etc.)
│   ├── services/
│   │   └── supabase_service.dart # All business logic (12 service classes)
│   └── screens/                  # 31 screens + 7 battle screens (built, hidden)
├── supabase/
│   ├── migrations/               # Timestamped SQL migrations
│   └── functions/                # Deno Edge Functions (4 core live + 4 battle live)
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
- `/splash`, `/onboarding`, `/login`, `/create-account`, `/forgot-password`
- `/matchups` — full matchup feed
- `/predictions` — full predictions feed
- `/matchup/:id` — voting + arguments
- `/prediction/:id`
- `/user/:username` — public profile
- `/boost/:argumentId` → `/payment`
- `/coins`, `/invite`, `/badges`
- `/saved` — saved matchups
- `/recent-activity` — user activity history
- `/my-statistics` — user stats dashboard
- `/top-voices` — top voice users list
- `/subscriptions` — follow/following management
- `/settings` — app settings
- `/admin` — role-gated (requires `users.role = 'admin'`)
- `/personal-info`, `/security`, `/notification-settings`, `/help`
- `/challenge/:opponentId` → `BattleChallengeScreen` (built; entry point hidden until battles go live)

**Debate Battle routes (built, accessible via direct URL):**
- `/battle/:id` — smart dispatcher: routes to correct sub-screen based on `debate_battles.status` + user role
- `/battle/:id/incoming` — opponent accept/decline screen
- `/battle/:id/lobby` — camera check + ready up
- `/battle/:id/live` — live battle (Agora video + voting)
- `/battle/:id/result` — winner reveal, coins, badges
- `/battle/:id/replay` — HLS video replay (expires 24h after battle ends)

---

## Current Product State / Recent Work

- **Coin packages live:** Store packs are `100, 250, 550, 1200, 2500, 5000, 10000, 25000`. `create-coin-purchase` validates the selected package against `app_settings.coinPacks` before creating Stripe PaymentIntents.
- **Supabase service-role access:** `admin/.env.local` uses the rotated `SUPABASE_SERVICE_ROLE_KEY` (`sb_secret_...`). `app_settings` grants were added for `service_role` plus authenticated reads.
- **Follow system activated:** `public.follows` is live with RLS, RPCs `follow_user(uuid)` and `unfollow_user(uuid)`, follower/following counters, and follow notifications. Flutter follow/unfollow calls should use the RPCs, not direct table writes.
- **Notifications activated:** `/notifications` loads notification rows. Routing by `related_table`: `matchups` → `/matchup/:id`, `arguments` → `/matchup/:matchupId`, `users` → `/user/:username`, `debate_battles` → `/battle/:id/incoming` (or `/result` for `battle_result` type), `badges` → `/badges`, `coin_transactions` → `/coins`.
- **Abòneman activated:** `/subscriptions` exists and is reachable from the menu item `Abòneman`. It shows `M ap swiv` and `Abònen mwen`, supports pull-to-refresh, profile taps, and follow/unfollow.
- **Public user profiles activated:** `/user/:username` is the public profile page. Home `Tòp Vwa`, debate argument authors, reply authors, notifications, and subscription lists route into it. Public profile hides the follow button on the signed-in user's own profile and updates follower counts locally after follow/unfollow.
- **Top voices now use live users:** Home calls `UserService.getTopVoices(limit: 8)`. The fallback image list is indexed with modulo because live top voices can exceed the number of bundled fallback avatars.
- **Onboarding flow:** `/onboarding` screen (5 slides: Debat, Vote, Agimante, Prediksyon, Enfliyans). First-launch detection via `SharedPreferences`. Shown once before login.
- **Auth signup with auto-profile creation:** `handle_new_auth_user()` DB trigger fires on `auth.users` insert, creates the public `users` row from `raw_user_meta_data` (username, full_name, language, referral_code, gender, date_of_birth, country, phone_number). Raises `USERNAME_INVALID` or `USERNAME_TAKEN` on conflict.
- **Username availability check:** `is_username_available(text)` RPC callable by `anon` and `authenticated` — use for real-time validation in the create-account form.
- **User demographics added:** `users` table now has `gender`, `date_of_birth`, `country`, `phone_number` columns.
- **Email system live:** Tables `email_messages`, `email_templates`, `email_settings` are in DB. Admin `/email` page manages outbound/inbound messages and templates. SMTP via IONOS (`SMTP_HOST`, `SMTP_USER`, `SMTP_PASS` secrets).
- **Recommendation Phase 1:** Home feed calls `get_recommended_home_feed()` first and falls back safely. Behavior events recorded for matchup views, votes, argument posts, saves, likes, replies, follows, support, boosts, prediction votes, and notification clicks. Tables: `user_interests`, `user_behavior_events`, `content_recommendation_scores`, `trending_scores`.
- **Verification system live:** `verification_requests` + `user_verifications` tables. Types: `standard` | `public_figure` | `organization` | `trusted_creator` | `admin`. Admin reviews via admin dashboard.
- **Creator tier system live:** `creator_profiles` table with tiers 0–4. Score auto-calculated by `calculate_creator_score()`. Tiers 0→1→2 auto-upgrade via `refresh_creator_tier()`. Tiers 3–4 require admin confirmation. See Creator Tier System section below.
- **Creator revenue sharing live:** `creator_revenue_events` + `creator_payouts` tables. `record_creator_revenue()` and `refresh_creator_tier()` RPCs. MonCash payout support (sandbox). `coinToUsdRate: 0.001` in `app_settings`.
- **Cosmetics system live:** User cosmetics (frames, effects, etc.) in DB. `get_equipped_cosmetics()` RPC.
- **Streak recovery system live:** Users can recover broken streaks.
- **Waitlist table live:** `waitlist` table for pre-launch signups.
- **Debate Battle feature — built, hidden:** All infrastructure is live (DB tables, Edge Functions, 7 Flutter screens, notification types). The entry point (`⚔️ 1 vs 1` button on public profiles) is hidden pending full testing. To reactivate: add `_myCreatorTier` field, `CreatorService().getMyProfile()` fetch, and the button widget back to `public_profile_screen.dart`. See Debate Battle Feature section below.
- **iOS permissions:** `NSCameraUsageDescription` (battles + avatar) and `NSMicrophoneUsageDescription` (battles) both set in `ios/Runner/Info.plist`.

---

## Service Classes (`lib/services/supabase_service.dart`)

All 12 service classes live in a single file. Services use an **RPC-first pattern**: try Supabase RPC/edge function, fall back to direct table query.

| Class | Responsibility |
|-------|---------------|
| `AuthService` | Sign up/in/out, password reset |
| `UserService` | Profiles, avatars (`uploadAvatar` → stores full public URL), follows, top voices |
| `MatchupService` | Feed, categories, voting, arguments, saves |
| `RecommendationService` | Personalized feed scoring, behavior event recording |
| `ArgumentService` | CRUD, reactions, replies, visibility scoring, reports |
| `CoinService` | Balance, transactions, Stripe purchases, transfers |
| `BadgeService` | XP events, 10-level tiers |
| `PredictionService` | Feed, voting, deadline tracking |
| `NotificationService` | Get/mark/send — `send()` inserts into `notifications` table (fire-and-forget, no await needed) |
| `BoostService` | Boost arguments with credits or coins |
| `AdminService` | AI draft approval, matchup/prediction CRUD, category mgmt, user list |
| `BattleService` | Challenge flow, Agora tokens, battle state, recording, rewards — **built and deployed** |

---

## Database Schema Key Points

**users** — `auth_user_id` links to Supabase auth (use this for joins, not `id`). `avatar_url` stores a full public storage URL (returned by `getPublicUrl()`). `role` → `user` | `admin` | `moderator`. Demographics: `gender`, `date_of_birth`, `country`, `phone_number`. `victory_count` and `participation_count` track debate battle history (already exist, used by `calculate_creator_score()`).

**matchups** — `status` → `draft` | `published` | `closed` | `archived`

**matchup_options** — has `image_url` column (added in migration 000007). Stored in `matchup-images` bucket (public).

**arguments** — voter-gated: users can only see arguments after voting. Enforced via `get_matchup_arguments_for_voter()` RPC + RLS.

**email_messages / email_templates / email_settings** — email system tables for outbound/inbound email management.

**creator_profiles** — one row per user: `creator_tier` (0–4), `creator_score` (0–100), `is_monetization_enabled`, `revenue_share_rate`, lifetime coin counters.

**verification_requests / user_verifications** — verification request + admin approval workflow.

**Storage buckets** — `avatars` and `matchup-images` are public. `verification-documents` is private (owner + admin only).

**Debate battle tables (live in DB):**
- `debate_battles` — one row per battle: mode, status, timer, Agora tokens, recording URL
- `battle_round_log` — per-speaker round turns (Full Debate mode only)
- `battle_audience_votes` — final winner vote (UNIQUE per voter per battle)
- `battle_extension_votes` — mid-battle "continue?" vote (UNIQUE per voter per battle)

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
- `handle_new_auth_user()` — trigger: auto-creates `users` row from `raw_user_meta_data` on Supabase auth signup
- `is_username_available(text)` — callable by `anon`/`authenticated`; validates format + uniqueness
- `calculate_creator_score(user_id)` — returns 0–100 score (badges 30pts, engagement 20pts, followers 20pts, consistency 15pts, reputation 10pts, debate performance 5pts)
- `refresh_creator_tier(user_id)` — recalculates score, auto-upgrades tiers 0→1→2, notifies user in Haitian Creole
- `lock_coins_for_battle(p_user_id, p_amount)` — atomic coin deduction; returns `true` if succeeded, `false` if insufficient balance (no race condition)
- `credit_coins(p_user_id, p_amount)` — atomic coin credit (used for battle prizes and refunds)

---

## Creator Tier System

Tiers live in `creator_profiles`. `refresh_creator_tier()` is called after any significant activity change.

| Tier | Name (HT) | Unlock condition | Revenue share | Debate access |
|------|-----------|-----------------|--------------|--------------|
| 0 | Itilizatè (User) | Default | 0% | ❌ None |
| 1 | Kreyatè Monte (Rising) | score ≥ 15 AND followers ≥ 10 — **automatic** | 60% | ⚡ Rapid Fire |
| 2 | Kreyatè Verifye (Verified) | Approved verification + score ≥ 35 | 70% | 🎙️ Full Debate + Rapid Fire |
| 3 | Kreyatè Elit (Elite) | score ≥ 70 + admin confirmation | 80% | All |
| 4 | Ikòn Kiltirèl (Cultural Icon) | Admin-only grant | Custom | All |

**Debate Battle tier gate:**
- ⚡ **Rapid Fire (5 min)** → Tier 1+ required for **both** challenger and opponent
- 🎙️ **Full Debate (10 min, structured)** → Tier 2+ required for **both** debaters
- Gate enforced server-side in Edge Function + client-side (entry point hidden until feature goes live)

---

## Debate Battle Feature

**Status: Infrastructure fully built and deployed. Entry point hidden pending full testing.**

### What is live
- DB tables: `debate_battles`, `battle_round_log`, `battle_audience_votes`, `battle_extension_votes`
- Notification types: `battle_challenge`, `battle_accepted`, `battle_result` in `notification_type` enum
- 4 Edge Functions deployed: `create-debate-battle`, `accept-debate-battle`, `start-battle-recording`, `end-battle`
- 7 Flutter screens built: `BattleChallengeScreen`, `BattleIncomingScreen`, `BattleLobbyScreen`, `BattleLiveScreen`, `BattleResultScreen`, `BattleReplayScreen`, `BattleScreen` (dispatcher)
- `BattleChallengeScreen` loads 5 hot matchups as selectable topics; user can also type a custom topic
- `BattleLiveScreen` uses `agora_rtc_engine` with `AgoraVideoView`; falls back to avatar placeholder if Agora not initialized
- `BattleReplayScreen` uses `video_player` for HLS playback with scrub bar
- Notifications screen routes `battle_challenge`/`battle_accepted` → `/battle/:id/incoming`, `battle_result` → `/battle/:id/result`

### What is NOT yet done (Agora + AWS)
1. Create Agora account → new project → get App ID + App Certificate
2. Add `AGORA_APP_ID` + `AGORA_APP_CERTIFICATE` to Supabase Edge Function secrets
3. Enable Cloud Recording on Agora dashboard
4. Create S3 bucket `gran-boulva-battle-recordings` with 24h object lifecycle rule
5. Create IAM user with S3 write access → give credentials to Agora Cloud Recording
6. Add `AGORA_APP_ID` to `--dart-define` when running (`--dart-define=AGORA_APP_ID=...`)

### To reactivate the ⚔️ 1 vs 1 entry point
In `public_profile_screen.dart`, add back to state:
```dart
int _myCreatorTier = 0;
```
Add to the `Future.wait([...])` in `_loadProfile()`:
```dart
CreatorService().getMyProfile(),
```
Set the field in `setState`:
```dart
_myCreatorTier = (results[3] as CreatorProfileModel?)?.creatorTier ?? 0;
```
Add button after the follow button (inside `if (!_isOwnProfile)` row):
```dart
if (_myCreatorTier >= 1 && !_isOwnProfile) ...[
  const SizedBox(width: 10),
  GestureDetector(
    onTap: () => context.go('/challenge/${_profile!.id}'),
    child: Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('⚔️', style: TextStyle(fontSize: 16)),
          SizedBox(width: 6),
          Text('1 vs 1', style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'Poppins',
          )),
        ],
      ),
    ),
  ),
],
```

### Modes

| Mode | Duration | Structure | Tier gate |
|------|----------|-----------|----------|
| ⚡ Rapid Fire | 5 min (+ 1× 2-min extension) | Free-for-all, both mics open | Tier 1+ |
| 🎙️ Full Debate | ~8.5 min (+ 1× bonus round) | Structured rounds, auto-mute | Tier 2+ |

**Full Debate rounds:**
1. Opening (Ouvertura): A 45s → B 45s
2. Main Argument (Agiman): A 90s → B 90s
3. Rebuttal (Repons): B 60s → A 60s ← reversed order
4. Closing (Klotin): A 45s → B 45s

**Audience extension vote:** triggered at 4:30 (Rapid Fire) or 9:30 (Full Debate). 10-second window. Threshold: 60%+ Yes AND minimum viewer count (200 for Rapid Fire, 500 for Full Debate). Max 1 extension per battle.

**End of battle:** 30-second audience winner vote → coins distributed (pool → winner 90%, platform 10%) → `record_badge_event()` + `refresh_creator_tier()` for both debaters → feed card posted → recording saved with 24h expiry.

**Supabase Realtime:** Each battle uses channel `battle:{battle_id}`. All debaters + audience subscribe. Events: `status_changed`, `round_advanced`, `extension_vote_open`, `extension_result`, `audience_vote_open`, `battle_result`, `reaction`, `coin_rain`.

**Timer authority:** `debate_battles.round_ends_at` is server-side source of truth. `pg_cron` advances Full Debate rounds server-side every 30s. Clients countdown locally and re-sync on rejoin.

**Agora simulator limitation:** `agora_rtc_engine` crashes on iOS Simulator (`objective_c.dylib` not available). Non-fatal — the app continues running, video tiles show avatar placeholder. All non-video screens work normally on simulator. Video testing requires real device only.

---

## Migration Naming — Critical Gotcha

Migrations use timestamp prefixes (`20260514000001_...`). **Timestamps must be unique.** If two migration files share the same timestamp, `supabase db push` only applies the first one alphabetically — the second is silently skipped. Always use a new unique timestamp when creating migrations.

Current applied migrations (in order):
```
20260514000000_grant_users_table_permissions
20260514000001_votes_add_vote_changed
20260514000002_ai_drafts_add_combined_score
20260514000003_grant_admin_table_permissions
20260514000004_ai_drafts_add_image_urls
20260514000005_ai_drafts_enhanced_scores
20260514000006_grant_users_insert
20260514000007_arguments_visibility_and_matchup_images    — RPC + image_url column
20260514000008_storage_matchup_images_public              — public bucket policies
20260514000009_ai_drafts_add_deadline
20260518000600_restore_active_argument_visibility
20260518002000_email_system                               — email_messages/templates/settings tables
20260519001000_coin_economy_settings
20260519002000_coin_spending_rules
20260519003000_prevent_self_support
20260519004000_daily_coin_rewards
20260519005000_recommendation_phase_one
20260519006000_restore_coin_packs_with_starter
20260519007000_follow_notifications_activation
20260519008000_auth_signup_profile_creation               — handle_new_auth_user trigger
20260519008100_coin_transaction_type_expansion
20260519008200_notification_type_expansion
20260519008300_username_availability_rpc                  — is_username_available() RPC
20260519008400_user_profile_demographics                  — gender/dob/country/phone columns
20260519008500_category_icon_pngs
20260519008600_category_icon_pngs_extended
20260519008700_verification_system                        — verification_requests + user_verifications
20260519008800_verification_grant_fix
20260519008900_creator_revenue_system                     — creator_profiles + revenue sharing
20260519009000_payout_settings                            — MonCash payout support
20260519009100_coin_economy_v2                            — refresh_creator_tier, record_creator_revenue
20260519009200_badge_names_icons_thresholds
20260519009300_badge_event_reference_keys
20260519009400_boost_ranking_system
20260519009500_predictions_authenticated_access
20260519009600_fix_home_feed_duplicates
20260519009700_prediction_votes_total_count
20260519009800_fix_prediction_votes_rls_recursion
20260519009900_fix_prediction_votes_rls_recursion_v2
20260519009910_prediction_votes_simple_rls
20260519009920_prediction_votes_drop_all_policies
20260519009930_pgrst_schema_reload
20260522000100_popular_matchups_feed
20260522000200_predictions_deadline_nullable
20260522000300_matchup_image_generator
20260522000400_fix_recommended_feed_popular_rpc
20260522000500_fix_coin_support_revenue_trigger_columns
20260522000600_streak_recovery_system
20260522000700_cosmetics_system
20260522000800_fix_equipped_cosmetics_keys
20260522000900_notification_type_announcement
20260522001000_welcome_email_template
20260522001100_waitlist_table
20260522001200_debate_battles                             — debate_battles + round_log + audience/extension votes tables
20260522001300_battle_notification_types                  — battle_challenge, battle_accepted, battle_result enum values
20260522001400_atomic_coin_ops                            — lock_coins_for_battle() + credit_coins() atomic RPCs
```

**Next migration timestamp to use: `20260522001500_...`**

---

## Admin Dashboard (`/admin/`)

Separate Next.js 16.2.6 app with App Router. Supabase URL: `ewltfxsevaofqdooldkw.supabase.co`.

**Sidebar** (`components/Sidebar.tsx`): collapsible, shows logo (`/public/logo.png`), nav links, user profile picture (fetched from `users.avatar_url` via `auth_user_id`), display name, and logout button.

**Admin pages:**
| Route | Purpose |
|-------|---------|
| `/` | Overview dashboard |
| `/analytics` | Activity charts, user/vote/argument metrics |
| `/matchups` | Matchup list with column filters, sort, status tabs |
| `/predictions` | Prediction management |
| `/categories` | Category management |
| `/scout` | Review AI-generated drafts (approve/reject) |
| `/payments` | Coin transactions + payment history |
| `/boosts` | Boost management table |
| `/users` | User list and management |
| `/notifications` | Push notification management |
| `/email` | Email messages, templates, and settings |
| `/moderation` | Content moderation queue |
| `/reports` | User-submitted reports |
| `/audit` | Moderation action logs |
| `/team` | Team / admin user management |
| `/settings` | Coin economy + recommendation controls |
| `/battles` | (**pending**) Battle history, recordings, moderation, manual end/cancel |
| `/login` | Supabase auth login |

Admin users: set `users.role = 'admin'` in Supabase Table Editor after account creation.

**Admin settings (`/settings`) controls:**
- Coin economy: vote cost, argument cost, transfer fee, support amounts, coin packs, boost tiers, signup bonus, daily claim base, streak bonus, daily claim max.
- Recommendation: personalization ratio, discovery ratio, perspective ratio, freshness decay, trending weight, interest weight, diversity weight.

---

## Edge Functions (Deno + TypeScript)

### Core — Live (4)

#### `approve-ai-draft`
Input: `draft_id`, `action` (approve/reject), optional edits. On approve: creates `matchup` + 2 `matchup_options`.

#### `create-coin-purchase`
Input: `coin_amount`, `usd_cents` (min $0.50). Creates Stripe PaymentIntent, inserts pending `coin_purchase`.

#### `confirm-coin-purchase`
Input: `client_secret`. Verifies with Stripe, credits `coin_balance`, records `coin_transaction`.

#### `run-scout`
Phase 1: parallel web searches targeting Haitian news sites. Phase 2: GPT-4 generates 25 drafts scored on 8 metrics, filters `uniqueness_score >= 6` + `safety_score >= 5`. Phase 3: inserts into `ai_generated_drafts` (status: `pending`).

### Debate Battle — Live (4)

#### `create-debate-battle`
Validates both users' creator tier (≥1 Rapid Fire, ≥2 Full Debate). Locks challenger entry fee. Inserts `debate_battles` row (status: `pending`). Inserts `notifications` row for opponent (`type: 'battle_challenge'`). Returns `battle_id`.

#### `accept-debate-battle`
Validates opponent tier. Locks opponent entry fee. Generates two Agora RTC tokens (same channel `battle_{id}`). Updates status to `accepted`. Notifies challenger (`type: 'battle_accepted'`).

#### `start-battle-recording`
Calls Agora Cloud Recording REST API to start recording to S3 bucket `gran-boulva-battle-recordings`. Stores Agora recording SID in battle row.

#### `end-battle`
Stops Agora recording → gets S3 URL → sets `recording_url` + `recording_expires_at = now() + 24h`. Opens audience winner vote (30s). Counts votes → sets `winner_id`. Distributes coins (90% winner, 10% platform). Updates `victory_count` / `participation_count`. Fires `record_badge_event()` + `refresh_creator_tier()` for both debaters. Posts feed card.

---

## Environment Variables

### Flutter app (`.env` at project root)
```
SUPABASE_URL=https://ewltfxsevaofqdooldkw.supabase.co
SUPABASE_ANON_KEY=eyJ...
STRIPE_PUBLISHABLE_KEY=pk_test_...
# AGORA_APP_ID passed via --dart-define at build time, not .env
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
SMTP_HOST, SMTP_USER, SMTP_PASS, SMTP_PORT, SMTP_SECURE    # IONOS SMTP
AGORA_APP_ID                                                 # pending — add when Agora account created
AGORA_APP_CERTIFICATE                                        # pending — server-side only, never in Flutter
AWS_ACCESS_KEY_ID                                            # pending — for Agora Cloud Recording S3 access
AWS_SECRET_ACCESS_KEY                                        # pending
AWS_S3_BUCKET=gran-boulva-battle-recordings                  # pending
AWS_S3_REGION=...                                            # pending
```

---

## Key Design Decisions

- **Voter-gated arguments:** Users cannot see arguments until they have voted — enforced at DB level.
- **Haitian Creole first:** All DB content has `_ht` and `_en` columns; UI defaults to `ht`.
- **Coin economy:** Purchased via Stripe, earned via referrals/admin/signup bonus/daily claim. Spent on boosts, argument support, and optionally voting/posting arguments. Transfers carry a fee. Admin controls live under `/admin/settings`.
- **Daily rewards:** Signup bonus defaults to 5 coins. Daily claim defaults to 2 coins, +1 streak bonus per consecutive day, capped at 10. Enforced by Supabase RPCs and tracked in `user_daily_coin_claims`.
- **Self-support blocked:** Users must not support their own arguments. UI hides the action and DB enforces via `support_argument_checked()`.
- **Recommendation Phase 1:** Home feed calls `get_recommended_home_feed()` first and falls back safely. The app records behavior events via `RecommendationService`. Tables: `user_interests`, `user_behavior_events`, `content_recommendation_scores`, `trending_scores`.
- **AI Scout pipeline:** `run-scout` → `ai_generated_drafts` (pending) → admin approves → `approve-ai-draft` creates live matchup.
- **Boost visibility:** `boost_expires_at` timestamp on arguments; expired boosts lose elevated visibility automatically.
- **Border colors on argument cards:** Option A → purple, Option B → pink (defined in `AppColors`).
- **free_boost_credits column** on `users` table tracks free boosts; query with `.eq('auth_user_id', user.id)` not `.eq('id', user.id)`.
- **Onboarding shown once:** Splash detects first launch via `SharedPreferences`; routes to `/onboarding` before `/login`. Subsequent launches skip it.
- **Auth deep-link URI:** `granboulva://auth-callback` — defined in `AuthRedirects.authCallback`.
- **Creator tier gating (debate battles):** Rapid Fire requires Tier 1+ (both debaters). Full Debate requires Tier 2+ (both debaters). Enforced server-side in Edge Function. Entry point (`⚔️ 1 vs 1`) currently hidden for all users — see "To reactivate" section above.
- **Battle timer authority:** `debate_battles.round_ends_at` is the server-side source of truth. Clients countdown locally and re-sync on rejoin. `pg_cron` advances Full Debate rounds server-side every 30s.
- **Battle recordings:** Agora Cloud Recording writes directly to S3. Bucket has a 24h lifecycle rule — AWS deletes files automatically. `recording_expires_at` in DB tracks expiry for UI; the URL goes dead when S3 deletes the file.
- **Battle challenge topic:** `BattleChallengeScreen` loads 5 popular matchups as selectable topics. Tapping one pre-fills the topic; free-text field activates if nothing is selected.
- **Battle notifications:** In-app only (DB rows). No push notification integration yet. User B must open the Notifications tab and pull-to-refresh to see a challenge.
- **Battle security hardening (done):** `end-battle` edge function rejects anonymous callers (requires valid JWT or service_role key). Coin deductions use atomic `lock_coins_for_battle()` RPC — no read-modify-write race condition. Entry fee capped at 10,000 coins. Topic length capped at 200 chars.
- **App Store revenue cut:** Apple/Google take 30% of all in-app coin purchases. This is the largest cost driver. Design coin flows to maximize off-store circulation (transfers, bonuses, rewards) where no cut applies.
- **MonCash payouts:** Haitian mobile money payout for creators. Currently sandbox. `coinToUsdRate: 0.001` (1,000 coins = $1 USD). Minimum payout: 1,000 coins.

---

## Deployment Notes

- Supabase migrations can be pushed from local with `supabase db push --linked`; this has been working.
- VPS admin deploy is currently manual because Claude cannot SSH non-interactively to `root@2.24.101.250`.
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

To fix "Installing and launching..." hang on real device:
```bash
# Kill the stuck flutter run, then use flutter install instead:
flutter install --device-id 00008030-001A41513A88C02E
# Then tap the app icon manually on the phone.
```

**iOS 14+ debug build limitation:** Debug builds cannot be launched from the home screen — iOS shows
"In iOS 14+, debug mode Flutter apps can only be launched from Flutter tooling...".
Use `flutter run` (keeps tooling attached) or build release for standalone use.

**Release build blank screen (silent failure):** `flutter install --release` can silently fail if
there is no pre-built artifact. Always run `flutter build ios --release` first, then install.
Diagnosing a release blank screen: wrap `main()` in `runZonedGuarded` to surface the error as
on-screen text, install release, tap icon, read the message.

---

## Monthly Budget Reference

Estimated monthly costs at early launch stage (Haiti/Caribbean team, ~50 battles/month):

| Category | Cost |
|----------|------|
| Supabase Pro | $25 |
| VPS + IONOS SMTP | ~$17 |
| OpenAI Scout | ~$24 |
| Stripe fees | ~$55 (on ~$1,000 coin sales) |
| Agora (battles) | ~$25 |
| AWS S3 (recordings) | ~$1 |
| Apple Developer | $8 |
| Tools (Figma, Slack, etc.) | ~$15 |
| Legal/accounting | ~$167 |
| **Team (5 people, Haiti rates)** | **~$6,750** |
| **Total** | **~$7,087/month** |

**Critical:** Apple/Google take **30%** of all in-app coin purchases (15% via Small Business Program under $1M/year). At $10,000/month gross coin revenue: $3,000 goes to Apple/Google before any operating cost.

---

## To-Do List

### 🔴 Before / During Apple Submission
- [ ] Prepare App Store screenshots, metadata, and app description
- [ ] Submit app to Apple App Store for review
- [ ] Apply pending DB migration: `supabase db push` → creates `partner_applications` table (`20260522001500_partner_applications.sql`)

### 🟡 After Apple Submission (while waiting)
- [ ] **VPS deploy** — SSH into `root@2.24.101.250` and run:
  ```bash
  cd /root/gran_boulva && git checkout -- admin/package-lock.json && git pull && cd admin && npm install && rm -rf .next && npm run build && pm2 restart gran-boulva-admin
  ```
- [ ] **Add Stripe secret key** — Admin dashboard → Settings → Stripe / Peman section

### 🟢 After Apple Approval (post-launch)
- [ ] **Web coin store** — Let users buy coins at `granboulva.com/coins` to bypass Apple's 30% fee. Includes: user login, pack grid with +10% web bonus, Stripe Checkout, confirm edge function, success page with deep link back to app, and "Buy on web" link in Flutter coin screen. Build once real purchase activity justifies it.
- [ ] **Agora + AWS setup** (to go live with Debate Battles):
  1. Create Agora account → new project → get App ID + App Certificate
  2. Add `AGORA_APP_ID` + `AGORA_APP_CERTIFICATE` to Supabase Edge Function secrets
  3. Enable Cloud Recording on Agora dashboard
  4. Create S3 bucket `gran-boulva-battle-recordings` with 24h object lifecycle rule
  5. Create IAM user with S3 write access → give credentials to Agora Cloud Recording
  6. Add `AGORA_APP_ID` to Flutter build: `--dart-define=AGORA_APP_ID=...`
  7. Reactivate `⚔️ 1 vs 1` entry point in `public_profile_screen.dart` (see instructions above)
- [ ] **Apple External Purchase Link entitlement** — Apply via App Store Connect to allow in-app link to web coin store (US users). Reduces Apple's cut on web-originated purchases.

**Agora scales with audience:** 500 viewers/battle × 1,500 battles/month ≈ $5,400/month in Agora fees alone. Consider viewer caps or premium live-viewing for high-traffic battles.
