-- Grant service_role access to all tables used by the admin dashboard
GRANT ALL ON TABLE public.ai_generated_drafts TO service_role;
GRANT ALL ON TABLE public.matchups TO service_role;
GRANT ALL ON TABLE public.matchup_options TO service_role;
GRANT ALL ON TABLE public.categories TO service_role;
GRANT ALL ON TABLE public.votes TO service_role;
GRANT ALL ON TABLE public.arguments TO service_role;
GRANT ALL ON TABLE public.reports TO service_role;
GRANT ALL ON TABLE public.payments TO service_role;
GRANT ALL ON TABLE public.predictions TO service_role;
GRANT ALL ON TABLE public.notifications TO service_role;
GRANT ALL ON TABLE public.boosts TO service_role;
GRANT ALL ON TABLE public.moderation_logs TO service_role;
