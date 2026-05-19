alter table public.ai_generated_drafts
  add column if not exists popularity_score  numeric,
  add column if not exists virality_score    numeric,
  add column if not exists uniqueness_score  numeric,
  add column if not exists relevance_score   numeric,
  add column if not exists trending_keywords text[],
  add column if not exists detected_entities text[],
  add column if not exists selection_reason  text,
  add column if not exists source_platform   text;
