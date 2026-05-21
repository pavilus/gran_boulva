alter table public.coin_transactions
  drop constraint if exists coin_transactions_transaction_type_check;

alter table public.coin_transactions
  add constraint coin_transactions_transaction_type_check
  check (
    transaction_type = any (array[
      'purchase',
      'boost',
      'boost_spend',
      'argument_support',
      'referral_reward',
      'transfer',
      'admin_reward',
      'refund',
      'signup_bonus',
      'daily_claim',
      'vote_spend',
      'vote_change_spend',
      'argument_post_spend'
    ])
  );
