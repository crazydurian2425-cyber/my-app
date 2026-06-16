-- ============================================================================
-- Online-presence column for planners. The dashboard pings this every ~90s
-- while a planner has the tab open; the superadmin "Manage planners" list shows
-- "Online now" when it's within the last 3 minutes, else "Last seen 2h ago".
-- (last_login_at already exists and is written on each login.) Idempotent.
-- ============================================================================
ALTER TABLE public.planners ADD COLUMN IF NOT EXISTS last_seen_at timestamptz;
