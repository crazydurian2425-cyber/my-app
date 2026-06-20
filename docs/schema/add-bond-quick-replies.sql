-- ============================================================================
-- CS console — add bond-inquiry quick replies
--
-- The planner-facing bond message asks about three things at once:
--   「保証金の金額、返金条件、振込方法についてご案内をお願いいたします。」
-- These chips let a CS agent answer in one tap (overview), or address each
-- point individually, plus a "tell me when you're ready and I'll send the
-- bank details" opener.
--
-- The console also ships these in QUICK_REPLIES_DEFAULTS (supercs999.html), but
-- defaults only auto-seed when the table has NO system chips yet. Since the live
-- table is already seeded, run this to add the four new chips (EN + JA).
--
-- Idempotent: each row is inserted only if its (lang, key) isn't already there,
-- so re-running — or running after an auto-seed — is safe.
-- ============================================================================

INSERT INTO public.cs_quick_replies (lang, key, label, body, sort_order, is_system)
SELECT v.lang, v.key, v.label, v.body, v.sort_order, true
FROM (VALUES
  ('ja','bond_overview',        '💬 保証金のご案内',
    E'{first_name}さん、お問い合わせありがとうございます。返金対象保証金についてご案内いたします。\n\n■ 金額：[金額]（ご依頼内容に記載の金額です）\n■ 返金条件：すべてのプランを期限内に提出し、内容確認・承認が完了した時点で、保証金は報酬とともに全額返金されます。\n■ 振込方法：ご準備が整いましたらお知らせください。振込先（銀行口座）と照合用の参照コードをお送りします。お振込後、振込完了画面のスクリーンショットをこのチャットへお送りいただければ、確認後にロックを解除いたします。\n\nご不明な点がございましたら、お気軽にお知らせください。', 16),
  ('ja','bond_ready',           '🏦 準備後に振込先を送付',
    E'{first_name}さん、返金対象保証金のお振込のご準備が整いましたら、お知らせください。振込先（銀行口座）と照合用の参照コードをすぐにお送りいたします。', 17),
  ('ja','bond_refund_terms',    '↩️ 返金条件',
    E'返金条件についてご案内いたします。すべてのプランを期限内に提出し、内容確認・承認が完了した時点で、返金対象保証金は報酬とともに全額返金されます。なお、期限超過・未対応・未納品などが確認された場合は、返金対象外となる場合があります。', 18),
  ('ja','bond_transfer_method', '💸 振込方法',
    E'振込方法についてご案内いたします。こちらからお送りする銀行口座へお振込みのうえ、振込完了画面のスクリーンショットをこのチャットへお送りください。確認後、プランのロックを解除いたします。', 19),
  ('en','bond_overview',        '💬 Bond overview',
    E'Hi {first_name}, thanks for reaching out. Here''s an overview of the refundable bond:\n\n■ Amount: [amount] (as shown in your brief)\n■ Refund terms: submit all plans on time and, once they pass review and approval, the bond is refunded in full together with your reward.\n■ Transfer: just let us know when you''re ready and we''ll send the bank details and a reference code. After transferring, post a screenshot of the completed transfer here and we''ll unlock the plan once it''s confirmed.\n\nHappy to help with anything else!', 16),
  ('en','bond_ready',           '🏦 Send details when ready',
    E'Hi {first_name}, whenever you''re ready to transfer the refundable bond, just let us know and we''ll send the bank details and a reference code right away.', 17),
  ('en','bond_refund_terms',    '↩️ Refund terms',
    E'Here are the refund terms: submit all plans on time and, once they pass review and approval, the refundable bond is returned in full along with your reward. If deadlines are missed or work is left unhandled or undelivered, the bond may become non-refundable.', 18),
  ('en','bond_transfer_method', '💸 Transfer method',
    E'For the transfer: send it to the bank details we provide, then post a screenshot of the completed transfer here. We''ll unlock the plan once it''s confirmed.', 19)
) AS v(lang, key, label, body, sort_order)
WHERE NOT EXISTS (
  SELECT 1 FROM public.cs_quick_replies q WHERE q.lang = v.lang AND q.key = v.key
);

-- Verify:
--   SELECT lang, key, label FROM public.cs_quick_replies
--   WHERE key LIKE 'bond_%' ORDER BY lang, sort_order;
