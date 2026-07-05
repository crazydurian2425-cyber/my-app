-- ============================================================================
-- /supermentor999 — mentor tracker page.
-- New planner columns + three new tables (problems, problem steps, remarks).
-- All access goes through the /api/sb worker proxy (service-role key), same as
-- superadmin999 / supercs999 — RLS is enabled with NO policies so the public
-- anon key can never read or write any of this.
-- Idempotent: safe to re-run.
-- ============================================================================

-- ── Planner columns the mentor edits ────────────────────────────────────────
-- contact_channel  : 'LINE' | 'Discord' — which chat platform the planner is on
-- contact_account  : which of OUR accounts handles them (e.g. '@jj_line_01')
-- mentor_status    : the mentor's own pipeline label, independent of
--                    planners.status (active/suspended/pending stays untouched)
ALTER TABLE public.planners ADD COLUMN IF NOT EXISTS contact_channel text;
ALTER TABLE public.planners ADD COLUMN IF NOT EXISTS contact_account text;
ALTER TABLE public.planners ADD COLUMN IF NOT EXISTS mentor_status   text;

-- ── Problems: one row per issue the mentor is tracking on a planner ─────────
CREATE TABLE IF NOT EXISTS public.planner_problems (
  id          uuid primary key default gen_random_uuid(),
  planner_id  uuid not null references public.planners(id) on delete cascade,
  title       text not null,
  status      text not null default 'open'
              check (status in ('open','progress','resolved')),
  created_by  text,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- ── Progression steps: the running log under each problem ──────────────────
CREATE TABLE IF NOT EXISTS public.planner_problem_steps (
  id          uuid primary key default gen_random_uuid(),
  problem_id  uuid not null references public.planner_problems(id) on delete cascade,
  body        text not null,
  created_by  text,
  created_at  timestamptz not null default now()
);

-- ── Remarks: free-form tagged notes on a planner ────────────────────────────
CREATE TABLE IF NOT EXISTS public.planner_remarks (
  id          uuid primary key default gen_random_uuid(),
  planner_id  uuid not null references public.planners(id) on delete cascade,
  body        text not null,
  tag         text not null default 'general'
              check (tag in ('general','chase','payment','quality','praise','status')),
  created_by  text,
  created_at  timestamptz not null default now()
);

CREATE INDEX IF NOT EXISTS planner_problems_planner_idx     ON public.planner_problems(planner_id);
CREATE INDEX IF NOT EXISTS planner_problem_steps_problem_idx ON public.planner_problem_steps(problem_id);
CREATE INDEX IF NOT EXISTS planner_remarks_planner_idx      ON public.planner_remarks(planner_id, created_at DESC);

-- Lock the new tables down: RLS on, no policies → anon/authed clients get
-- nothing; only the worker's service-role key (which bypasses RLS) can touch
-- them. Planners can never see mentor remarks about themselves.
ALTER TABLE public.planner_problems      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.planner_problem_steps ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.planner_remarks       ENABLE ROW LEVEL SECURITY;

-- Verify:
--   SELECT column_name FROM information_schema.columns
--    WHERE table_name='planners' AND column_name IN ('contact_channel','contact_account','mentor_status');
--   SELECT count(*) FROM public.planner_problems;
--   SELECT count(*) FROM public.planner_remarks;
