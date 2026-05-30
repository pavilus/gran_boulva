-- email_event_mappings: maps event slugs to email templates
CREATE TABLE IF NOT EXISTS public.email_event_mappings (
  event_slug    TEXT PRIMARY KEY,
  template_id   UUID REFERENCES public.email_templates(id) ON DELETE SET NULL,
  enabled       BOOLEAN NOT NULL DEFAULT false,
  label_ht      TEXT NOT NULL,
  description_ht TEXT,
  category      TEXT NOT NULL DEFAULT 'general'
);

GRANT ALL ON TABLE public.email_event_mappings TO service_role;

INSERT INTO public.email_event_mappings (event_slug, label_ht, description_ht, category) VALUES
  ('email_confirmed',       'Konfimason Imèl',         'Voye lè itilizatè a konfime adrès imèl li',              'kont'),
  ('password_reset',        'Reyinityalizasyon Modpas', 'Voye lè yon moun mande reyinitye modpas li',             'kont'),
  ('coin_purchase',         'Acha Coins',               'Voye lè yon itilizatè achte yon pakè coins',             'peman'),
  ('founding_supporter',    'Kreyatè Fondatè',          'Voye lè yon moun peye pou soutni Gran Boulva',           'peman'),
  ('waitlist_joined',       'Enskri nan Lis Datant',    'Voye lè yon moun enskri nan lis datant la',             'peman'),
  ('battle_challenge',      'Defi Batay',               'Voye lè yon moun defi yon lòt pou yon debat',           'kominotè'),
  ('battle_result',         'Rezilta Batay',            'Voye rezilta batay la bay toulede patisipan',            'kominotè'),
  ('verification_approved', 'Verifikasyon Apwouve',     'Voye lè demann verifikasyon an apwouve',                 'kominotè'),
  ('verification_rejected', 'Verifikasyon Refize',      'Voye lè demann verifikasyon an refize',                  'kominotè'),
  ('creator_tier_upgrade',  'Nivo Kreyatè Monte',       'Voye lè nivo kreyatè yon itilizatè monte otomatikman',  'kominotè')
ON CONFLICT (event_slug) DO NOTHING;
