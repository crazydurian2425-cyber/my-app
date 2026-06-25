-- ============================================================================
-- CS console quick replies — English LABELS (for CS agents who don't read
-- Japanese) + bond payment methods expanded to THREE: bank transfer / PayPay QR
-- / PayPay phone number or ID. Adds a dedicated "PayPay phone / ID" chip.
--
-- WHY: CS agents pick chips by label. Every chip's LABEL becomes English while
-- the BODY stays Japanese (that's what the planner receives). The bond "how to
-- pay" wording now lists all three methods.
--
-- Chips live in public.cs_quick_replies (the console reads from there; the
-- hardcoded QUICK_REPLIES_DEFAULTS only auto-seed an EMPTY table). The live
-- table is already seeded, so run THIS to apply the changes.
--
-- Idempotent: safe to re-run. Custom chips (is_system = false) are untouched.
-- Phone/ID use [電話番号] / [PayPay ID] fill-in placeholders (like [金額]).
-- ============================================================================

-- 1) Bond chips — refresh every bond system chip (English label + 3-method
--    bodies) and add the new PayPay phone/ID chip. DELETE-then-INSERT by key.
DELETE FROM public.cs_quick_replies
WHERE is_system = true
  AND key IN ('bond_overview','bond_ready','bond_refund_terms','bond_transfer_method','bond_paypay','bond_paypay_phone');

