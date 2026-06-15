-- ============================================================================
-- Japan travelers — Japanese for the structured brief data (room type, must-haves,
-- languages). Occasion sentences + origin place-names left as-is per request.
-- Keyed by seed_batch='jp-01' + person_id. Run once; pairs with the seed.
-- ============================================================================
UPDATE public.travelers SET meta = jsonb_set(jsonb_set(jsonb_set(meta, '{room_type}', to_jsonb('シングル1室 · 1名'::text)), '{accommodation_musthaves}', '["静かな部屋","中心部の立地","庭園ビュー"]'::jsonb), '{languages}', '["ポルトガル語","英語（流暢）","スペイン語（日常会話）"]'::jsonb)
  WHERE meta->>'seed_batch'='jp-01' AND meta->>'person_id'='0001';
UPDATE public.travelers SET meta = jsonb_set(jsonb_set(jsonb_set(meta, '{room_type}', to_jsonb('シングル1室 · 1名'::text)), '{accommodation_musthaves}', '["温泉","山ビュー","静かな部屋"]'::jsonb), '{languages}', '["ノルウェー語","英語（流暢）","スウェーデン語（日常会話）"]'::jsonb)
  WHERE meta->>'seed_batch'='jp-01' AND meta->>'person_id'='0002';
UPDATE public.travelers SET meta = jsonb_set(jsonb_set(jsonb_set(meta, '{room_type}', to_jsonb('シングル1室 · 1名'::text)), '{accommodation_musthaves}', '["中心部の立地","駅近","朝食"]'::jsonb), '{languages}', '["タミル語","英語（流暢）","ヒンディー語","カンナダ語（日常会話）"]'::jsonb)
  WHERE meta->>'seed_batch'='jp-01' AND meta->>'person_id'='0003';
UPDATE public.travelers SET meta = jsonb_set(jsonb_set(jsonb_set(meta, '{room_type}', to_jsonb('シングル1室 · 1名'::text)), '{accommodation_musthaves}', '["温泉","静かな部屋","中心部の立地"]'::jsonb), '{languages}', '["英語（ネイティブ）","日本語（初級）"]'::jsonb)
  WHERE meta->>'seed_batch'='jp-01' AND meta->>'person_id'='0004';
UPDATE public.travelers SET meta = jsonb_set(jsonb_set(jsonb_set(meta, '{room_type}', to_jsonb('シングル1室 · 1名'::text)), '{accommodation_musthaves}', '["中心部の立地","山ビュー","静かな部屋"]'::jsonb), '{languages}', '["アラビア語","英語（流暢）","フランス語（初級）"]'::jsonb)
  WHERE meta->>'seed_batch'='jp-01' AND meta->>'person_id'='0005';
UPDATE public.travelers SET meta = jsonb_set(jsonb_set(jsonb_set(meta, '{room_type}', to_jsonb('ダブル1室 · 2名'::text)), '{accommodation_musthaves}', '["温泉","静かな部屋","中心部の立地"]'::jsonb), '{languages}', '["韓国語","英語（中級）"]'::jsonb)
  WHERE meta->>'seed_batch'='jp-01' AND meta->>'person_id'='0006';
UPDATE public.travelers SET meta = jsonb_set(jsonb_set(jsonb_set(meta, '{room_type}', to_jsonb('ダブル1室 · 2名'::text)), '{accommodation_musthaves}', '["中心部の立地","駅近","朝食"]'::jsonb), '{languages}', '["英語（ネイティブ）","フランス語（日常会話）"]'::jsonb)
  WHERE meta->>'seed_batch'='jp-01' AND meta->>'person_id'='0007';
UPDATE public.travelers SET meta = jsonb_set(jsonb_set(jsonb_set(meta, '{room_type}', to_jsonb('ダブル1室 · 2名'::text)), '{accommodation_musthaves}', '["温泉","山ビュー","静かな部屋"]'::jsonb), '{languages}', '["ドイツ語","英語（流暢）"]'::jsonb)
  WHERE meta->>'seed_batch'='jp-01' AND meta->>'person_id'='0008';
UPDATE public.travelers SET meta = jsonb_set(jsonb_set(jsonb_set(meta, '{room_type}', to_jsonb('ダブル1室 · 2名'::text)), '{accommodation_musthaves}', '["静かな部屋","キングベッド","中心部の立地"]'::jsonb), '{languages}', '["英語（ネイティブ）","スペイン語（日常会話）"]'::jsonb)
  WHERE meta->>'seed_batch'='jp-01' AND meta->>'person_id'='0009';
UPDATE public.travelers SET meta = jsonb_set(jsonb_set(jsonb_set(meta, '{room_type}', to_jsonb('ダブル1室 · 2名'::text)), '{accommodation_musthaves}', '["温泉","キングベッド","静かな部屋"]'::jsonb), '{languages}', '["フランス語（ネイティブ）","英語（流暢）"]'::jsonb)
  WHERE meta->>'seed_batch'='jp-01' AND meta->>'person_id'='0010';
