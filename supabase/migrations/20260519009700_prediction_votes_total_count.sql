-- ─────────────────────────────────────────────────────────────────────────────
-- Keep predictions.total_votes in sync via trigger on prediction_votes.
-- ─────────────────────────────────────────────────────────────────────────────

create or replace function public.sync_prediction_vote_count()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if TG_OP = 'INSERT' then
    update public.predictions
       set total_votes = total_votes + 1
     where id = NEW.prediction_id;
  elsif TG_OP = 'DELETE' then
    update public.predictions
       set total_votes = greatest(0, total_votes - 1)
     where id = OLD.prediction_id;
  end if;
  return null;
end;
$$;

drop trigger if exists trg_sync_prediction_vote_count on public.prediction_votes;
create trigger trg_sync_prediction_vote_count
  after insert or delete on public.prediction_votes
  for each row execute function public.sync_prediction_vote_count();
