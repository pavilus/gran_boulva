-- Make poster/share URLs optional so option-only generation can still populate the gallery
ALTER TABLE public.matchup_image_sets
  ALTER COLUMN poster_image_url DROP NOT NULL,
  ALTER COLUMN share_image_url DROP NOT NULL;

-- Backfill gallery rows from existing matchup_options image pairs
-- (pairs where both A and B have image_url but no image_set row exists yet)
INSERT INTO public.matchup_image_sets (matchup_id, option_a_image_url, option_b_image_url, poster_image_url, share_image_url, model)
SELECT
  oa.matchup_id,
  oa.image_url  AS option_a_image_url,
  ob.image_url  AS option_b_image_url,
  NULL          AS poster_image_url,
  NULL          AS share_image_url,
  'gpt-image-1' AS model
FROM
  public.matchup_options oa
  JOIN public.matchup_options ob
    ON  ob.matchup_id  = oa.matchup_id
    AND ob.option_label = 'B'
WHERE
  oa.option_label = 'A'
  AND oa.image_url IS NOT NULL AND oa.image_url <> ''
  AND ob.image_url IS NOT NULL AND ob.image_url <> ''
  AND NOT EXISTS (
    SELECT 1 FROM public.matchup_image_sets mis WHERE mis.matchup_id = oa.matchup_id
  );
