# Gran Boulva — Reward System Reference

**Version:** 2026-05-25 (post-fix)  
**Language:** English (Haitian Creole terms preserved for in-app names)

---

## 1. Overview

Gran Boulva's reward system is designed to celebrate every way a user contributes to the community — voting, arguing, supporting others, and showing up day after day.

The system has three interlocking parts:

| Part | What it does |
|------|-------------|
| **Badges** (Badj) | Track five types of engagement. Each badge has 10 levels. Level up by accumulating XP through specific actions. |
| **XP (Experience Points)** | Raw currency for badge progression. Earned per action. Not directly visible to users — only the level matters. |
| **Influence Score** (Pwen Enfliyans) | A single number that reflects your standing in the community. Earned from coin support received, badge level-ups, and active participation. Shown in the menu as a tier label. |

These three reinforce each other: badge levels gate the creator tier system, and influence score determines your visible rank (Debitan → Entèmedyè → Konfime → Elit).

---

## 2. The 5 Badges — Complete Reference

### 2.1 Top Votè (Top Voter)

**Badge key:** `top_voter`  
**Color:** Purple `#A855F7`  
**What it measures:** How actively you vote on matchups.

**How to earn XP:**
- Cast a vote (via `submitVoteAndArgument`) → **+1 XP per vote**
- Change a vote (`changeVote`) → **+0 XP** (tracked but earns no XP; used to prevent vote-farming)

**Influence bonus per event:** +1 influence per vote cast (added after the fix)

**Level thresholds:**

| Level | XP Required | Influence Reward (on level-up) | What it means |
|-------|------------|-------------------------------|--------------|
| 1 | 10 | 5 | You've cast 10 votes |
| 2 | 50 | 10 | 50 votes in |
| 3 | 100 | 15 | 100 votes total |
| 4 | 250 | 20 | 250 votes — a consistent voice |
| 5 | 500 | 25 | 500 votes — serious voter |
| 6 | 1,000 | 30 | 1,000 votes — community pillar |
| 7 | 2,500 | 35 | 2,500 votes — top tier engagement |
| 8 | 5,000 | 40 | 5,000 votes — legendary voter |
| 9 | 10,000 | 45 | 10,000 votes — elite of the elite |
| 10 | 25,000 | 50 | 25,000 votes — Grand Boulva Master |

---

### 2.2 San Kanpe (Hot Streak)

**Badge key:** `hot_streak`  
**Color:** Orange `#F97316`  
**What it measures:** Daily consecutive activity (claiming your daily coin reward).

**How to earn XP:**
- Claim daily coin reward (`claimDailyReward`) → **+1 XP per day**, deduplicated by date key `daily:YYYY-MM-DD`

**Influence bonus per event:** None directly from San Kanpe (streak is its own reward — daily claim earns coins instead)

**Level thresholds:**

| Level | XP Required (Days) | Influence Reward | What it means |
|-------|-------------------|-----------------|--------------|
| 1 | 3 | 5 | 3-day streak |
| 2 | 7 | 10 | 1-week streak |
| 3 | 14 | 15 | 2-week streak |
| 4 | 21 | 20 | 3-week streak |
| 5 | 30 | 25 | 1-month streak |
| 6 | 45 | 30 | 45-day streak |
| 7 | 60 | 35 | 2-month streak |
| 8 | 90 | 40 | 3-month streak |
| 9 | 180 | 45 | 6-month streak |
| 10 | 365 | 50 | Full year streak — extraordinary |

Note: Streak recovery exists (`streak_recovery_system` migration). A broken streak does not reset badge XP.

---

### 2.3 Gran Debatè (Debater)

**Badge key:** `debater`  
**Color:** Blue `#3B82F6`  
**What it measures:** How often you post arguments.

**How to earn XP:**
- Post an argument alongside a vote (`submitVoteAndArgument`) → **+3 XP per argument**

**Influence bonus per event:** +2 influence per argument posted (added after the fix)

**Level thresholds:**

| Level | XP Required | Influence Reward | What it means |
|-------|------------|-----------------|--------------|
| 1 | 5 | 5 | ~2 arguments posted |
| 2 | 25 | 10 | ~9 arguments |
| 3 | 50 | 15 | ~17 arguments |
| 4 | 100 | 20 | ~34 arguments |
| 5 | 250 | 25 | ~84 arguments |
| 6 | 500 | 30 | ~167 arguments |
| 7 | 1,000 | 35 | ~334 arguments |
| 8 | 2,500 | 40 | ~834 arguments |
| 9 | 5,000 | 45 | ~1,667 arguments |
| 10 | 10,000 | 50 | ~3,334 arguments — true Grand Debatè |

---

### 2.4 Konsistan (Consistent)

