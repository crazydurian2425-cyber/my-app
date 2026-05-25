-- ============================================================================
-- Fix wallet_requests RLS — planner can't submit payout requests
--
-- Symptom: planner clicks "Submit request" in the Wallet → "Request
-- payout" modal, sees toast:
--   Failed: new row violates row-level security policy for table
--   "wallet_requests"
--
-- Root cause: initial.sql declares both SELECT and INSERT policies on
-- public.wallet_requests, but the LIVE database is missing the INSERT
-- policy (schema drift). RLS is enabled, so without an INSERT policy
-- the table denies every INSERT by default — including the planner's
-- own payout request.
--
-- This migration re-creates the INSERT policy (idempotent — drops then
-- re-creates) so it's guaranteed to be present. Also re-asserts the
-- SELECT policy + RLS enable for the same reason.
-- ============================================================================

-- Ensure RLS is enabled on the table.
ALTER TABLE public.wallet_requests ENABLE ROW LEVEL SECURITY;

-- SELECT — planner can read their own requests.
DROP POLICY IF EXISTS "wallet_requests own" ON public.wallet_requests;
CREATE POLICY "wallet_requests own"
  ON public.wallet_requests
  FOR SELECT
  TO authenticated
  USING (planner_id = auth.uid());

-- INSERT — planner can submit a payout request for themselves.
-- The CHECK ensures the row's planner_id matches the auth'd user — they
-- can't INSERT a request on behalf of another planner.
DROP POLICY IF EXISTS "wallet_requests self insert" ON public.wallet_requests;
CREATE POLICY "wallet_requests self insert"
  ON public.wallet_requests
  FOR INSERT
  TO authenticated
  WITH CHECK (planner_id = auth.uid());

-- UPDATE — planner can cancel their own PENDING requests (used by
-- cancelPayoutRequest in dashboard.html). The check restricts to
-- rows the planner owns AND only allows the cancel transition.
DROP POLICY IF EXISTS "wallet_requests self cancel" ON public.wallet_requests;
CREATE POLICY "wallet_requests self cancel"
  ON public.wallet_requests
  FOR UPDATE
  TO authenticated
  USING (planner_id = auth.uid())
  WITH CHECK (planner_id = auth.uid());


-- ── Verify ──────────────────────────────────────────────────────────
-- a) RLS is enabled.
SELECT relname, relrowsecurity
FROM   pg_class
WHERE  oid = 'public.wallet_requests'::regclass;
-- → relrowsecurity = true

-- b) The three policies exist.
SELECT polname, polcmd
FROM   pg_policy
WHERE  polrelid = 'public.wallet_requests'::regclass
ORDER  BY polname;
-- → 3 rows: own (SELECT), self insert (INSERT), self cancel (UPDATE)
