# Gran Boulva App Test Plan

Version: 2026-05-21  
Platform target: iOS first, with cross-checks on Android and web when available  
Primary goal: verify every user-facing feature, critical backend rule, and high-risk integration before release.

## 1. Test Strategy

Gran Boulva should be tested in four layers:

1. Smoke tests: fast checks after every build to confirm the app opens and critical paths still work.
2. Feature tests: manual and automated scenarios for every screen and core service.
3. Integration tests: Supabase RPCs, Edge Functions, storage, notifications, coins, verification, and admin workflows.
4. Release regression: full pass on a clean iOS install with real network, production-like data, and at least two user accounts.

## 2. Test Environments

| Environment | Purpose | Required Data |
|---|---|---|
| Local simulator | Fast UI regression, layout, smoke tests | Seed users, matchups, arguments, coins |
| Physical iPhone | Real-device behavior, camera/photos, push/deep links, performance | Test accounts and Supabase test project |
| Supabase staging | RPC, RLS, storage, Edge Functions | Test migrations applied |
| Supabase production | Final release validation only | Small controlled test account set |

## 3. Test Accounts

Create and keep these accounts available:

| Account | Role | Purpose |
|---|---|---|
| `tester_a` | Normal user, Male | Signup, vote, argue, boost own argument |
| `tester_b` | Normal user, Female | Follow, support arguments, default female avatar |
| `creator_1` | Creator-eligible user | Creator dashboard and revenue checks |
| `verified_pending` | User with pending verification | Verification review checks |
| `admin_1` | Admin | Admin dashboard, reports, verification approval |
| `low_coin_user` | Normal user with 0-5 coins | Insufficient balance checks |

## 4. Pre-Release Entry Criteria

- `flutter analyze` passes.
- `scripts/test_fast.sh` passes.
- Latest Supabase migrations are pushed to staging.
- App launches on the current iOS simulator and one physical iPhone.
- Test accounts can sign in.
- Staging storage buckets exist: `avatars`, `verification-documents`.
- Edge Functions used by the app are deployed or fallback RPCs are confirmed.

## 5. Smoke Test Checklist

Run this after every meaningful change.

| ID | Area | Steps | Expected Result |
|---|---|---|---|
| SM-01 | Launch | Fresh install, open app | Splash appears, then onboarding or home based on auth state |
| SM-02 | Login | Sign in as `tester_a` | User reaches home with bottom navigation |
| SM-03 | Home | Scroll home feed | Matchup cards load, images/icons render, no crash |
| SM-04 | Matchup | Open a matchup | Detail page loads with 56px top bar and matching back button style |
| SM-05 | Vote | Vote on a matchup | Vote persists and arguments unlock |
| SM-06 | Argument | Post an argument | Argument appears under the selected option |
| SM-07 | Profile | Open profile tab | User info, stats, badges section, and avatar render |
| SM-08 | Menu | Open menu tab | Menu items and nav icon states render correctly |
| SM-09 | Notifications | Open notifications | List loads or empty state appears |
| SM-10 | Logout | Log out from settings/menu | Session clears and app returns to login/onboarding |

## 6. Authentication and Onboarding

| ID | Scenario | Steps | Expected Result |
|---|---|---|---|
| AUTH-01 | First launch onboarding | Install app fresh and open | Onboarding appears before auth-only routes |
| AUTH-02 | Create account required fields | Attempt signup without required fields | Form blocks submission with clear errors |
| AUTH-03 | Create account success | Enter full name, username, email, password, required sex, required date of birth, optional country and phone | Account and profile are created |
| AUTH-04 | Username availability | Try an existing username | App rejects duplicate username |
| AUTH-05 | Male default avatar | Create Male account without photo | Profile/home/menu show `default_male.png` |
| AUTH-06 | Female default avatar | Create Female account without photo | Profile/home/menu show `default_female.png` |
| AUTH-07 | Login success | Sign in with valid credentials | Home opens and session persists after restart |
| AUTH-08 | Login failure | Sign in with wrong password | Error appears, no session starts |
| AUTH-09 | Forgot password | Submit valid email | Reset request is accepted |
| AUTH-10 | Logout | Log out | Auth session is cleared; protected routes redirect away |

## 7. Navigation and Layout

