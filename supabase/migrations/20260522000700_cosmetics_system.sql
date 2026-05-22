-- ─────────────────────────────────────────────────────────────────────────────
-- 20260522000700_cosmetics_system
-- Creates cosmetic_categories, cosmetic_items, user_cosmetics,
-- equipped_cosmetics tables; seeds initial data; adds RPCs.
-- ─────────────────────────────────────────────────────────────────────────────

-- ── 1. Tables ─────────────────────────────────────────────────────────────────

create table if not exists public.cosmetic_categories (
  id         uuid primary key default gen_random_uuid(),
  key        text unique not null,
  name_ht    text not null,
  name_en    text not null,
  sort_order integer not null default 0
);

alter table public.cosmetic_categories enable row level security;

create policy "Anyone can read cosmetic categories"
  on public.cosmetic_categories for select using (true);

grant select on public.cosmetic_categories to authenticated, anon;
grant all    on public.cosmetic_categories to service_role;

-- ──────────────────────────────────────────────────────────────────────────────

create table if not exists public.cosmetic_items (
  id             uuid primary key default gen_random_uuid(),
  category_id    uuid references public.cosmetic_categories(id),
  key            text unique not null,
  name_ht        text not null,
  name_en        text not null,
  description_ht text,
  description_en text,
  price_coins    integer not null,
  rarity         text not null check (rarity in ('common','rare','epic','legendary','founder')),
  asset_url      text,
  preview_url    text,
  is_active      boolean not null default true,
  created_at     timestamptz default now()
);

alter table public.cosmetic_items enable row level security;

create policy "Anyone can read active cosmetic items"
  on public.cosmetic_items for select using (is_active = true);

grant select on public.cosmetic_items to authenticated, anon;
grant all    on public.cosmetic_items to service_role;

-- ──────────────────────────────────────────────────────────────────────────────

create table if not exists public.user_cosmetics (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid not null references public.users(id) on delete cascade,
  cosmetic_item_id uuid not null references public.cosmetic_items(id),
  purchased_at     timestamptz default now(),
  source           text not null default 'purchase',
  status           text not null default 'active',
  unique(user_id, cosmetic_item_id)
);

alter table public.user_cosmetics enable row level security;

create policy "Users see own cosmetics"
  on public.user_cosmetics for select
  using (user_id = (select id from public.users where auth_user_id = auth.uid()));

create index if not exists user_cosmetics_user_id_idx on public.user_cosmetics(user_id);

grant select on public.user_cosmetics to authenticated;
grant all    on public.user_cosmetics to service_role;

-- ──────────────────────────────────────────────────────────────────────────────

create table if not exists public.equipped_cosmetics (
  id                  uuid primary key default gen_random_uuid(),
  user_id             uuid not null references public.users(id) on delete cascade unique,
  profile_frame_id    uuid references public.cosmetic_items(id),
  username_effect_id  uuid references public.cosmetic_items(id),
  profile_theme_id    uuid references public.cosmetic_items(id),
  cosmetic_badge_id   uuid references public.cosmetic_items(id),
  updated_at          timestamptz default now()
);

alter table public.equipped_cosmetics enable row level security;

create policy "Users see own equipped cosmetics"
  on public.equipped_cosmetics for select
  using (user_id = (select id from public.users where auth_user_id = auth.uid()));

create policy "Public can read equipped cosmetics"
  on public.equipped_cosmetics for select using (true);

create index if not exists equipped_cosmetics_user_id_idx on public.equipped_cosmetics(user_id);

grant select on public.equipped_cosmetics to authenticated, anon;
grant all    on public.equipped_cosmetics to service_role;

-- ── 2. Seed categories ────────────────────────────────────────────────────────

insert into public.cosmetic_categories (key, name_ht, name_en, sort_order) values
  ('profile_frame',    'Kadè Pwofil',  'Profile Frames',    1),
  ('username_effect',  'Efè Non',      'Username Effects',  2),
  ('profile_theme',    'Tèm Pwofil',   'Profile Themes',    3),
  ('cosmetic_badge',   'Badj Kosmetik','Cosmetic Badges',   4)
on conflict (key) do nothing;

-- ── 3. Seed initial items ─────────────────────────────────────────────────────

do $$
declare
  v_frame_cat   uuid;
  v_effect_cat  uuid;
  v_theme_cat   uuid;
  v_badge_cat   uuid;
