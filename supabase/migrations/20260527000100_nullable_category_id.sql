-- Allow null category_id on matchups and predictions
-- The AI Scout sometimes can't match a category name exactly
ALTER TABLE public.matchups ALTER COLUMN category_id DROP NOT NULL;
ALTER TABLE public.predictions ALTER COLUMN category_id DROP NOT NULL;