| ID | Scenario | Steps | Expected Result |
|---|---|---|---|
| NAV-01 | Bottom nav icons | Tap Home, Notifications, Profile, Menu | Selected tab uses filled icon; unselected tabs use unfilled icon |
| NAV-02 | Nav icon size | Compare nav icons visually | Icons are consistently sized and not clipped |
| NAV-03 | Back button consistency | Open matchup, profile subpages, payment, boost | Back buttons match app style |
| NAV-04 | Text overflow | Check profile About, cards, buttons on small iPhone | Text stays inside containers, two-line max where specified |
| NAV-05 | Deep route guard | Open protected route while logged out | App redirects to login |

## 8. Home and Matchup Feed

| ID | Scenario | Steps | Expected Result |
|---|---|---|---|
| HOME-01 | Recommended feed | Open home | Feed loads recommended matchups |
| HOME-02 | Category filter | Select categories if available | Feed updates by category |
| HOME-03 | Save matchup | Save and unsave a matchup | State persists and saved page updates |
| HOME-04 | Matchup image | View matchup cards | Images render with fallback if missing |
| HOME-05 | Empty state | Use an account/category with no matchups | Empty state appears without crash |
| HOME-06 | Feed refresh | Pull to refresh or revisit home | Latest data appears |

## 9. Matchup Detail, Voting, and Arguments

| ID | Scenario | Steps | Expected Result |
|---|---|---|---|
| MAT-01 | Detail load | Open matchup from feed | Title, options, stats, and action area load |
| MAT-02 | Vote required | Open arguments before voting | Arguments are locked if vote is required |
| MAT-03 | Submit vote | Pick option A or B and submit | Vote count updates and selection persists |
| MAT-04 | Change vote | Change selected option | Coin rule applies and vote updates |
| MAT-05 | Submit argument | Vote with a valid argument body | Argument is created and visible |
| MAT-06 | Empty argument | Submit blank argument | App blocks submission |
| MAT-07 | Own argument merge | User has own argument but hidden by voter visibility RPC | Own argument still appears |
| MAT-08 | Argument sorting Top | Select `Top Agimantasyon` | Arguments sort by `final_score` |
| MAT-09 | Argument sorting Boosted | Select `Boosted` | Only active boosted arguments appear, sorted by score |
| MAT-10 | Argument sorting Recent | Select `Resan` | Newest arguments appear first |
| MAT-11 | Following tab | Select `Swiv mwen` | Followed users' arguments are shown or empty state appears |
| MAT-12 | Like argument | Like another user's argument | Like count and score update |
| MAT-13 | Remove like | Tap same reaction again | Reaction is removed |
| MAT-14 | Reply | Add reply to argument | Reply count updates; reply appears in thread |
| MAT-15 | Report | Report argument | Report is saved and admin can view it |

## 10. Boost System

| ID | Scenario | Steps | Expected Result |
|---|---|---|---|
| BST-01 | Boost screen | Tap `Booste` on own argument | Boost tier screen opens |
| BST-02 | 24h boost | Buy/use `24h` tier | Coins deducted, `boost_expires_at` extends 24h, boost score +20 |
| BST-03 | 4d boost | Buy/use `4d` tier | Coins deducted, expiration extends 4 days, boost score +60 |
| BST-04 | 1w boost | Buy/use `1w` tier | Coins deducted, expiration extends 7 days, boost score +120 |
| BST-05 | Free boost | Use free credit when available | Free credit decreases; no coins deducted |
| BST-06 | Insufficient coins | Try boost with low balance | Clear insufficient balance error |
| BST-07 | Own argument rule | Try boosting another user's argument | App/backend blocks action |
| BST-08 | Visual state | Return to matchup detail | Boosted badge/glow appears |
| BST-09 | Ranking effect | Compare Top tab before/after boost | Boosted argument moves according to formula but not guaranteed first |
| BST-10 | Expired boost | Use test data with expired boost | Badge disappears and boost score returns to 0 |

## 11. Boulva Coins and Economy

