-- Rename Tier 1 from "Kreyatè Monte" to "Kreyatè Entèmedyè" in the
-- refresh_creator_tier() notification strings.

create or replace function public.refresh_creator_tier(p_user_id uuid)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_score         integer;
  v_new_tier      integer;
  v_current_tier  integer;
  v_followers     integer;
  v_verification  text;
  v_verif_status  text;
  v_share_rate    numeric(3,2);
  v_monetization  boolean;
begin
  v_score := public.calculate_creator_score(p_user_id);

  select
    coalesce(followers_count, 0),
    coalesce(verification_type, ''),
    coalesce(verification_status, 'none')
  into v_followers, v_verification, v_verif_status
  from public.users where id = p_user_id;

  insert into public.creator_profiles (user_id, creator_tier, creator_score)
  values (p_user_id, 0, v_score)
  on conflict (user_id) do nothing;

  select creator_tier into v_current_tier
  from public.creator_profiles where user_id = p_user_id;

  v_new_tier := v_current_tier;

  -- 0 → 1 Entèmedyè: score >= 15 AND followers >= 10
  if v_current_tier = 0 and v_score >= 15 and v_followers >= 10 then
    v_new_tier := 1;
  end if;

  -- 1 → 2 Verified Creator: approved verification + score >= 35
  if v_current_tier <= 1
    and v_verif_status = 'approved'
    and v_verification in ('trusted_creator', 'public_figure', 'organization')
    and v_score >= 35
  then
    v_new_tier := 2;
  end if;

  -- Tiers 3 and 4 require admin confirmation

  -- Revenue share rates
  case v_new_tier
    when 1 then v_share_rate := 0.60; v_monetization := true;
    when 2 then v_share_rate := 0.70; v_monetization := true;
    when 3 then v_share_rate := 0.80; v_monetization := true;
    when 4 then v_share_rate := null; v_monetization := true;
    else         v_share_rate := 0.00; v_monetization := false;
  end case;

  update public.creator_profiles
  set
    creator_score      = v_score,
    creator_tier       = v_new_tier,
    score_updated_at   = now(),
    tier_updated_at    = case when v_new_tier <> v_current_tier then now() else tier_updated_at end,
    revenue_share_rate = case
      when v_new_tier = 4 then revenue_share_rate
      else coalesce(v_share_rate, 0.00)
    end,
    is_monetization_enabled = case
      when monetization_suspended then false
      else v_monetization
    end,
    updated_at = now()
  where user_id = p_user_id;

  -- Notify on tier upgrade
  if v_new_tier > v_current_tier then
    insert into public.notifications (user_id, type, title, body)
    values (
      p_user_id,
      'system',
      case v_new_tier
        when 1 then '🌱 Ou tounen Kreyatè Entèmedyè!'
        when 2 then '✅ Ou tounen Kreyatè Verifye!'
        when 3 then '⚡ Ou tounen Kreyatè Elit!'
        when 4 then '👑 Ou tounen Ikòn Kiltirèl!'
        else 'Nivo kreyatè ou chanje'
      end,
      case v_new_tier
        when 1 then 'Felisitasyon! Ou kounye a nan Nivo 1 — Kreyatè Entèmedyè. Ou ka touche 60% nan revni ou yo.'
        when 2 then 'Felisitasyon! Ou kounye a nan Nivo 2 — Kreyatè Verifye ak 70% revni.'
        when 3 then 'Ou rive nan somè a! Nivo 3 — Kreyatè Elit ak 80% revni.'
        when 4 then 'Ou se yon Ikòn Kiltirèl Gran Boulva. Mèsi pou enfliyans ou.'
        else ''
      end
    );
  end if;

  return v_new_tier;
end;
$$;

grant execute on function public.refresh_creator_tier(uuid) to authenticated, service_role;
