-- ============================================================================
-- CS console — bond-inquiry quick replies (bank transfer + PayPay QR)
--
-- The planner-facing bond message asks about amount / refund terms / how to pay.
-- The bond can be paid two ways: a bank transfer, or a PayPay QR code. These
-- chips let a CS agent answer in one tap (overview), explain each point, send
-- bank details OR a PayPay QR, plus a "tell me when you're ready" opener.
--
-- The console also ships these in QUICK_REPLIES_DEFAULTS (supercs999.html), but
-- defaults only auto-seed when the table has NO system chips yet. Since the live
-- table is already seeded, run this to (re)sync the bond chips.
--
-- Idempotent: deletes the 5 bond system chips by key, then re-inserts the
-- current set — so re-running (or running after an earlier version) is safe.
-- Custom chips (is_system = false) and other defaults are untouched.
-- ============================================================================

DELETE FROM public.cs_quick_replies
WHERE is_system = true
  AND key IN ('bond_overview','bond_ready','bond_refund_terms','bond_transfer_method','bond_paypay');

INSERT INTO public.cs_quick_replies (lang, key, label, body, sort_order, is_system)
VALUES
  ('ja','bond_overview', '💬 保証金のご案内',
    E'{first_name}さん、お問い合わせありがとうございます。返金対象保証金についてご案内いたします。\n\n■ 金額：[金額]（ご依頼内容に記載の金額です）\n■ 返金条件：すべてのプランを期限内に提出し、内容確認・承認が完了した時点で、保証金は報酬とともに全額返金されます。\n■ お手続き方法：銀行振込またはPayPayのQRコードがご利用いただけます。ご準備が整いましたらお知らせください。ご希望の方法に応じて、振込先またはPayPayのQRコードと、照合用の参照コードをお送りします。お手続き後、完了画面のスクリーンショットをこのチャットへお送りいただければ、確認後にロックを解除いたします。\n\nご不明な点がございましたら、お気軽にお知らせください。', 16, true),
  ('ja','bond_ready', '🏦 準備ができたらご案内',
    E'{first_name}さん、返金対象保証金のお手続きのご準備が整いましたら、お知らせください。銀行振込またはPayPayのQRコードがご利用いただけます。ご希望の方法に応じて、振込先またはPayPayのQRコードと、照合用の参照コードをすぐにお送りいたします。', 17, true),
  ('ja','bond_refund_terms', '↩️ 返金条件',
    E'返金条件についてご案内いたします。すべてのプランを期限内に提出し、内容確認・承認が完了した時点で、返金対象保証金は報酬とともに全額返金されます。なお、期限超過・未対応・未納品などが確認された場合は、返金対象外となる場合があります。', 18, true),
  ('ja','bond_transfer_method', '💳 お手続き方法（振込/PayPay）',
    E'保証金のお手続き方法は2通りございます。\n\n①銀行振込：お送りする銀行口座へお振込みください。\n②PayPay：お送りするQRコードを読み取ってお手続きください。\n\nいずれの場合も、完了画面のスクリーンショットをこのチャットへお送りください。確認後、プランのロックを解除いたします。', 19, true),
  ('ja','bond_paypay', '📱 PayPay QRコード',
    E'{first_name}さん、PayPayでのお手続きですね。こちらのQRコードを読み取り、金額[金額]でお手続きください。\n参照コード：BOND-{set_num}-{planner_short}\nお手続き後、完了画面のスクリーンショットをこのチャットへお送りください。確認後、プランのロックを解除いたします。', 20, true),
  ('en','bond_overview', '💬 Bond overview',
    E'Hi {first_name}, thanks for reaching out. Here''s an overview of the refundable bond:\n\n■ Amount: [amount] (as shown in your brief)\n■ Refund terms: submit all plans on time and, once they pass review and approval, the bond is refunded in full together with your reward.\n■ How to complete it: you can use a bank transfer or a PayPay QR code. Just let us know when you''re ready and we''ll send either the bank details or the PayPay QR, plus a reference code. After that, post a screenshot of the completed payment here and we''ll unlock the plan once it''s confirmed.\n\nHappy to help with anything else!', 16, true),
  ('en','bond_ready', '🏦 Send details when ready',
    E'Hi {first_name}, whenever you''re ready to handle the refundable bond, just let us know. You can use a bank transfer or a PayPay QR code — we''ll send the bank details or the PayPay QR, plus a reference code, right away.', 17, true),
  ('en','bond_refund_terms', '↩️ Refund terms',
    E'Here are the refund terms: submit all plans on time and, once they pass review and approval, the refundable bond is returned in full along with your reward. If deadlines are missed or work is left unhandled or undelivered, the bond may become non-refundable.', 18, true),
  ('en','bond_transfer_method', '💳 How to pay (transfer / PayPay)',
    E'There are two ways to complete the bond:\n\n1) Bank transfer — send it to the bank details we provide.\n2) PayPay — scan the QR code we send you.\n\nEither way, post a screenshot of the completed payment here and we''ll unlock the plan once it''s confirmed.', 19, true),
  ('en','bond_paypay', '📱 PayPay QR',
    E'Hi {first_name}, sure — to pay by PayPay, scan the QR code here and complete it for [amount].\nReference: BOND-{set_num}-{planner_short}\nAfter that, post a screenshot of the completed payment here and we''ll unlock the plan once it''s confirmed.', 20, true);

-- Verify:
--   SELECT lang, key, label FROM public.cs_quick_replies
--   WHERE key LIKE 'bond_%' ORDER BY lang, sort_order;
