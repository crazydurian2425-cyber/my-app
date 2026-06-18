-- ============================================================================
-- Terms JA audit fixes — apply to the LIVE legal_docs row (slug='terms').
-- terms.html (the seed/fallback) is already updated; this pushes the same fixes
-- to the DB the public page actually reads. Targeted jsonb_set per key, so any
-- other edits made in the Terms editor are preserved. Idempotent.
--   s3.l1 (ja): restore 独自 (original); s2.l3 / s4.p1: PayPay+bank neutral (EN+JA),
--   drop honorific お; s4.pW (ja): 固定給 → 給与・固定報酬.
-- ============================================================================
UPDATE public.legal_docs SET dict =
  jsonb_set(
  jsonb_set(
  jsonb_set(
  jsonb_set(
  jsonb_set(
  jsonb_set(dict,
    '{ja,s4.pW}', to_jsonb(replace(dict->'ja'->>'s4.pW', '固定給を保証するものではありません', '給与・固定報酬を保証するものではありません'))),
    '{en,s2.l3}', to_jsonb('hold a valid payout method in your own name able to receive JPY (¥) — PayPay or a Japanese bank account;'::text)),
    '{en,s4.p1}', to_jsonb('Each set''s commission is displayed on your dashboard before you claim it. Payouts are made in <strong>Japanese yen (¥)</strong> to the payout method you set in your profile (PayPay or a Japanese bank transfer).'::text)),
    '{ja,s2.l3}', to_jsonb('報酬を受け取るための、ご本人名義の有効な支払い方法（PayPay または日本の銀行口座）を登録できること。'::text)),
    '{ja,s3.l1}', to_jsonb('<strong>品質：</strong>各旅程は、独自の内容で、事実に基づき、旅行者の依頼内容に合わせて作成する必要があります。'::text)),
    '{ja,s4.p1}', to_jsonb('各セットまたはプランごとの報酬額は、対応前にダッシュボードに表示されます。報酬は、プロフィールで設定した支払い方法に応じて、<strong>日本円（¥）</strong>にて支払われます。'::text))
WHERE slug = 'terms';

-- Verify: SELECT dict->'ja'->>'s3.l1', dict->'ja'->>'s4.pW', dict->'en'->>'s2.l3'
--   FROM public.legal_docs WHERE slug='terms';
