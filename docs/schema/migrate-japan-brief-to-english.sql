-- ============================================================================
-- Migrate Japan traveler briefs to canonical ENGLISH (in place).
--
-- Converts room_type / accommodation_musthaves / languages from Japanese to
-- English for the existing jp-01 batch AND the luxury lux-jp-bond-01 batch,
-- so the admin backend (which shows the raw stored value) reads English.
-- The planner dashboard re-localizes to Japanese via its bilingual dictionary
-- when toggled to JA.
--
-- In-place UPDATE (no delete) — preserves assignments / plans. Exact whole-
-- value matching (no substring collisions). Idempotent: re-running is a no-op
-- (English values no longer match the Japanese CASE arms).
-- ============================================================================

-- room_type (scalar)
UPDATE public.travelers SET meta = jsonb_set(meta, '{room_type}', to_jsonb((CASE meta->>'room_type'
    WHEN 'シングル1室 · 1名' THEN '1 single room · 1 guest'
    WHEN 'ダブル1室 · 2名' THEN '1 double room · 2 guests'
    WHEN 'ジュニアスイート1室 · 2名' THEN '1 junior suite · 2 guests'
    WHEN 'デラックス1室 · 1名' THEN '1 deluxe room · 1 guest'
    WHEN 'スイート1室 · 2名' THEN '1 suite · 2 guests'
    WHEN 'ファミリースイート1室 · 4名' THEN '1 family suite · 4 guests'
    WHEN '2ベッドルームスイート1室 · 4名' THEN '1 two-bedroom suite · 4 guests'
    WHEN '露天風呂付き客室1室 · 1名' THEN '1 room with private open-air bath · 1 guest'
    WHEN '露天風呂付き客室1室 · 2名' THEN '1 room with private open-air bath · 2 guests'
    WHEN '露天風呂付きスイート1室 · 2名' THEN '1 suite with private open-air bath · 2 guests'
    WHEN 'コネクティングスイート3室 · 5名' THEN '3 connecting suites · 5 guests'
    WHEN 'コネクティングスイート3室 · 5名（バリアフリー）' THEN '3 connecting suites · 5 guests (barrier-free)'
    WHEN 'コネクティング2室 · 4名（大人2・子供2）' THEN '2 connecting rooms · 4 guests (2 adults + 2 children)'
    WHEN 'コネクティング3室 · 5名（1室2名＋1名）' THEN '3 connecting rooms · 5 guests (2 per room + 1)'
    WHEN 'ツイン2室 · 4名（1室2名）' THEN '2 twin rooms · 4 guests (2 per room)'
    WHEN '2室 · 4名（1室2名）' THEN '2 rooms · 4 guests (2 per room)'
    WHEN '2室 · 3名（ダブル1・ツイン1〈ティーン用〉）' THEN '2 rooms · 3 guests (1 double + 1 twin for the teens)'
    WHEN '2室 · 3名（ダブル1・シングル1）' THEN '2 rooms · 3 guests (1 double + 1 single)'
    ELSE meta->>'room_type' END)))
WHERE meta->>'seed_batch' IN ('jp-01','lux-jp-bond-01') AND meta ? 'room_type';

