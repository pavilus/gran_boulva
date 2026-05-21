update public.app_settings
   set value = value || jsonb_build_object(
     'coinPacks',
     '[
       {
         "coins": 100,
         "price": 99,
         "label": "$0.99",
         "savings": "",
         "popular": false
       },
       {
         "coins": 250,
         "price": 299,
         "label": "$2.99",
         "savings": "",
         "popular": false
       },
       {
         "coins": 550,
         "price": 499,
         "label": "$4.99",
         "savings": "Pi bon pase starter",
         "popular": false
       },
       {
         "coins": 1200,
         "price": 999,
         "label": "$9.99",
         "savings": "Ekonomize plis",
         "popular": false
       },
       {
         "coins": 2500,
         "price": 1999,
         "label": "$19.99",
         "savings": "Ekonomize 20%",
         "popular": true
       },
       {
         "coins": 5000,
         "price": 3499,
         "label": "$34.99",
         "savings": "Ekonomize 25%",
         "popular": false
       },
       {
         "coins": 10000,
         "price": 6499,
         "label": "$64.99",
         "savings": "Ekonomize 30%",
         "popular": false
       },
       {
         "coins": 25000,
         "price": 14999,
         "label": "$149.99",
         "savings": "Ekonomize 40%",
         "popular": false
       }
     ]'::jsonb
   ),
       updated_at = now()
 where key = 'coin_economy';