| ID | Scenario | Steps | Expected Result |
|---|---|---|---|
| COIN-01 | Balance display | Open coin store/menu/profile | Balance is consistent across screens |
| COIN-02 | Daily claim | Claim daily coins | Balance increases and claim state updates |
| COIN-03 | Daily duplicate | Claim again same day | App blocks duplicate claim |
| COIN-04 | Coin packs | Open coin store | Packs and prices render from config/fallback |
| COIN-05 | Purchase flow | Start purchase | Payment screen opens with selected pack |
| COIN-06 | Purchase success | Complete test purchase or mock confirmation | Balance and transaction history update |
| COIN-07 | Purchase failure | Cancel or fail payment | No balance change; clear error |
| COIN-08 | Transaction history | Open recent transactions | Transactions are ordered newest first |
| COIN-09 | Support argument | Support another user's argument with 10/25/50/100 coins | Coins deducted; argument support count/coins increase |
| COIN-10 | Self support | Try supporting own argument | Backend rejects |
| COIN-11 | Low balance support | Support with insufficient balance | Clear error, no count change |
| COIN-12 | Transfer coins | Send coins to another user | Amount plus fee deducted; receiver balance increases |
| COIN-13 | Transfer fee | Send 100 coins | Sender pays 110 if fee is 10; receiver gets 100 |
| COIN-14 | Gift/feed | Public gift/support feed if enabled | Event appears with correct sender/receiver data |

## 12. Badge System

| ID | Scenario | Steps | Expected Result |
|---|---|---|---|
| BADGE-01 | Badge list | Open badges page | Badge names and icons load |
| BADGE-02 | Profile badges | Open profile with no earned badges | No unearned badge icons appear |
| BADGE-03 | Top Votè | Generate vote badge progress | `Top Votè` uses `topvotè.png` |
| BADGE-04 | San Kanpe | Claim daily or hot streak progress | `San Kanpe` uses `sankanpe.png` |
| BADGE-05 | Gran Debatè | Create argument/reply progress | `Gran Debatè` uses `grandebatè.png` |
| BADGE-06 | Konsistan | Trigger consistent activity | `Konsistan` uses `konsistan.png` |
| BADGE-07 | Gran Sipòtè | Support/gifting progress | `Gran Sipòtè` uses `sipote.png` |
| BADGE-08 | Level-up notification | Cross a badge threshold | Notification is created once per level |

## 13. Profile and Social Graph

| ID | Scenario | Steps | Expected Result |
|---|---|---|---|
| PROF-01 | My profile | Open profile tab | Avatar, username, About, stats, badges load |
| PROF-02 | About limit | Set long About text | Profile truncates to two lines without overflow |
| PROF-03 | Stats | Check Enfliyans, Patisipasyon, Viktwa, Abònen | Values and icons render correctly |
| PROF-04 | Estatistik mwen | Open statistics | Vòt total, victory, comment, clock, boost stats are correct |
| PROF-05 | Followers/following | Follow from public profile | Counts update on both profiles |
| PROF-06 | Public profile | Open `/user/:username` | Public profile loads or shows not found |
| PROF-07 | Avatar upload | Upload/crop profile photo | New avatar appears across home, menu, profile |
| PROF-08 | Personal info | Edit name, country, phone, About | Changes save and persist |
| PROF-09 | Top voices | Open top voices | Ranked voices load with influence data |

## 14. Verification System

| ID | Scenario | Steps | Expected Result |
|---|---|---|---|
| VER-01 | Request form | Open verification request | Form loads current verification status |
| VER-02 | Required fields | Submit empty request | Required validation appears |
| VER-03 | Document upload | Upload document/photo proof | File uploads to private bucket and row is created |
| VER-04 | Submit request | Submit valid request | Request status becomes pending |
| VER-05 | Duplicate pending | Submit while pending | App prevents duplicate or updates gracefully |
| VER-06 | Admin view | Admin opens verification tab | Pending requests and documents appear |
| VER-07 | Signed document URL | Admin opens document | Temporary signed URL opens file |
| VER-08 | Approve | Admin approves request | User verification fields update and notification is sent |
| VER-09 | Reject | Admin rejects with reason | Request rejected, user notified |
| VER-10 | Revoke | Admin revokes approved verification | Badge/status removed and audit data updates |

## 15. Notifications