UPDATE public.travelers SET meta = jsonb_set(jsonb_set(jsonb_set(meta, '{room_type}', to_jsonb('ジュニアスイート1室 · 2名'::text)), '{accommodation_musthaves}', '["温泉","中心部の立地","キングベッド"]'::jsonb), '{languages}', '["イタリア語","英語（流暢）","スペイン語（日常会話）"]'::jsonb)
  WHERE meta->>'seed_batch'='jp-01' AND meta->>'person_id'='0011';
UPDATE public.travelers SET meta = jsonb_set(jsonb_set(jsonb_set(meta, '{room_type}', to_jsonb('ジュニアスイート1室 · 2名'::text)), '{accommodation_musthaves}', '["温泉","山ビュー","朝食"]'::jsonb), '{languages}', '["英語（ネイティブ）","中国語","マレー語（初級）"]'::jsonb)
  WHERE meta->>'seed_batch'='jp-01' AND meta->>'person_id'='0012';
UPDATE public.travelers SET meta = jsonb_set(jsonb_set(jsonb_set(meta, '{room_type}', to_jsonb('ジュニアスイート1室 · 2名'::text)), '{accommodation_musthaves}', '["中心部の立地","キングベッド","静かな部屋"]'::jsonb), '{languages}', '["スペイン語","カタルーニャ語","英語（流暢）"]'::jsonb)
  WHERE meta->>'seed_batch'='jp-01' AND meta->>'person_id'='0013';
UPDATE public.travelers SET meta = jsonb_set(jsonb_set(jsonb_set(meta, '{room_type}', to_jsonb('コネクティング2室 · 4名（大人2・子供2）'::text)), '{accommodation_musthaves}', '["ファミリールーム","温泉","駅近"]'::jsonb), '{languages}', '["スペイン語","英語（中級）"]'::jsonb)
  WHERE meta->>'seed_batch'='jp-01' AND meta->>'person_id'='0014';
UPDATE public.travelers SET meta = jsonb_set(jsonb_set(jsonb_set(meta, '{room_type}', to_jsonb('コネクティング3室 · 5名（1室2名＋1名）'::text)), '{accommodation_musthaves}', '["ファミリールーム","温泉","山ビュー"]'::jsonb), '{languages}', '["オランダ語","英語（流暢）","ドイツ語（初級）"]'::jsonb)
  WHERE meta->>'seed_batch'='jp-01' AND meta->>'person_id'='0015';
UPDATE public.travelers SET meta = jsonb_set(jsonb_set(jsonb_set(meta, '{room_type}', to_jsonb('コネクティング2室 · 4名（大人2・子供2）'::text)), '{accommodation_musthaves}', '["温泉","ファミリールーム","駅近"]'::jsonb), '{languages}', '["タイ語","英語（中級）"]'::jsonb)
  WHERE meta->>'seed_batch'='jp-01' AND meta->>'person_id'='0016';
UPDATE public.travelers SET meta = jsonb_set(jsonb_set(jsonb_set(meta, '{room_type}', to_jsonb('2室 · 3名（ダブル1・ツイン1〈ティーン用〉）'::text)), '{accommodation_musthaves}', '["中心部の立地","山ビュー","朝食"]'::jsonb), '{languages}', '["英語（ネイティブ）","マオリ語（初級）"]'::jsonb)
  WHERE meta->>'seed_batch'='jp-01' AND meta->>'person_id'='0017';
UPDATE public.travelers SET meta = jsonb_set(jsonb_set(jsonb_set(meta, '{room_type}', to_jsonb('ツイン2室 · 4名（1室2名）'::text)), '{accommodation_musthaves}', '["中心部の立地","駅近","静かな部屋"]'::jsonb), '{languages}', '["フィリピン語","英語（流暢）"]'::jsonb)
  WHERE meta->>'seed_batch'='jp-01' AND meta->>'person_id'='0018';
UPDATE public.travelers SET meta = jsonb_set(jsonb_set(jsonb_set(meta, '{room_type}', to_jsonb('2室 · 4名（1室2名）'::text)), '{accommodation_musthaves}', '["温泉","山ビュー","静かな部屋"]'::jsonb), '{languages}', '["スウェーデン語","英語（流暢）","ドイツ語（初級）"]'::jsonb)
  WHERE meta->>'seed_batch'='jp-01' AND meta->>'person_id'='0019';
UPDATE public.travelers SET meta = jsonb_set(jsonb_set(jsonb_set(meta, '{room_type}', to_jsonb('2室 · 3名（ダブル1・シングル1）'::text)), '{accommodation_musthaves}', '["中心部の立地","駅近","朝食"]'::jsonb), '{languages}', '["英語（ネイティブ）","ズールー語","アフリカーンス語（日常会話）"]'::jsonb)
  WHERE meta->>'seed_batch'='jp-01' AND meta->>'person_id'='0020';
