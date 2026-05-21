-- Extend category PNG icons to sport, food, health, music, education, technology
-- Uses name_en for reliable matching alongside name_ht fallback

UPDATE public.categories SET icon = '/categories/sport.png'
  WHERE name_en ILIKE '%sport%' OR name_ht ILIKE '%espò%' OR name_ht ILIKE '%sport%';

UPDATE public.categories SET icon = '/categories/food.png'
  WHERE name_en ILIKE '%food%' OR name_ht ILIKE '%manje%';

UPDATE public.categories SET icon = '/categories/health.png'
  WHERE name_en ILIKE '%health%' OR name_ht ILIKE '%sante%';

UPDATE public.categories SET icon = '/categories/music.png'
  WHERE name_en ILIKE '%music%' OR name_ht ILIKE '%mizik%';

UPDATE public.categories SET icon = '/categories/education.png'
  WHERE name_en ILIKE '%education%' OR name_ht ILIKE '%edikasyon%';

UPDATE public.categories SET icon = '/categories/technology.png'
  WHERE name_en ILIKE '%tech%' OR name_ht ILIKE '%teknoloji%';
