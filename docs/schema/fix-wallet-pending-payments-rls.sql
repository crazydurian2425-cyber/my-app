-- ============================================================================
-- Fix wallet_pending_payments RLS — planner can't SEE platform invoices
--
-- Symptom: admin issues an invoice (Invoices → New invoice) and it shows in
-- the admin "Invoices owed to platform" list as PENDING, but the planner
-- sees NOTHING on their dashboard banner or Wallet "Invoices due to platform"
-- card.
--
-- Root cause: initial.sql declares a SELECT policy on
-- public.wallet_pending_payments, but the LIVE database is missing it
-- (schema drift — same issue that hit wallet_requests). RLS is enabled, so
-- with no SELECT policy the table denies every read by the authenticated
-- planner. The admin still sees rows because it queries with the service
-- role (bypasses RLS).
--
-- Idempotent: drops then re-creates so it's guaranteed present.
-- The planner only needs SELECT — invoices are created/updated by the admin
-- via the service role, never by the planner.
-- ============================================================================

ALTER TABLE public.wallet_pending_payments ENABLE ROW LEVEL SECURITY;

-- SELECT — planner can read their OWN invoices (banner + wallet card).
DROP POLICY IF EXISTS "wallet_pending_payments own" ON public.wallet_pending_payments;
CREATE POLICY "wallet_pending_payments own"
  ON public.wallet_pending_payments
  FOR SELECT
  TO authenticated
  USING (planner_id = auth.uid());

-- ── Verify ──────────────────────────────────────────────────────────
-- a) RLS enabled.
SELECT relname, relrowsecurity
FROM   pg_class
WHERE  oid = 'public.wallet_pending_payments'::regclass;
-- → relrowsecurity = true

-- b) The SELECT policy exists.
SELECT polname, polcmd
FROM   pg_policy
WHERE  polrelid = 'public.wallet_pending_payments'::regclass
ORDER  BY polname;
-- → at least one row: own (SELECT)
