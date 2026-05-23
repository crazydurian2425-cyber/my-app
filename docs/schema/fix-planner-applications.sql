-- ============================================================================
-- Fix /apply.html signup — two schema gaps:
--
--   1. planner_applications is missing columns the form tries to insert:
--      japan_depth, languages, heard_from, signup_ip, signup_country,
--      signup_city, signup_region, signup_isp. The INSERT fails 400/403
--      because those columns don't exist.
--
--   2. The /apply form pre-checks for duplicate applications via the RPC
--      check_application_exists(p_email text). That function isn't in
--      initial.sql — hence the 404 on the RPC call in the browser
--      console.
--
-- Idempotent — uses ADD COLUMN IF NOT EXISTS and CREATE OR REPLACE.
-- Safe to re-run.
-- ============================================================================


-- ── 1. Add the missing columns ─────────────────────────────────────────────
ALTER TABLE public.planner_applications
  ADD COLUMN IF NOT EXISTS japan_depth     TEXT,
  ADD COLUMN IF NOT EXISTS languages       TEXT[],
  ADD COLUMN IF NOT EXISTS heard_from      TEXT,
  -- IP geolocation snapshot captured at signup time. inet stores both v4
  -- and v6 cleanly; TEXT fallback is fine if you prefer to avoid the
  -- inet type.
  ADD COLUMN IF NOT EXISTS signup_ip       INET,
  ADD COLUMN IF NOT EXISTS signup_country  TEXT,
  ADD COLUMN IF NOT EXISTS signup_city     TEXT,
  ADD COLUMN IF NOT EXISTS signup_region   TEXT,
  ADD COLUMN IF NOT EXISTS signup_isp      TEXT;


-- ── 2. Duplicate-email check RPC ───────────────────────────────────────────
-- SECURITY DEFINER lets the anon role call it without needing SELECT
-- permission on the underlying table. Returns boolean only — no row
-- data leaks. Apply-form pre-checks this so the planner gets a friendly
-- "you've already applied" message instead of a generic INSERT error.
CREATE OR REPLACE FUNCTION public.check_application_exists(p_email text)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.planner_applications
    WHERE LOWER(email) = LOWER(p_email)
  );
$$;

-- Allow anon + authenticated to execute the RPC. SECURITY DEFINER
-- means the function runs with owner privileges regardless.
GRANT EXECUTE ON FUNCTION public.check_application_exists(text) TO anon, authenticated;


-- ── 3. Link auth user → application RPC ────────────────────────────────────
-- Anon role has INSERT but NOT UPDATE on planner_applications (RLS).
-- After auth.signUp succeeds in the apply form we need to patch the
-- just-inserted row with the new auth user's id. Direct .update() from
-- the browser would 403 — wrap it in a SECURITY DEFINER RPC that
-- targets ONLY the row matching the same email + user_id IS NULL
-- (so old historical rows with the same email can't be hijacked).
CREATE OR REPLACE FUNCTION public.link_application_user(p_email text, p_user_id uuid)
RETURNS void
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  UPDATE public.planner_applications
  SET    user_id = p_user_id
  WHERE  LOWER(email) = LOWER(p_email)
    AND  user_id IS NULL;
$$;

GRANT EXECUTE ON FUNCTION public.link_application_user(text, uuid) TO anon, authenticated;


-- ── 4. Re-create the public INSERT RLS policy ──────────────────────────────
-- The /apply form runs anonymously (browser → PostgREST as the `anon`
-- role). Initial.sql carried a "for insert with check (true)" policy
-- but if the DB was provisioned without it (or the policy was dropped
-- in a later migration), every signup throws code 42501:
--   "new row violates row-level security policy for table
--    planner_applications".
-- Re-assert RLS + a permissive INSERT policy targeting the anon AND
-- authenticated roles explicitly. The form never reads back so no
-- SELECT policy is granted - keeps the table closed to public reads.
ALTER TABLE public.planner_applications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "applications public insert" ON public.planner_applications;
CREATE POLICY "applications public insert"
  ON public.planner_applications
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

-- Verify:
--   SELECT polname, roles::text, cmd
--   FROM pg_policies WHERE schemaname='public' AND tablename='planner_applications';
--   -- Expect a row with cmd='INSERT' and roles like {anon,authenticated}.


-- ── Verify ─────────────────────────────────────────────────────────────────
--   SELECT column_name, data_type
--   FROM information_schema.columns
--   WHERE table_schema='public' AND table_name='planner_applications'
--   ORDER BY ordinal_position;
--
--   SELECT public.check_application_exists('nobody@example.com');
--   -- → false
