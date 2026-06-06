-- ============================================================================
-- Keep conversations' summary columns in sync on every message insert.
--
-- Symptom: a planner sends a chat message, but the CS console inbox shows
-- "No messages yet", no unread badge, and no notification — until the agent
-- manually opens the conversation. New messages don't surface on their own.
--
-- Root cause: the live DB has NO trigger maintaining
-- conversations.last_message_at / last_message_preview / last_sender_type /
-- unread_for_cs / unread_for_planner. Inserting into `messages` left those
-- columns frozen at conversation-creation time (last_message_preview = NULL,
-- last_message_at = created_at, unread_for_cs = 0). The CS inbox reads exactly
-- those columns (loadConversations orders by last_message_at, previews from
-- last_message_preview, badges from unread_for_cs), so planner messages never
-- showed. Realtime used to mask this by bumping the inbox client-side, but the
-- CS console connects with the public (anon) key and Supabase Realtime denies
-- it `messages` row events under RLS — so once realtime stopped delivering,
-- the missing trigger was exposed.
--
-- SECURITY DEFINER so the trigger can UPDATE conversations even when the row
-- was inserted by a planner (planners have no direct UPDATE on conversations
-- under RLS). Idempotent.
-- ============================================================================

create or replace function public.bump_conversation_on_message()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.conversations c set
    last_message_at      = new.created_at,
    last_message_preview = left(coalesce(nullif(new.body, ''), '📷 Image'), 140),
    last_sender_type     = new.sender_type,
    unread_for_cs        = case when new.sender_type = 'planner'
                                then coalesce(c.unread_for_cs, 0) + 1
                                else c.unread_for_cs end,
    unread_for_planner   = case when new.sender_type = 'cs'
                                then coalesce(c.unread_for_planner, 0) + 1
                                else c.unread_for_planner end
  where c.id = new.conversation_id;
  return new;
end;
$$;

drop trigger if exists trg_bump_conversation on public.messages;
create trigger trg_bump_conversation
  after insert on public.messages
  for each row execute function public.bump_conversation_on_message();

-- ── Backfill existing conversations so the inbox immediately reflects real
--    last-message data (otherwise old conversations keep showing
--    "No messages yet" until their next message). Unread counts are left as-is
--    — the trigger handles them going forward.
update public.conversations c set
  last_message_at      = m.created_at,
  last_message_preview = left(coalesce(nullif(m.body, ''), '📷 Image'), 140),
  last_sender_type     = m.sender_type
from (
  select distinct on (conversation_id)
         conversation_id, created_at, body, sender_type
  from   public.messages
  order  by conversation_id, created_at desc
) m
where m.conversation_id = c.id;

-- ── Verify ──────────────────────────────────────────────────────────
-- a) Trigger exists.
SELECT tgname FROM pg_trigger WHERE tgrelid = 'public.messages'::regclass AND NOT tgisinternal;
-- → trg_bump_conversation

-- b) A conversation with messages now shows a real preview + recent timestamp.
SELECT id, last_message_preview, last_message_at, unread_for_cs
FROM   public.conversations
ORDER  BY last_message_at DESC NULLS LAST
LIMIT  5;
