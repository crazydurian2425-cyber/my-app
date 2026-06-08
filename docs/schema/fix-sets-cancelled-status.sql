-- ============================================================================
-- Allow status = 'cancelled' on public.sets (admin "Close set" teardown).
--
-- Bug: clicking Close on Active sets fired
--   PATCH /rest/v1/sets?id=eq.<id>  { status: 'cancelled' }  → 400 Bad Request
-- because the LIVE sets.status CHECK constraint was rebuilt at some point with
-- only ('open','claimed','completed') and never got 'cancelled' — even though
-- closeSet() (superadmin999.html) was changed to write 'cancelled' (commit
-- c77e7a5). Classic schema drift: app code shipped, DB migration didn't.
--
-- This migration drops whatever CHECK constraint currently governs sets.status
-- (by discovering its real name, which varies) and recreates it with the FULL
-- vocabulary actually used across the app — both the live set ('open','claimed',
-- 'completed') and the original initial.sql set — plus 'cancelled'. Listing
-- extra values is harmless and future-proofs against either vocabulary.
--
-- Safe to run repeatedly. No existing row can violate the new (superset)
-- constraint, so it will not fail on live data.
-- ============================================================================

-- 1) Safety net: ensure completed_at exists (initial.sql has it; some drifted
--    environments may not). Harmless if already present.
alter table public.sets add column if not exists completed_at timestamptz;

-- 2) Drop the current status CHECK constraint, whatever it is named.
do $$
declare c record;
begin
  for c in
    select con.conname
    from   pg_constraint con
    join   pg_class      rel on rel.oid = con.conrelid
    join   pg_namespace  nsp on nsp.oid = rel.relnamespace
    where  nsp.nspname = 'public'
      and  rel.relname = 'sets'
      and  con.contype = 'c'
      and  pg_get_constraintdef(con.oid) ilike '%status%'
  loop
    execute format('alter table public.sets drop constraint %I', c.conname);
  end loop;
end $$;

-- 3) Recreate it as a superset that includes 'cancelled'.
alter table public.sets
  add constraint sets_status_check
  check (status in (
    'open','claimed','completed','cancelled',   -- live vocabulary + cancel
    'in_progress','paid','submitted'            -- legacy initial.sql values
  ));

-- ── Verify ──────────────────────────────────────────────────────────
-- Should show the new constraint definition including 'cancelled'.
select con.conname, pg_get_constraintdef(con.oid) as def
from   pg_constraint con
join   pg_class rel on rel.oid = con.conrelid
join   pg_namespace nsp on nsp.oid = rel.relnamespace
where  nsp.nspname = 'public' and rel.relname = 'sets' and con.contype = 'c'
  and  pg_get_constraintdef(con.oid) ilike '%status%';
