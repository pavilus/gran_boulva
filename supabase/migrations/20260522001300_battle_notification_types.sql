-- Add battle notification types to the notification_type enum.
-- These are required for create-debate-battle and accept-debate-battle
-- edge functions to insert notification rows without a type-constraint error.

alter type public.notification_type add value if not exists 'battle_challenge';
alter type public.notification_type add value if not exists 'battle_accepted';
alter type public.notification_type add value if not exists 'battle_result';
