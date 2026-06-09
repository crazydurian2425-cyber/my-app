-- ============================================================================
-- Add a BANK (SEPA/IBAN) payout option alongside the existing crypto payout.
-- Model: ONE active method per planner (payout_method = 'crypto' | 'bank').
--
-- Problem this fixes: crypto currently HIJACKS the bank_* columns
--   bank_name        = stablecoin (USDT/USDC)
--   bank_branch_code = network (TRC20/…)
--   bank_account     = wallet address
-- so the same columns can't also hold a real IBAN. This migration gives crypto
-- its OWN columns, moves existing wallets into them, then frees the bank_*
-- columns for their natural meaning:
--   bank_account     = IBAN          (e.g. FR76 1621 8000 0140 1214 5377 309)
--   bank_holder      = account holder (e.g. Miroslav Conkal)
--   bank_branch_code = BIC / SWIFT    (e.g. BFBKFRP1)
--
-- Safe to run once. Wrapped in a transaction.
-- ============================================================================

begin;

-- 1) Dedicated crypto columns + the active-method flag.
alter table public.planners add column if not exists crypto_asset   text;  -- 'USDT' | 'USDC'
alter table public.planners add column if not exists crypto_network text;  -- 'TRC20' | 'ERC20' | …
alter table public.planners add column if not exists crypto_address text;  -- wallet address
alter table public.planners add column if not exists payout_method  text;  -- 'crypto' | 'bank'

-- 2) Move existing crypto wallets OUT of the overloaded bank_* columns into the
--    new crypto_* columns. "Has crypto" == a wallet address is present.
update public.planners
set crypto_asset   = nullif(btrim(bank_name), ''),
    crypto_network = coalesce(nullif(btrim(bank_branch_code), ''), 'TRC20'),
    crypto_address = nullif(btrim(bank_account), ''),
    payout_method  = 'crypto'
where bank_account is not null and btrim(bank_account) <> '';

-- 3) Now clear the bank_* columns we just copied FROM, so they start empty and
--    can hold real bank details. Only touch rows we migrated (crypto_address
--    now equals the old bank_account).
update public.planners
set bank_name        = null,
    bank_branch_code = null,
    bank_account     = null
where crypto_address is not null
  and crypto_address = btrim(bank_account);

-- 4) Default anyone with no method yet to 'crypto' (harmless; they have no
--    address either, so they'll still be prompted to set one).
update public.planners
set payout_method = 'crypto'
where payout_method is null;

commit;

-- ── VERIFY ──────────────────────────────────────────────────────────
-- Crypto data should now live in crypto_*, bank_* should be empty for everyone
-- (until planners start entering IBANs).
select count(*)                                            as planners,
       count(*) filter (where crypto_address is not null)  as with_crypto,
       count(*) filter (where bank_account   is not null)  as with_bank,
       count(*) filter (where payout_method = 'crypto')    as method_crypto,
       count(*) filter (where payout_method = 'bank')      as method_bank
from public.planners;