begin
  select id into v_frame_cat  from public.cosmetic_categories where key = 'profile_frame';
  select id into v_effect_cat from public.cosmetic_categories where key = 'username_effect';
  select id into v_theme_cat  from public.cosmetic_categories where key = 'profile_theme';
  select id into v_badge_cat  from public.cosmetic_categories where key = 'cosmetic_badge';

  -- Profile frames
  insert into public.cosmetic_items
    (category_id, key, name_ht, name_en, description_ht, description_en, price_coins, rarity)
  values
    (v_frame_cat, 'frame_neon_violet',  'Neon Viyolèt', 'Neon Violet',
     'Yon kadè neon viyolèt ki bay pwofil ou yon aparans modèn.',
     'A neon violet frame that gives your profile a modern look.',
     100, 'rare'),
    (v_frame_cat, 'frame_kade_lo',      'Kadè Lò',      'Gold Frame',
     'Yon kadè lò prestijye pou moun ki merite.',
     'A prestigious gold frame for those who deserve it.',
     250, 'epic'),
    (v_frame_cat, 'frame_fon_ayiti',    'Fon Ayiti',    'Haiti Frame',
     'Yon kadè ki reprezante koulè drapo ayisyen.',
     'A frame representing the colors of the Haitian flag.',
     150, 'rare'),
    (v_frame_cat, 'frame_fondate',      'Fondate',      'Founder',
     'Rezève pou fondatè kominotè a. Pa kapab achte.',
     'Reserved for community founders. Cannot be purchased.',
     0, 'founder'),
    (v_frame_cat, 'frame_glorye',       'Glorye',       'Glorious',
     'Yon kadè legendè pou chanpyon yo.',
     'A legendary frame for champions.',
     500, 'legendary')
  on conflict (key) do nothing;

  -- Username effects
  insert into public.cosmetic_items
    (category_id, key, name_ht, name_en, description_ht, description_en, price_coins, rarity)
  values
    (v_effect_cat, 'effect_briyan',   'Briyan',   'Shining',
     'Non ou ap klere tankou zetwal.',
     'Your username will shine like a star.',
     75, 'common'),
    (v_effect_cat, 'effect_gradiyan', 'Gradiyan', 'Gradient',
     'Non ou afiche ak koulè gradiyan viyolèt.',
     'Your username displays with a purple gradient color.',
     200, 'rare')
  on conflict (key) do nothing;

  -- Profile themes
  insert into public.cosmetic_items
    (category_id, key, name_ht, name_en, description_ht, description_en, price_coins, rarity)
  values
    (v_theme_cat, 'theme_nwit',   'Tèm Nwit',  'Night Theme',
     'Yon tèm nwa fon ak aksan blou.',
     'A deep dark theme with blue accents.',
     50, 'common'),
    (v_theme_cat, 'theme_woyal',  'Tèm Woyal', 'Royal Theme',
     'Yon tèm woyal viyolèt ak or.',
     'A royal purple and gold theme.',
     150, 'rare')
  on conflict (key) do nothing;

  -- Cosmetic badges
  insert into public.cosmetic_items
    (category_id, key, name_ht, name_en, description_ht, description_en, price_coins, rarity)
  values
    (v_badge_cat, 'badge_kouwon', 'Kouwòn',  'Crown',
     'Yon kouwon devan non ou pou montre otorite ou.',
     'A crown before your name to show your authority.',
     300, 'epic'),
    (v_badge_cat, 'badge_dife',   'Dife',    'Fire',
     'Yon flam dife pou montre ke ou cho nan kominotè a.',
     'A flame to show you are hot in the community.',
     200, 'rare')
  on conflict (key) do nothing;
end;
$$;

-- ── 4. RPC: get_cosmetics_store ───────────────────────────────────────────────

create or replace function public.get_cosmetics_store()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id  uuid;
  v_result   jsonb;
begin
  select id into v_user_id
  from public.users
  where auth_user_id = auth.uid();

  select jsonb_agg(
    jsonb_build_object(
      'id',             ci.id,
      'key',            ci.key,
      'category_id',    ci.category_id,
      'category_key',   cc.key,
      'name_ht',        ci.name_ht,
      'name_en',        ci.name_en,
      'description_ht', ci.description_ht,
      'description_en', ci.description_en,
      'price_coins',    ci.price_coins,
      'rarity',         ci.rarity,
      'asset_url',      ci.asset_url,
      'preview_url',    ci.preview_url,
      'is_owned',       (uc.id is not null),
      'is_equipped',    (
        case cc.key
          when 'profile_frame'   then (eq.profile_frame_id   = ci.id)
          when 'username_effect' then (eq.username_effect_id = ci.id)
          when 'profile_theme'   then (eq.profile_theme_id   = ci.id)
          when 'cosmetic_badge'  then (eq.cosmetic_badge_id  = ci.id)
          else false
        end
      )
    )
    order by cc.sort_order, ci.rarity desc, ci.price_coins
  )
  into v_result
  from public.cosmetic_items ci
  join public.cosmetic_categories cc on cc.id = ci.category_id
  left join public.user_cosmetics uc
    on uc.cosmetic_item_id = ci.id and uc.user_id = v_user_id
  left join public.equipped_cosmetics eq
    on eq.user_id = v_user_id
  where ci.is_active = true;

  return coalesce(v_result, '[]'::jsonb);
end;
$$;

grant execute on function public.get_cosmetics_store() to authenticated;

-- ── 5. RPC: purchase_cosmetic ─────────────────────────────────────────────────

