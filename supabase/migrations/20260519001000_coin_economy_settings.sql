create table if not exists public.app_settings (
  key text primary key,
  value jsonb not null,
  updated_at timestamptz not null default now()
);

alter table public.app_settings enable row level security;

drop policy if exists "Authenticated users can read app settings" on public.app_settings;
create policy "Authenticated users can read app settings"
  on public.app_settings for select
  to authenticated
  using (true);

drop policy if exists "Service role can manage app settings" on public.app_settings;
create policy "Service role can manage app settings"
  on public.app_settings for all
  to service_role
  using (true)
  with check (true);

insert into public.app_settings (key, value)
values (
  'coin_economy',
  '{
    "coinsPerVote": 0,
    "coinsPerArgument": 0,
    "transferFee": 10,
    "supportAmounts": [10, 25, 50, 100],
    "boostTiers": [
      {
        "label": "24 Èdtan",
        "tier": "24h",
        "coins": 150,
        "desc": "Vizibilite × 2 pandan 24 èdtan"
      },
      {
        "label": "4 Jou",
        "tier": "4d",
        "coins": 350,
        "desc": "Vizibilite × 5 pandan 4 jou"
      },
      {
        "label": "1 Semèn",
        "tier": "1w",
        "coins": 550,
        "desc": "Vizibilite × 10 pandan 1 semèn"
      }
    ],
    "coinPacks": [
      {
        "coins": 1000,
        "price": 999,
        "label": "$9.99",
        "savings": "",
        "popular": false
      },
      {
        "coins": 2500,
        "price": 1999,
        "label": "$19.99",
        "savings": "Ekonomize 20%",
        "popular": true
      },
      {
        "coins": 5000,
        "price": 3499,
        "label": "$34.99",
        "savings": "Ekonomize 25%",
        "popular": false
      },
      {
        "coins": 10000,
        "price": 6499,
        "label": "$64.99",
        "savings": "Ekonomize 30%",
        "popular": false
      },
      {
        "coins": 25000,
        "price": 14999,
        "label": "$149.99",
        "savings": "Ekonomize 40%",
        "popular": false
      }
    ]
  }'::jsonb
)
on conflict (key) do nothing;
