-- Update category icons from emoji to PNG paths
UPDATE public.categories SET icon = '/categories/fire.png'        WHERE name_ht ILIKE '%Popilè%'     OR name_ht ILIKE '%Popile%';
UPDATE public.categories SET icon = '/categories/society.png'     WHERE name_ht ILIKE '%Sosyete%'    OR name_ht ILIKE '%Sosi%';
UPDATE public.categories SET icon = '/categories/entertainment.png' WHERE name_ht ILIKE '%Divètisman%' OR name_ht ILIKE '%Divetis%';
UPDATE public.categories SET icon = '/categories/sport.png'       WHERE name_ht ILIKE '%Sport%';
UPDATE public.categories SET icon = '/categories/politics.png'    WHERE name_ht ILIKE '%Politik%';
UPDATE public.categories SET icon = '/categories/star.png'        WHERE name_ht ILIKE '%Tout%';