| ID | Scenario | Steps | Expected Result |
|---|---|---|---|
| NOTIF-01 | Notification list | Open notifications tab | Notifications load newest first |
| NOTIF-02 | Unread count | Trigger notification | Nav/menu count updates |
| NOTIF-03 | Mark one read | Tap a notification | It becomes read |
| NOTIF-04 | Mark all read | Use mark all read action | All unread notifications become read |
| NOTIF-05 | Notification icons | Inspect pages using notification icon | `notification_unifilled.png` or expected asset appears |
| NOTIF-06 | Related navigation | Tap boost/support/badge notification | App opens relevant screen when route is supported |

## 16. Predictions

| ID | Scenario | Steps | Expected Result |
|---|---|---|---|
| PRED-01 | Feed | Open predictions tab | Prediction cards load |
| PRED-02 | Detail | Open prediction | Detail and options load |
| PRED-03 | Vote prediction | Select option | Vote is saved and count updates |
| PRED-04 | Duplicate vote | Vote again if not allowed | App/backend blocks duplicate |
| PRED-05 | Admin create prediction | Admin creates prediction | Prediction appears in feed |

## 17. Creator Dashboard and Revenue

| ID | Scenario | Steps | Expected Result |
|---|---|---|---|
| CR-01 | Dashboard load | Open creator dashboard | Creator tier, wallet, revenue, and stats load |
| CR-02 | Tier refresh | Trigger refresh tier | Tier recalculates from creator score |
| CR-03 | Revenue events | Support/boost-related event occurs | Revenue event appears when eligible |
| CR-04 | Payout request | Request payout with valid amount | Payout row is created |
| CR-05 | Invalid payout | Request below minimum or over balance | App blocks request |

## 18. Admin Dashboard

| ID | Scenario | Steps | Expected Result |
|---|---|---|---|
| ADM-01 | Admin access | Open admin route as admin | Dashboard opens |
| ADM-02 | Non-admin access | Open admin route as normal user | Access is blocked |
| ADM-03 | Matchups list | Open matchups admin tab | Matchups load |
| ADM-04 | Create matchup | Create matchup with category and two options | Matchup and options are saved |
| ADM-05 | Publish/unpublish | Toggle publish state | Matchup visibility updates |
| ADM-06 | Reports | Open pending reports | Reports load with related data |
| ADM-07 | AI drafts | Approve/reject draft if data exists | Edge Function updates draft state |
| ADM-08 | Categories | Add category | Category appears in app filters |
| ADM-09 | Run trend scan | Trigger scan | Edge Function runs or returns controlled error |

## 19. Settings, Security, Help, and Recovery

| ID | Scenario | Steps | Expected Result |
|---|---|---|---|
| SET-01 | Settings list | Open settings | Items render and navigate |
| SET-02 | Notification settings | Toggle notification preferences | State persists or controlled placeholder is shown |
| SET-03 | Security page | Open security | Password/session options render |
| SET-04 | Password reset | Submit reset email | Supabase reset flow starts |
| SET-05 | Help page | Open help | FAQ/help content renders |
| SET-06 | Recovery | Test app after force close/network drop | Session recovers or redirects cleanly |

## 20. Saved Items and Recent Activity

| ID | Scenario | Steps | Expected Result |
|---|---|---|---|
| SAVE-01 | Save matchup | Save from card/detail | Item appears in saved page |
| SAVE-02 | Unsave matchup | Remove saved item | Item disappears |
| ACT-01 | Recent activity | Open recent activity | Vote, debate/comment, and badge activities use expected icons |
| ACT-02 | Empty activity | Account with no activity | Empty state appears |

## 21. Recommendation and Analytics Signals

| ID | Scenario | Steps | Expected Result |
|---|---|---|---|
| REC-01 | View signal | Open matchup | `matchup_view` event records without blocking UI |
| REC-02 | Vote signal | Vote/argue | Recommendation event records |
| REC-03 | Boost signal | Boost argument | Boost event records |
| REC-04 | Notification click | Tap notification | Click event records |
| REC-05 | Fallback | Disable Edge Function in staging | App falls back to DB query/RPC where implemented |

## 22. Media and Assets

