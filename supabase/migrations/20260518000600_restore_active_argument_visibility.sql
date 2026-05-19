do $$
begin
  if not exists (
    select 1
      from pg_policies
     where schemaname = 'public'
       and tablename = 'arguments'
       and policyname = 'Authenticated users can read active arguments'
  ) then
    create policy "Authenticated users can read active arguments"
      on public.arguments
      for select
      to authenticated
      using (
        status = 'active'
      );
  end if;
end;
$$;
