alter table public.ai_generated_drafts
  add column if not exists combined_score numeric;
