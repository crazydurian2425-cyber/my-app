-- ============================================================================
-- Add the account TYPE (預金種目: 普通 / 当座) for Japanese bank-transfer payouts.
--
-- Why: a Japanese domestic transfer (振込 / furikomi) is routed by
--   bank + branch + ACCOUNT TYPE + account number. The same branch can hold a
--   普通 (ordinary) and a 当座 (current) account under the same number, so the
--   type is part of the routing key — not cosmetic. We already store:
--     bank_name        = bank name        (e.g. 三菱UFJ銀行)
--     bank_branch_code = 3-digit branch   (e.g. 001)
--     bank_account     = account number   (e.g. 1234567)
--     bank_holder      = holder, katakana (e.g. ヤマダ タロウ)
--   This migration adds the missing piece.
--
-- The app degrades gracefully if this hasn't run yet (account type just won't
-- persist and defaults to 普通 on screen), but run it so 当座 accounts are
-- stored correctly. Safe to run once; idempotent.
-- ============================================================================

alter table public.planners add column if not exists bank_account_type text;  -- '普通' | '当座'

-- Backfill: existing bank-method planners default to 普通 (ordinary) — the
-- near-universal type for individuals.
update public.planners
set bank_account_type = '普通'
where payout_method = 'bank'
  and (bank_account_type is null or btrim(bank_account_type) = '');

-- ── VERIFY ──────────────────────────────────────────────────────────
select count(*)                                              as bank_planners,
       count(*) filter (where bank_account_type = '普通')    as futsu,
       count(*) filter (where bank_account_type = '当座')    as touza,
       count(*) filter (where bank_account_type is null)     as type_missing
from public.planners
where payout_method = 'bank';
