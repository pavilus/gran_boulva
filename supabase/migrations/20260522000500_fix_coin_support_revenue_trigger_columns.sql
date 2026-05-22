-- Coin transaction schema uses from_user_id/to_user_id/transaction_type.
-- The creator revenue trigger still referenced older gifting columns, which
-- breaks every coin transaction insert, including daily coin claims.
create or replace function public.trg_coin_support_revenue()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.transaction_type = 'support'
     and new.to_user_id is not null then
    perform public.record_creator_revenue(
      new.to_user_id,
      new.from_user_id,
      'argument_support',
      new.amount::bigint,
      'coin_transactions',
      new.id
    );
  end if;

  return new;
end;
$$;
