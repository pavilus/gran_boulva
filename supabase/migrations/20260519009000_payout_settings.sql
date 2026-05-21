-- ============================================================
-- Payout Settings + creator_payouts enhancements
-- Migration: 20260519009000_payout_settings.sql
-- ============================================================

-- ── 1. Add payout settings row to app_settings ──────────────
insert into public.app_settings (key, value)
values (
  'payout_settings',
  '{
    "coinToUsdRate": 0.001,
    "minPayoutCoins": 1000,
    "payoutMode": "manual",
    "moncashEnvironment": "sandbox",
    "moncashEnabled": false
  }'::jsonb
)
on conflict (key) do nothing;

-- ── 2. Enhance creator_payouts columns ───────────────────────
alter table public.creator_payouts
  add column if not exists payout_phone     text,
  add column if not exists estimated_usd    numeric(10,4),
  add column if not exists moncash_reference text,
  add column if not exists auto_processed   boolean not null default false;

-- ── 3. RPC: get_payout_settings() — used by the app ─────────
create or replace function public.get_payout_settings()
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(value, '{}'::jsonb)
  from public.app_settings
  where key = 'payout_settings';
$$;

grant execute on function public.get_payout_settings() to authenticated, anon;