INSERT INTO public.cs_quick_replies (lang, key, label, body, sort_order, is_system)
VALUES
  -- ── Japanese bodies (English labels) ──
  ('ja','bond_overview', '💬 Bond overview',
    E'{first_name}さん、お問い合わせありがとうございます。返金対象保証金についてご案内いたします。\n\n■ 金額：[金額]（ご依頼内容に記載の金額です）\n■ 返金条件：すべてのプランを期限内に提出し、内容確認・承認が完了した時点で、保証金は報酬とともに全額返金されます。\n■ お手続き方法：銀行振込、またはPayPay（QRコード・電話番号・PayPay ID）がご利用いただけます。ご準備が整いましたらお知らせください。ご希望の方法に応じて、振込先・PayPayのQRコード・PayPayの送金先（電話番号/ID）と、照合用の参照コードをお送りします。お手続き後、完了画面のスクリーンショットをこのチャットへお送りいただければ、確認後にロックを解除いたします。\n\nご不明な点がございましたら、お気軽にお知らせください。', 16, true),
  ('ja','bond_ready', '🏦 Send details when ready',
    E'{first_name}さん、返金対象保証金のお手続きのご準備が整いましたら、お知らせください。銀行振込、またはPayPay（QRコード・電話番号・PayPay ID）がご利用いただけます。ご希望の方法に応じて、振込先・PayPayのQRコード・PayPayの送金先（電話番号/ID）と、照合用の参照コードをすぐにお送りいたします。', 17, true),
  ('ja','bond_refund_terms', '↩️ Refund terms',
    E'返金条件についてご案内いたします。すべてのプランを期限内に提出し、内容確認・承認が完了した時点で、返金対象保証金は報酬とともに全額返金されます。なお、期限超過・未対応・未納品などが確認された場合は、返金対象外となる場合があります。', 18, true),
  ('ja','bond_transfer_method', '💳 How to pay (transfer / PayPay)',
    E'保証金のお手続き方法は次の3通りございます。\n\n①銀行振込：お送りする銀行口座へお振込みください。\n②PayPay（QRコード）：お送りするQRコードを読み取ってお手続きください。\n③PayPay（電話番号・ID）：お知らせするPayPay電話番号またはPayPay IDへご送金ください。\n\nいずれの場合も、完了画面のスクリーンショットをこのチャットへお送りください。確認後、プランのロックを解除いたします。', 19, true),
  ('ja','bond_paypay', '📱 PayPay QR',
    E'{first_name}さん、PayPayでのお手続きですね。こちらのQRコードを読み取り、金額[金額]でお手続きください。\n参照コード：BOND-{set_num}-{planner_short}\nお手続き後、完了画面のスクリーンショットをこのチャットへお送りください。確認後、プランのロックを解除いたします。', 20, true),
  ('ja','bond_paypay_phone', '📱 PayPay phone / ID',
    E'{first_name}さん、PayPayでのお手続きですね。以下のPayPay送金先へ、金額[金額]でお手続きください。\nPayPay電話番号：[電話番号]\n（またはPayPay ID：[PayPay ID]）\n参照コード：BOND-{set_num}-{planner_short}\n\n【送金手順】\n1. PayPayアプリを開きます\n2. ホーム画面の「送る」をタップします\n3. 「PayPay ID・電話番号・表示名で検索」を選択します\n4. 上記の電話番号またはIDを入力して検索します\n5. 表示された相手を選択します\n6. 「送る」をタップします\n7. 送金金額を入力します\n8. 内容を確認して「送る」をもう一度タップして完了です\n\n※送金前に相手が正しいか必ずご確認ください。\nお手続き後、完了画面のスクリーンショットをこのチャットへお送りください。確認後、プランのロックを解除いたします。', 21, true),
  -- ── English bodies ──
  ('en','bond_overview', '💬 Bond overview',
    E'Hi {first_name}, thanks for reaching out. Here''s an overview of the refundable bond:\n\n■ Amount: [amount] (as shown in your brief)\n■ Refund terms: submit all plans on time and, once they pass review and approval, the bond is refunded in full together with your reward.\n■ How to complete it: you can use a bank transfer, or PayPay (QR code, phone number, or PayPay ID). Just let us know when you''re ready and we''ll send the bank details, the PayPay QR, or the PayPay phone number / ID, plus a reference code. After that, post a screenshot of the completed payment here and we''ll unlock the plan once it''s confirmed.\n\nHappy to help with anything else!', 16, true),
  ('en','bond_ready', '🏦 Send details when ready',
    E'Hi {first_name}, whenever you''re ready to handle the refundable bond, just let us know. You can use a bank transfer, or PayPay (QR code, phone number, or PayPay ID) — we''ll send the bank details, the PayPay QR, or the PayPay phone number / ID, plus a reference code, right away.', 17, true),
  ('en','bond_refund_terms', '↩️ Refund terms',
    E'Here are the refund terms: submit all plans on time and, once they pass review and approval, the refundable bond is returned in full along with your reward. If deadlines are missed or work is left unhandled or undelivered, the bond may become non-refundable.', 18, true),
  ('en','bond_transfer_method', '💳 How to pay (transfer / PayPay)',
    E'There are three ways to complete the bond:\n\n1) Bank transfer — send it to the bank details we provide.\n2) PayPay (QR code) — scan the QR code we send you.\n3) PayPay (phone number / ID) — send to the PayPay phone number or PayPay ID we give you.\n\nAny of these — post a screenshot of the completed payment here and we''ll unlock the plan once it''s confirmed.', 19, true),
  ('en','bond_paypay', '📱 PayPay QR',
    E'Hi {first_name}, sure — to pay by PayPay, scan the QR code here and complete it for [amount].\nReference: BOND-{set_num}-{planner_short}\nAfter that, post a screenshot of the completed payment here and we''ll unlock the plan once it''s confirmed.', 20, true),
  ('en','bond_paypay_phone', '📱 PayPay phone / ID',
    E'Hi {first_name}, to pay by PayPay, send [amount] to our PayPay account:\nPayPay phone: [phone]\n(or PayPay ID: [PayPay ID])\nReference: BOND-{set_num}-{planner_short}\n\nHow to send:\n1. Open the PayPay app\n2. Tap "Send" on the home screen\n3. Choose "Search by PayPay ID / phone / display name"\n4. Enter the phone number or ID above\n5. Select the correct recipient\n6. Tap "Send"\n7. Enter the amount\n8. Confirm and tap "Send" again\n\nPlease double-check the recipient before sending. After that, post a screenshot of the completed payment here and we''ll unlock the plan once confirmed.', 21, true);

-- 2) Every NON-bond JA chip — copy its English label from the matching EN row,
--    so CS sees English labels everywhere (Japanese bodies stay untouched).
UPDATE public.cs_quick_replies AS j
SET label = e.label
FROM public.cs_quick_replies AS e
WHERE j.lang = 'ja' AND e.lang = 'en'
  AND j.key IS NOT NULL AND j.key = e.key
  AND j.key NOT IN ('bond_overview','bond_ready','bond_refund_terms','bond_transfer_method','bond_paypay','bond_paypay_phone');

-- Verify:
--   SELECT lang, key, label FROM public.cs_quick_replies
--   WHERE is_system = true ORDER BY lang, sort_order;