create or replace function public.purchase_cosmetic(p_cosmetic_item_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id   uuid;
  v_balance   integer;
  v_price     integer;
  v_name      text;
  v_rarity    text;
  v_already   boolean;
begin
  select id into v_user_id
  from public.users
  where auth_user_id = auth.uid();

  if v_user_id is null then
    return '{"ok":false,"error":"User not found"}'::jsonb;
  end if;

  -- fetch item
  select price_coins, name_ht, rarity
  into v_price, v_name, v_rarity
  from public.cosmetic_items
  where id = p_cosmetic_item_id and is_active = true;

  if v_price is null then
    return '{"ok":false,"error":"Item not found"}'::jsonb;
  end if;

  -- founder items cannot be purchased
  if v_rarity = 'founder' then
    return '{"ok":false,"error":"This item cannot be purchased"}'::jsonb;
  end if;

  -- check already owned
  select exists(
    select 1 from public.user_cosmetics
    where user_id = v_user_id and cosmetic_item_id = p_cosmetic_item_id
  ) into v_already;

  if v_already then
    return '{"ok":false,"error":"Already owned"}'::jsonb;
  end if;

  -- check balance
  select coin_balance into v_balance from public.users where id = v_user_id;

  if v_balance < v_price then
    return '{"ok":false,"error":"Insufficient coins"}'::jsonb;
  end if;

  -- deduct
  update public.users
  set coin_balance = coin_balance - v_price
  where id = v_user_id;

  -- log transaction
  insert into public.coin_transactions
    (user_id, amount, transaction_type, description)
  values
    (v_user_id, -v_price, 'cosmetic_purchase', 'Cosmetic purchase: ' || v_name);

  -- grant ownership
  insert into public.user_cosmetics
    (user_id, cosmetic_item_id, source)
  values
    (v_user_id, p_cosmetic_item_id, 'purchase');

  return jsonb_build_object('ok', true, 'item_name', v_name);
end;
$$;

grant execute on function public.purchase_cosmetic(uuid) to authenticated;

-- ── 6. RPC: equip_cosmetic ────────────────────────────────────────────────────

create or replace function public.equip_cosmetic(p_slot text, p_cosmetic_item_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id  uuid;
  v_owned    boolean;
  v_cat_key  text;
begin
  select id into v_user_id
  from public.users
  where auth_user_id = auth.uid();

  if v_user_id is null then
    return '{"ok":false,"error":"User not found"}'::jsonb;
  end if;

  -- verify ownership (or founder item granted)
  select exists(
    select 1 from public.user_cosmetics
    where user_id = v_user_id and cosmetic_item_id = p_cosmetic_item_id
  ) into v_owned;

  if not v_owned then
    return '{"ok":false,"error":"Item not owned"}'::jsonb;
  end if;

  -- validate slot
  if p_slot not in ('profile_frame','username_effect','profile_theme','cosmetic_badge') then
    return '{"ok":false,"error":"Invalid slot"}'::jsonb;
  end if;

  -- upsert equipped_cosmetics
  insert into public.equipped_cosmetics (user_id, profile_frame_id, username_effect_id, profile_theme_id, cosmetic_badge_id, updated_at)
  values (
    v_user_id,
    case when p_slot = 'profile_frame'   then p_cosmetic_item_id else null end,
    case when p_slot = 'username_effect' then p_cosmetic_item_id else null end,
    case when p_slot = 'profile_theme'   then p_cosmetic_item_id else null end,
    case when p_slot = 'cosmetic_badge'  then p_cosmetic_item_id else null end,
    now()
  )
  on conflict (user_id) do update set
    profile_frame_id   = case when p_slot = 'profile_frame'   then p_cosmetic_item_id else equipped_cosmetics.profile_frame_id   end,
    username_effect_id = case when p_slot = 'username_effect' then p_cosmetic_item_id else equipped_cosmetics.username_effect_id end,
    profile_theme_id   = case when p_slot = 'profile_theme'   then p_cosmetic_item_id else equipped_cosmetics.profile_theme_id   end,
    cosmetic_badge_id  = case when p_slot = 'cosmetic_badge'  then p_cosmetic_item_id else equipped_cosmetics.cosmetic_badge_id  end,
    updated_at         = now();

  return '{"ok":true}'::jsonb;
end;
$$;

grant execute on function public.equip_cosmetic(text, uuid) to authenticated;

-- ── 7. RPC: get_equipped_cosmetics ───────────────────────────────────────────

create or replace function public.get_equipped_cosmetics(p_user_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_result jsonb;
begin
  select jsonb_build_object(
    'profile_frame_id',    eq.profile_frame_id,
    'profile_frame_key',   pf.key,
    'username_effect_id',  eq.username_effect_id,
    'profile_theme_id',    eq.profile_theme_id,
    'cosmetic_badge_id',   eq.cosmetic_badge_id
  )
  into v_result
  from public.equipped_cosmetics eq
  left join public.cosmetic_items pf on pf.id = eq.profile_frame_id
  where eq.user_id = p_user_id;

  return coalesce(v_result, '{}'::jsonb);
end;
$$;

grant execute on function public.get_equipped_cosmetics(uuid) to authenticated, anon;