| ID | Scenario | Steps | Expected Result |
|---|---|---|---|
| ASSET-01 | Navigation assets | Inspect nav tabs | Filled/unfilled icon assets display correctly |
| ASSET-02 | Coin assets | Inspect coin store/support/profile | All coin icons use `coin.png` |
| ASSET-03 | Fire assets | Inspect streak/support/activity | All fire icons use `fire.png` |
| ASSET-04 | Profile stat assets | Inspect profile sections | community/fire/trophy/follower/victory/vote/comment/clock icons display |
| ASSET-05 | Missing asset fallback | Temporarily missing optional image in staging build | App uses safe fallback or fails visibly during QA |

## 23. iOS-Specific Test Pass

| ID | Scenario | Steps | Expected Result |
|---|---|---|---|
| IOS-01 | Cold launch | Kill app and relaunch | App restores expected route/session |
| IOS-02 | Background/foreground | Background app for 2 minutes | State remains stable |
| IOS-03 | Offline mode | Turn on airplane mode | App shows controlled errors and no crash |
| IOS-04 | Slow network | Use network link conditioner if available | Loading states appear, no duplicate submissions |
| IOS-05 | Camera/photos permission | Upload avatar/verification document | Permission prompts work and denial is handled |
| IOS-06 | Keyboard | Fill long forms | Keyboard does not cover primary action permanently |
| IOS-07 | Safe areas | Test notched iPhones | Headers/nav bars do not overlap system UI |
| IOS-08 | Dynamic text | Increase text size | Critical screens remain usable |

## 24. Security and Data Rules

| ID | Scenario | Steps | Expected Result |
|---|---|---|---|
| SEC-01 | RLS own data | Normal user queries another user's private data | Access is denied |
| SEC-02 | Verification documents | Normal user opens another user's document path | Access denied; admin signed URL required |
| SEC-03 | Coin balance integrity | Attempt duplicate support/boost taps rapidly | No negative balance or duplicate unintended spend |
| SEC-04 | Admin-only RPC/screen | Normal user attempts admin action | Blocked by UI and backend |
| SEC-05 | Self-support | Support own argument through UI/RPC | Rejected |
| SEC-06 | Boost ownership | Boost another user's argument through UI/RPC | Rejected |
| SEC-07 | Input sanitization | Enter long/special text in profile/argument/reply | Data saves safely and UI does not overflow |

## 25. Performance Checks

| ID | Scenario | Steps | Target |
|---|---|---|---|
| PERF-01 | App launch | Measure cold launch | Usable within acceptable release target |
| PERF-02 | Home feed load | Load home on normal network | First content appears quickly with loading state |
| PERF-03 | Matchup detail | Open busy matchup with many arguments | Smooth scroll, no jank-heavy layout |
| PERF-04 | Profile | Open profile with many badges/activities | No visible stalls |
| PERF-05 | Coin/notification queries | Open transaction and notification lists | Queries return in reasonable time |

## 26. Automation Recommendations

Automate these first:

1. Auth smoke: launch, login, logout.
2. Matchup smoke: open feed, open detail, vote, post argument.
3. Boost smoke: boost own argument with seeded coins and verify boosted state.
4. Coin support smoke: support another user's argument and verify counts.
5. Profile smoke: default avatar by gender, follower/following counts, About truncation.
6. Verification smoke: submit request with test image, admin approve in staging.
7. Admin smoke: create/publish/unpublish matchup.

Suggested tooling:

- Flutter widget tests for formatting, validation, and small UI states.
- Flutter integration tests on iOS simulator for navigation and core flows.
- Supabase SQL/RPC tests for coins, boost, support, badges, and RLS.
- A small seeded QA dataset reset script for repeatable manual testing.

## 27. Release Exit Criteria

- All smoke tests pass on simulator and physical iPhone.
- All P0/P1 feature tests pass.
- No known crash, auth lockout, payment/coin loss, or data exposure issue remains.
- Boost/support ranking has been verified with at least three arguments of different scores.
- Admin verification approval/rejection is verified.
- Logout and session recovery are verified.
- App has been tested from a clean install.

## 28. Priority Legend

| Priority | Meaning |
|---|---|
| P0 | Blocks release: crash, auth broken, data loss, payment/coin issue, private data leak |
| P1 | Major feature broken or core UX unusable |
| P2 | Important regression but workaround exists |
| P3 | Polish, copy, visual consistency |

