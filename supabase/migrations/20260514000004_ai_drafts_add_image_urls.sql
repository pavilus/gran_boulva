alter table public.ai_generated_drafts
  add column if not exists image_url_a text,
  add column if not exists image_url_b text;
