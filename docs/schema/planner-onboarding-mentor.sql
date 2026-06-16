-- ============================================================================
-- Tag each planner with their onboarding mentor (FCKING / JT / KIT), set inline
-- from the superadmin "Manage planners" list. Free text so mentors can be added
-- later by editing ONBOARDING_MENTORS in superadmin999.html. Idempotent.
-- ============================================================================
ALTER TABLE public.planners ADD COLUMN IF NOT EXISTS onboarding_mentor text;
