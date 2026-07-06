-- ============================================================================
-- Read receipts for the CS chat — CS-console-only visibility.
-- messages.read_at = when the PLANNER first had the message on screen
-- (support.html stamps it while the tab is visible). The planner UI never
-- shows anything; only supercs999.html renders "Seen / Sent" ticks.
-- Idempotent: safe to re-run.
-- ============================================================================

ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS read_at timestamptz;

-- Security-definer RPC so the planner's anon-key client can ONLY set read_at
-- on non-planner messages inside their own conversation — it can't touch
-- bodies, other columns, or other planners' conversations, regardless of any
-- drift in the messages RLS policies on the live DB.
CREATE OR REPLACE FUNCTION public.jj_mark_cs_messages_read(p_conversation_id uuid)
RETURNS void
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  UPDATE public.messages m
     SET read_at = now()
   WHERE m.conversation_id = p_conversation_id
     AND m.read_at IS NULL
     AND m.sender_type IS DISTINCT FROM 'planner'
     AND EXISTS (
       SELECT 1 FROM public.conversations c
        WHERE c.id = p_conversation_id
          AND c.planner_id = auth.uid()
     );
$$;

REVOKE ALL ON FUNCTION public.jj_mark_cs_messages_read(uuid) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.jj_mark_cs_messages_read(uuid) TO authenticated;

-- Verify:
--   SELECT column_name FROM information_schema.columns
--    WHERE table_name='messages' AND column_name='read_at';
--   SELECT proname FROM pg_proc WHERE proname='jj_mark_cs_messages_read';
