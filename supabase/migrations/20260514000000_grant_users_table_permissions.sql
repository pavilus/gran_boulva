-- Grant necessary permissions on the users table
GRANT SELECT, UPDATE ON TABLE public.users TO authenticated;
GRANT SELECT, UPDATE ON TABLE public.users TO service_role;

-- Also ensure coin_transactions and coin_purchases have service_role grants
GRANT ALL ON TABLE public.coin_transactions TO service_role;
GRANT ALL ON TABLE public.coin_purchases TO service_role;
