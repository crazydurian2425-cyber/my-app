-- ─────────────────────────────────────────────────────────────────────────
-- CS console speed: index the messages table
-- ─────────────────────────────────────────────────────────────────────────
-- The CS console reads a conversation with:
--     where conversation_id = ? order by created_at
-- and the realtime "new message" handler re-runs that SAME query on every
-- received message, while sends insert into the same table. Without an index on
-- (conversation_id, created_at), Postgres scans the WHOLE messages table on
-- every chat open, every received message, and pays index-maintenance cost on
-- inserts — which is the lag you're seeing on load + receive + send.
--
-- This index makes all three fast. It is purely additive — it does NOT change
-- any data or behaviour, only speeds up the existing queries.
--
-- HOW TO RUN (Supabase → SQL editor):
--   Just paste the two statements below and Run. They build with a brief lock
--   (a second or two on a normal-sized table) — unnoticeable.
--
--   NOTE: the Supabase SQL editor wraps your query in a transaction, and
--   CREATE INDEX CONCURRENTLY is NOT allowed inside a transaction (you'd get
--   "ERROR: 25001: CREATE INDEX CONCURRENTLY cannot run inside a transaction
--   block"). So we DON'T use CONCURRENTLY here. If you ever run this from psql
--   instead, you can add CONCURRENTLY to avoid the lock entirely.

CREATE INDEX IF NOT EXISTS idx_messages_conv_created
  ON public.messages (conversation_id, created_at);


-- OPTIONAL (cheap, also additive): speeds the 6s "new planner message" poller,
-- which filters by sender_type = 'planner' and created_at > <since>. Only
-- matters when realtime is down and the poller is the fallback.

CREATE INDEX IF NOT EXISTS idx_messages_planner_created
  ON public.messages (created_at)
  WHERE sender_type = 'planner';