**Badge key:** `consistent`  
**Color:** Green `#22C55E`  
**What it measures:** Weekly participation over time.

**How to earn XP:**
- During daily claim on Monday, OR when the streak count is a multiple of 7 → **+1 XP per week**, deduplicated by week key `week:YYYY-WNN`

**Influence bonus per event:** None directly; level-up rewards apply.

**Level thresholds:**

| Level | XP Required (Weeks) | Influence Reward | What it means |
|-------|--------------------|-----------------| --------------|
| 1 | 1 | 5 | First active week |
| 2 | 2 | 10 | 2 weeks in |
| 3 | 4 | 15 | 1 month of weeks |
| 4 | 8 | 20 | 2 months |
| 5 | 12 | 25 | 3 months |
| 6 | 24 | 30 | 6 months |
| 7 | 36 | 35 | 9 months |
| 8 | 52 | 40 | Full year |
| 9 | 104 | 45 | 2 years of consistent play |
| 10 | 156 | 50 | 3 years — absolute veteran |

---

### 2.5 Gran Sipòtè (Great Supporter)

**Badge key:** `community`  
**Color:** Pink `#D90C82`  
**What it measures:** Supporting others through coins, gifts, and replies.

**How to earn XP:**
- Support an argument with coins (`supportArgument`) → **+2 XP per support action**
- Gift coins to a creator (`giftCoins`) → **+2 XP per gift**
- Reply to someone's argument (`replyToArgument`) → **+2 XP per reply**

**Influence bonus per event:** +1 influence per community action (added after the fix)

**Level thresholds:**

| Level | XP Required | Influence Reward | What it means |
|-------|------------|-----------------|--------------|
| 1 | 10 | 5 | 5 support actions |
| 2 | 50 | 10 | 25 actions |
| 3 | 100 | 15 | 50 actions |
| 4 | 250 | 20 | 125 actions |
| 5 | 500 | 25 | 250 actions |
| 6 | 1,000 | 30 | 500 actions |
| 7 | 2,500 | 35 | 1,250 actions |
| 8 | 5,000 | 40 | 2,500 actions |
| 9 | 10,000 | 45 | 5,000 actions |
| 10 | 25,000 | 50 | 12,500 actions — the ultimate Gran Sipòtè |

---

## 3. Influence Score

### What it is

`influence_score` is a single integer on every user's profile. It represents community standing and prestige, distinct from coins (which are spendable currency) or badge XP (which is internal tracking).

### Where it appears

The Menu screen (`MenuScreen`) displays the influence score as both a raw number and a tier label:

| Tier Label | Tier Emoji | Influence Required |
|-----------|-----------|-------------------|
| Debitan | 👤 | 0–14 |
| Entèmedyè | 🌱 | 15–34 |
| Konfime | ✅ | 35–69 |
| Elit | ⚡ | 70+ |

The menu card shows: `{emoji} {label} • {score} pwen`