-- accommodation_musthaves (array, order preserved)
UPDATE public.travelers SET meta = jsonb_set(meta, '{accommodation_musthaves}', COALESCE((
  SELECT jsonb_agg(CASE el
    WHEN '温泉' THEN 'Onsen'
    WHEN 'ファミリールーム' THEN 'Family room'
    WHEN '駅近' THEN 'Near station'
    WHEN '中心部の立地' THEN 'Central location'
    WHEN '静かな部屋' THEN 'Quiet room'
    WHEN '山ビュー' THEN 'Mountain view'
    WHEN '庭園ビュー' THEN 'Garden view'
    WHEN 'キングベッド' THEN 'King bed'
    WHEN '朝食' THEN 'Breakfast'
    WHEN '高層階' THEN 'High floor'
    WHEN 'シティビュー' THEN 'City view'
    WHEN 'クラブラウンジ利用' THEN 'Club lounge access'
    WHEN '露天風呂付き客室' THEN 'Private open-air bath'
    WHEN '夕朝食付き' THEN 'Half-board (dinner & breakfast)'
    WHEN '渓谷ビュー' THEN 'Valley view'
    WHEN 'スイート' THEN 'Suite'
    WHEN '川沿い' THEN 'Riverside'
    WHEN 'ビーチフロント' THEN 'Beachfront'
    WHEN 'ファミリースイート' THEN 'Family suite'
    WHEN 'ハラル対応' THEN 'Halal-friendly'
    WHEN '2ベッドルーム' THEN 'Two bedrooms'
    WHEN '富士山ビュー' THEN 'Mt. Fuji view'
    WHEN '専用庭' THEN 'Private garden'
    WHEN 'コネクティングルーム' THEN 'Connecting rooms'
    WHEN 'バリアフリー' THEN 'Barrier-free'
    ELSE el END ORDER BY ord)
  FROM jsonb_array_elements_text(meta->'accommodation_musthaves') WITH ORDINALITY AS t(el, ord)
), '[]'::jsonb))
WHERE meta->>'seed_batch' IN ('jp-01','lux-jp-bond-01') AND meta ? 'accommodation_musthaves';

-- languages (array, order preserved)
UPDATE public.travelers SET meta = jsonb_set(meta, '{languages}', COALESCE((
  SELECT jsonb_agg(CASE el
    WHEN '英語（ネイティブ）' THEN 'English (native)'
    WHEN '英語（中級）' THEN 'English (intermediate)'
    WHEN '英語（流暢）' THEN 'English (fluent)'
    WHEN '韓国語' THEN 'Korean'
    WHEN '韓国語（日常会話）' THEN 'Korean (conversational)'
    WHEN 'ヒンディー語' THEN 'Hindi'
    WHEN '中国語' THEN 'Mandarin'
    WHEN '中国語（北京語）' THEN 'Mandarin'
    WHEN '広東語' THEN 'Cantonese'
    WHEN 'アラビア語' THEN 'Arabic'
    WHEN 'ドイツ語' THEN 'German'
    WHEN 'ドイツ語（初級）' THEN 'German (basic)'
    WHEN 'イタリア語' THEN 'Italian'
    WHEN 'ポルトガル語' THEN 'Portuguese'
    WHEN 'スペイン語' THEN 'Spanish'
    WHEN 'スペイン語（日常会話）' THEN 'Spanish (conversational)'
    WHEN 'フランス語（ネイティブ）' THEN 'French (native)'
    WHEN 'フランス語（初級）' THEN 'French (basic)'
    WHEN 'フランス語（日常会話）' THEN 'French (conversational)'
    WHEN 'タミル語' THEN 'Tamil'
    WHEN 'カンナダ語（日常会話）' THEN 'Kannada (conversational)'
    WHEN 'ノルウェー語' THEN 'Norwegian'
    WHEN 'スウェーデン語' THEN 'Swedish'
    WHEN 'スウェーデン語（日常会話）' THEN 'Swedish (conversational)'
    WHEN 'オランダ語' THEN 'Dutch'
    WHEN 'タイ語' THEN 'Thai'
    WHEN 'マレー語（初級）' THEN 'Malay (basic)'
    WHEN 'フィリピン語' THEN 'Filipino'
    WHEN 'アフリカーンス語（日常会話）' THEN 'Afrikaans (conversational)'
    WHEN 'カタルーニャ語' THEN 'Catalan'
    WHEN 'ズールー語' THEN 'Zulu'
    WHEN 'マオリ語（初級）' THEN 'Maori (basic)'
    WHEN '日本語（初級）' THEN 'Japanese (basic)'
    ELSE el END ORDER BY ord)
  FROM jsonb_array_elements_text(meta->'languages') WITH ORDINALITY AS t(el, ord)
), '[]'::jsonb))
WHERE meta->>'seed_batch' IN ('jp-01','lux-jp-bond-01') AND meta ? 'languages';

-- Verify:
--   SELECT meta->>'room_type', meta->'accommodation_musthaves', meta->'languages'
--     FROM public.travelers WHERE meta->>'seed_batch' IN ('jp-01','lux-jp-bond-01');
