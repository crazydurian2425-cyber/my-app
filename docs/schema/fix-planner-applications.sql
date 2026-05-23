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


-- ── Verify ─────────────────────────────────────────────────────────────────
--   SELECT column_name, data_type
--   FROM information_schema.columns
--   WHERE table_schema='public' AND table_name='planner_applications'
--   ORDER BY ordinal_position;
--
--   SELECT public.check_application_exists('nobody@example.com');
--   -- → false
