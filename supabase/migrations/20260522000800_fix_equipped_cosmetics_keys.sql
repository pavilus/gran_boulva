-- Fix get_equipped_cosmetics to return keys for all 4 equipped slots,
-- not just the profile_frame_key.

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
    'profile_frame_id',     eq.profile_frame_id,
    'profile_frame_key',    pf.key,
    'username_effect_id',   eq.username_effect_id,
    'username_effect_key',  ue.key,
    'profile_theme_id',     eq.profile_theme_id,
    'profile_theme_key',    pt.key,
    'cosmetic_badge_id',    eq.cosmetic_badge_id,
    'cosmetic_badge_key',   cb.key
  )
  into v_result
  from public.equipped_cosmetics eq
  left join public.cosmetic_items pf on pf.id = eq.profile_frame_id
  left join public.cosmetic_items ue on ue.id = eq.username_effect_id
  left join public.cosmetic_items pt on pt.id = eq.profile_theme_id
  left join public.cosmetic_items cb on cb.id = eq.cosmetic_badge_id
  where eq.user_id = p_user_id;

  return coalesce(v_result, '{}'::jsonb);
end;
$$;

grant execute on function public.get_equipped_cosmetics(uuid) to authenticated, anon;
