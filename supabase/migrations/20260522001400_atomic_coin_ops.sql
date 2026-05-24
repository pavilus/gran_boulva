-- ============================================================
-- Atomic coin operations for debate battles
-- Prevents race conditions in concurrent challenge/accept flows.
-- ============================================================

-- Atomically deduct coins from a user's balance.
-- Returns TRUE if the deduction succeeded (sufficient balance),
-- FALSE if the user did not have enough coins (no change made).
create or replace function public.lock_coins_for_battle(
  p_user_id uuid,
  p_amount   int
) returns boolean
  language plpgsql
  security definer
as $$
begin
  if p_amount <= 0 then
    return true;  -- nothing to deduct
  end if;
  update public.users
    set coin_balance = coin_balance - p_amount
  where id = p_user_id
    and coin_balance >= p_amount;
  return found;
end;
$$;

-- Atomically credit coins to a user's balance (no underflow risk).
create or replace function public.credit_coins(
  p_user_id uuid,
  p_amount   int
) returns void
  language plpgsql
  security definer
as $$
begin
  if p_amount <= 0 then
    return;
  end if;
  update public.users
    set coin_balance = coin_balance + p_amount
  where id = p_user_id;
end;
$$;

grant execute on function public.lock_coins_for_battle(uuid, int) to service_role;
grant execute on function public.credit_coins(uuid, int)          to service_role;