Influence also appears on argument cards in the argument feed (shown alongside the author's username).

### All the ways to earn influence (after the fix)

| Source | Amount | When |
|--------|--------|------|
| Receiving coin support on an argument | `floor(coins / 10)`, minimum 1 | When another user calls `support_argument()` — the creator receives influence, not the supporter |
| Badge level-up (any badge) | `level × 5` (the `influence_reward` for that level) | When `record_badge_event_v2` detects a level-up |
| Vote cast (top_voter badge event) | +1 per vote | Every time a new vote event is inserted |
| Argument posted (debater badge event) | +2 per argument | Every time a new argument event is inserted |
| Community action (community badge event) | +1 per support/gift/reply | Every time a new community event is inserted |

**Note:** The `hot_streak` and `consistent` badge events do not carry per-event influence bonuses — they are rewarded only via level-up influence_rewards.

### Pre-fix state (what was broken)

Before migration `20260525000400`, `influence_score` was only updated by coin support received (`support_argument` function). Badge level-ups stored the `influence_reward` in the `badge_levels` table but never wrote to `users.influence_score`. Votes, arguments, and community actions generated no influence at all. This meant users who were highly active debaters could have an influence score of 0 unless someone also sent them coins.

---

## 4. Creator Tier System

Creator tiers live in the `creator_profiles` table. A user's creator tier determines access to Debate Battles and revenue sharing.

| Tier | Name (HT) | Name (EN) | Unlock Condition | Revenue Share | Debate Access |
|------|-----------|-----------|-----------------|--------------|---------------|
| 0 | Itilizatè | User | Default (everyone starts here) | 0% | None |
| 1 | Kreyatè Monte | Rising Creator | `creator_score >= 15` AND `followers_count >= 10` — automatic | 0% (monetization not yet enabled) | Rapid Fire (5 min) |
| 2 | Kreyatè Verifye | Verified Creator | Approved verification (trusted_creator / public_figure / organization) AND `creator_score >= 35` | 70% | Full Debate + Rapid Fire |
| 3 | Kreyatè Elit | Elite Creator | `creator_score >= 70` + admin confirmation | 80% | All |
| 4 | Ikòn Kiltirèl | Cultural Icon | Admin-only grant | Custom | All |

### How creator_score is calculated

`calculate_creator_score(user_id)` returns 0–100 using six weighted components:

| Component | Max Points | Formula |
|-----------|-----------|---------|
| Badge Progression | 30 | `(avg badge level / 10) × 30` |
| Engagement Quality | 20 | Log-scale of `participation_count` (capped at 500) |
| Followers | 20 | Log-scale of `followers_count` (capped at 10,000) |
| Consistency | 15 | Log-scale of `participation_count` (capped at 200) |
| Community Reputation | 10 | Log-scale of `total_support_received` (capped at 5,000 coins) |
| Debate Performance | 5 | `victory_count / max(participation_count, 1) × 5` |

`refresh_creator_tier(user_id)` recalculates the score and auto-upgrades tiers 0→1 and 1→2. Tiers 3 and 4 are admin-only.

---

## 5. Progression Roadmap

Assumptions: 5 votes/day, 2 arguments/week (via `submitVoteAndArgument`), 1 support or reply action/week.

For simplicity, daily claim is assumed every day, and weeks are counted by Monday claim events.

### Influence score estimate

Per week (5 days active):
- Votes: 5 × 5 = 25 vote events × 1 influence each = 25 influence/week from votes
- Arguments: 2 × 2 influence = 4 influence/week from arguments
- Community: 1 × 1 influence = 1 influence/week from community actions
- Level-up rewards: periodic bonuses (see below)

**Total base per week: ~30 influence** (before level-up bonuses)

### Week-by-week view

| Milestone | XP accumulation | Badge levels reached | Estimated influence score |
|-----------|----------------|---------------------|--------------------------|
| Week 1 | top_voter: 25 XP (Lv1 at 10 ✓), debater: 6 XP (Lv1 at 5 ✓), hot_streak: 5+ XP (Lv1 at 3 ✓, Lv2 at 7 possible), consistent: 1 XP (Lv1 ✓), community: 2 XP | Lv1 on 4 badges (all except community) | ~45 |
| Month 1 (4 weeks) | top_voter: ~100 XP → Lv3, debater: ~24 XP → Lv1, hot_streak: ~28 XP → Lv4, consistent: ~4 XP → Lv3, community: ~8 XP → approaching Lv1 | top_voter Lv3, hot_streak Lv4, consistent Lv3 | ~160 |
| Month 3 (13 weeks) | top_voter: ~325 XP → Lv4, debater: ~78 XP → Lv3, hot_streak: ~91 XP → Lv8, consistent: ~13 XP → Lv5, community: ~26 XP → Lv2 | Meaningful progress on all 5 badges | ~600 |
| Month 6 (26 weeks) | top_voter: ~650 XP → Lv5+, debater: ~156 XP → Lv4, hot_streak: ~182 XP → Lv9, consistent: ~26 XP → Lv6, community: ~52 XP → Lv2+ | Several badges at Lv5+, streak at Lv9 | ~1,100–1,500 |

Note: These are estimates. Actual influence varies with coin support received (which can add large influence bonuses) and the exact level-up timing.

---

## 6. Badge Level Reference Tables

### Top Votè — Level Reference

| Level | XP Required | Cumulative XP | Influence Reward | What it means |
|-------|------------|--------------|-----------------|---------------|
| 1 | 10 | 10 | 5 | First 10 votes |
| 2 | 50 | 50 | 10 | 50 votes cast |
| 3 | 100 | 100 | 15 | 100 votes |
| 4 | 250 | 250 | 20 | 250 votes |
| 5 | 500 | 500 | 25 | 500 votes |
| 6 | 1,000 | 1,000 | 30 | 1,000 votes |
| 7 | 2,500 | 2,500 | 35 | 2,500 votes |
| 8 | 5,000 | 5,000 | 40 | 5,000 votes |
| 9 | 10,000 | 10,000 | 45 | 10,000 votes |
| 10 | 25,000 | 25,000 | 50 | 25,000 votes — Grand Master |

Note: XP thresholds are cumulative totals (not deltas). Each vote earns 1 XP. Level 1 requires 10 total XP. XP never resets.

### San Kanpe — Level Reference

| Level | XP Required (Days) | Cumulative | Influence Reward | What it means |
|-------|-------------------|-----------|-----------------|---------------|
| 1 | 3 | 3 | 5 | 3-day streak |
| 2 | 7 | 7 | 10 | Week |
| 3 | 14 | 14 | 15 | 2 weeks |
| 4 | 21 | 21 | 20 | 3 weeks |
| 5 | 30 | 30 | 25 | Month |
| 6 | 45 | 45 | 30 | 45 days |
| 7 | 60 | 60 | 35 | 2 months |
| 8 | 90 | 90 | 40 | 3 months |
| 9 | 180 | 180 | 45 | 6 months |
| 10 | 365 | 365 | 50 | Full year |

### Gran Debatè — Level Reference

| Level | XP Required | Cumulative XP | Influence Reward | Approx. Arguments |
|-------|------------|--------------|-----------------|------------------|
| 1 | 5 | 5 | 5 | ~2 |
| 2 | 25 | 25 | 10 | ~9 |
| 3 | 50 | 50 | 15 | ~17 |
| 4 | 100 | 100 | 20 | ~34 |
| 5 | 250 | 250 | 25 | ~84 |
| 6 | 500 | 500 | 30 | ~167 |
| 7 | 1,000 | 1,000 | 35 | ~334 |
| 8 | 2,500 | 2,500 | 40 | ~834 |
| 9 | 5,000 | 5,000 | 45 | ~1,667 |
| 10 | 10,000 | 10,000 | 50 | ~3,334 |

Note: Each argument earns 3 XP. Approx. arguments = XP required / 3.

### Konsistan — Level Reference

| Level | XP Required (Weeks) | Cumulative | Influence Reward | Calendar |
|-------|--------------------|-----------|-----------------| ---------|
| 1 | 1 | 1 | 5 | 1 week |
| 2 | 2 | 2 | 10 | 2 weeks |
| 3 | 4 | 4 | 15 | 1 month |
| 4 | 8 | 8 | 20 | 2 months |
| 5 | 12 | 12 | 25 | 3 months |
| 6 | 24 | 24 | 30 | 6 months |
| 7 | 36 | 36 | 35 | 9 months |
| 8 | 52 | 52 | 40 | 1 year |
| 9 | 104 | 104 | 45 | 2 years |
| 10 | 156 | 156 | 50 | 3 years |

### Gran Sipòtè — Level Reference

| Level | XP Required | Cumulative XP | Influence Reward | Approx. Actions |
|-------|------------|--------------|-----------------|----------------|
| 1 | 10 | 10 | 5 | 5 actions |
| 2 | 50 | 50 | 10 | 25 actions |
| 3 | 100 | 100 | 15 | 50 actions |
| 4 | 250 | 250 | 20 | 125 actions |
| 5 | 500 | 500 | 25 | 250 actions |
| 6 | 1,000 | 1,000 | 30 | 500 actions |
| 7 | 2,500 | 2,500 | 35 | 1,250 actions |
| 8 | 5,000 | 5,000 | 40 | 2,500 actions |
| 9 | 10,000 | 10,000 | 45 | 5,000 actions |
| 10 | 25,000 | 25,000 | 50 | 12,500 actions |

Note: Each support/gift/reply earns 2 XP. Approx. actions = XP required / 2.

---

## 7. Tips for New Users

**Start with voting.** Every matchup vote earns Top Votè XP and +1 influence. It costs 0 coins (or very few, depending on your economy settings). Vote on 10 matchups your first day and you'll hit Top Votè Level 1 immediately.

**Add an argument every time you vote.** The `submitVoteAndArgument` flow earns both Top Votè XP (+1) and Gran Debatè XP (+3) in a single action. Two arguments a week is enough to reach Debater Level 1 in your first week.

**Claim your daily coins every day.** This is the fastest path to San Kanpe badges. 3 consecutive days unlocks Level 1. It also earns coins you can use to support others.

**Reply to arguments you find interesting.** Each reply earns Gran Sipòtè XP (+2) and +1 influence. This is the easiest way to build community standing while contributing to better debates.

**Send coin support when you believe in someone.** The person you support gains influence from your coins (`floor(coins / 10)` per support). Supporting generously lifts the best voices in the community. Plus, you earn Gran Sipòtè XP and +1 influence yourself.

**Badge level-ups give you a burst of influence.** When you level up any badge, you immediately earn `level × 5` influence. Reaching Level 5 on Top Votè gives you 25 influence at once. Plan your active streaks and argument posting to hit multiple level-ups in the same week.

**Consistency beats intensity.** The Konsistan badge rewards weekly presence, not daily fire. You only need to be active once a week, every week, to progress. A player who is active 1 day a week for a year outranks a player who played heavily for one month and then quit.

**Gran Sipòtè is a sleeper badge.** Most users neglect it, but it has the same high thresholds as Top Votè. Community builders who reply and support regularly will stand out in the long run. And the Haitian community spirit — *solidarite* — is exactly what Gran Sipòtè rewards.
