-- Rename onboarding mentor JT → TT so existing assignments keep matching the
-- dropdown (ONBOARDING_MENTORS in superadmin999.html). Idempotent.
UPDATE public.planners
SET onboarding_mentor = 'TT'
WHERE onboarding_mentor = 'JT';

-- Verify:
--   SELECT onboarding_mentor, count(*) FROM public.planners
--     WHERE onboarding_mentor IS NOT NULL GROUP BY 1 ORDER BY 1;
