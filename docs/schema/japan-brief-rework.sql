-- ============================================================================
-- Japan jp-01 brief rework — supersedes japan-brief-data-ja.sql (do NOT run that
-- one anymore; this file covers room_type + languages + everything else).
--   • room_type + languages → Japanese
--   • budget_tier + daily_timing realigned
--   • accommodation_musthaves → location-appropriate, PER UNIT (no onsen in a
--     city core, no onsen+king-bed clashes, mountain-view only where there are
--     mountains, family-room on every family unit)
--   • two families get a hotel-budget bump for onsen-ryokan family rooms
-- Keyed by seed_batch='jp-01'. Idempotent — safe to re-run.
-- ============================================================================

-- #0001 (1=中心部の立地/静かな部屋/朝食  2=静かな部屋/庭園ビュー  3=静かな部屋/庭園ビュー  4=中心部の立地/庭園ビュー/静かな部屋)
UPDATE public.travelers SET meta =
  jsonb_set(jsonb_set(jsonb_set(jsonb_set(jsonb_set(meta,
    '{room_type}',          to_jsonb('シングル1室 · 1名'::text)),
    '{languages}',          '["ポルトガル語","英語（流暢）","スペイン語（日常会話）"]'::jsonb),
    '{budget_tier}',        to_jsonb('mid_range'::text)),
    '{daily_timing}',       to_jsonb('early'::text)),
    '{accommodation_musthaves}', CASE (meta->>'unit_order')::int
      WHEN 1 THEN '["中心部の立地","静かな部屋","朝食"]'::jsonb
      WHEN 2 THEN '["静かな部屋","庭園ビュー"]'::jsonb
      WHEN 3 THEN '["静かな部屋","庭園ビュー"]'::jsonb
      WHEN 4 THEN '["中心部の立地","庭園ビュー","静かな部屋"]'::jsonb
      ELSE meta->'accommodation_musthaves'
    END)
  WHERE meta->>'seed_batch'='jp-01' AND meta->>'person_id'='0001';

-- #0002 (1=中心部の立地/静かな部屋  2=温泉/山ビュー/静かな部屋  3=温泉/静かな部屋)
UPDATE public.travelers SET meta =
  jsonb_set(jsonb_set(jsonb_set(jsonb_set(jsonb_set(meta,
    '{room_type}',          to_jsonb('シングル1室 · 1名'::text)),
    '{languages}',          '["ノルウェー語","英語（流暢）","スウェーデン語（日常会話）"]'::jsonb),
    '{budget_tier}',        to_jsonb('mid_range'::text)),
    '{daily_timing}',       to_jsonb('early'::text)),
    '{accommodation_musthaves}', CASE (meta->>'unit_order')::int
      WHEN 1 THEN '["中心部の立地","静かな部屋"]'::jsonb
      WHEN 2 THEN '["温泉","山ビュー","静かな部屋"]'::jsonb
      WHEN 3 THEN '["温泉","静かな部屋"]'::jsonb
      ELSE meta->'accommodation_musthaves'
    END)
  WHERE meta->>'seed_batch'='jp-01' AND meta->>'person_id'='0002';

-- #0003 (1=中心部の立地/駅近/朝食  2=駅近/朝食  3=中心部の立地/駅近/朝食  4=静かな部屋/朝食)
UPDATE public.travelers SET meta =
  jsonb_set(jsonb_set(jsonb_set(jsonb_set(jsonb_set(meta,
    '{room_type}',          to_jsonb('シングル1室 · 1名'::text)),
    '{languages}',          '["タミル語","英語（流暢）","ヒンディー語","カンナダ語（日常会話）"]'::jsonb),
    '{budget_tier}',        to_jsonb('mid_range'::text)),
    '{daily_timing}',       to_jsonb('standard'::text)),
    '{accommodation_musthaves}', CASE (meta->>'unit_order')::int
      WHEN 1 THEN '["中心部の立地","駅近","朝食"]'::jsonb
      WHEN 2 THEN '["駅近","朝食"]'::jsonb
      WHEN 3 THEN '["中心部の立地","駅近","朝食"]'::jsonb
      WHEN 4 THEN '["静かな部屋","朝食"]'::jsonb
      ELSE meta->'accommodation_musthaves'
    END)
  WHERE meta->>'seed_batch'='jp-01' AND meta->>'person_id'='0003';

-- #0004 (1=中心部の立地/静かな部屋  2=温泉/静かな部屋  3=温泉/山ビュー/静かな部屋  4=中心部の立地/静かな部屋)
UPDATE public.travelers SET meta =
  jsonb_set(jsonb_set(jsonb_set(jsonb_set(jsonb_set(meta,
    '{room_type}',          to_jsonb('シングル1室 · 1名'::text)),
    '{languages}',          '["英語（ネイティブ）","日本語（初級）"]'::jsonb),
    '{budget_tier}',        to_jsonb('mid_range'::text)),
    '{daily_timing}',       to_jsonb('standard'::text)),
    '{accommodation_musthaves}', CASE (meta->>'unit_order')::int
      WHEN 1 THEN '["中心部の立地","静かな部屋"]'::jsonb
      WHEN 2 THEN '["温泉","静かな部屋"]'::jsonb
      WHEN 3 THEN '["温泉","山ビュー","静かな部屋"]'::jsonb
      WHEN 4 THEN '["中心部の立地","静かな部屋"]'::jsonb
      ELSE meta->'accommodation_musthaves'
    END)
  WHERE meta->>'seed_batch'='jp-01' AND meta->>'person_id'='0004';

-- #0005 (1=中心部の立地/静かな部屋/朝食  2=山ビュー/温泉/静かな部屋  3=中心部の立地/庭園ビュー/静かな部屋)
UPDATE public.travelers SET meta =
  jsonb_set(jsonb_set(jsonb_set(jsonb_set(jsonb_set(meta,
    '{room_type}',          to_jsonb('シングル1室 · 1名'::text)),
    '{languages}',          '["アラビア語","英語（流暢）","フランス語（初級）"]'::jsonb),
    '{budget_tier}',        to_jsonb('luxury'::text)),
    '{daily_timing}',       to_jsonb('standard'::text)),
    '{accommodation_musthaves}', CASE (meta->>'unit_order')::int
      WHEN 1 THEN '["中心部の立地","静かな部屋","朝食"]'::jsonb
      WHEN 2 THEN '["山ビュー","温泉","静かな部屋"]'::jsonb
      WHEN 3 THEN '["中心部の立地","庭園ビュー","静かな部屋"]'::jsonb
      ELSE meta->'accommodation_musthaves'
    END)
  WHERE meta->>'seed_batch'='jp-01' AND meta->>'person_id'='0005';

-- #0006 (1=中心部の立地/静かな部屋  2=温泉/静かな部屋  3=温泉/庭園ビュー/静かな部屋  4=中心部の立地/庭園ビュー/静かな部屋)
UPDATE public.travelers SET meta =
  jsonb_set(jsonb_set(jsonb_set(jsonb_set(jsonb_set(meta,
    '{room_type}',          to_jsonb('ダブル1室 · 2名'::text)),
    '{languages}',          '["韓国語","英語（中級）"]'::jsonb),
    '{budget_tier}',        to_jsonb('mid_range'::text)),
    '{daily_timing}',       to_jsonb('standard'::text)),
    '{accommodation_musthaves}', CASE (meta->>'unit_order')::int
      WHEN 1 THEN '["中心部の立地","静かな部屋"]'::jsonb
      WHEN 2 THEN '["温泉","静かな部屋"]'::jsonb
      WHEN 3 THEN '["温泉","庭園ビュー","静かな部屋"]'::jsonb
      WHEN 4 THEN '["中心部の立地","庭園ビュー","静かな部屋"]'::jsonb
      ELSE meta->'accommodation_musthaves'
    END)
  WHERE meta->>'seed_batch'='jp-01' AND meta->>'person_id'='0006';

-- #0007 (1=中心部の立地/駅近/朝食  2=駅近/朝食  3=中心部の立地/駅近/朝食  4=静かな部屋/朝食)
UPDATE public.travelers SET meta =
  jsonb_set(jsonb_set(jsonb_set(jsonb_set(jsonb_set(meta,
    '{room_type}',          to_jsonb('ダブル1室 · 2名'::text)),
    '{languages}',          '["英語（ネイティブ）","フランス語（日常会話）"]'::jsonb),
    '{budget_tier}',        to_jsonb('luxury'::text)),
    '{daily_timing}',       to_jsonb('standard'::text)),
    '{accommodation_musthaves}', CASE (meta->>'unit_order')::int
      WHEN 1 THEN '["中心部の立地","駅近","朝食"]'::jsonb
      WHEN 2 THEN '["駅近","朝食"]'::jsonb
      WHEN 3 THEN '["中心部の立地","駅近","朝食"]'::jsonb
      WHEN 4 THEN '["静かな部屋","朝食"]'::jsonb
      ELSE meta->'accommodation_musthaves'
    END)
  WHERE meta->>'seed_batch'='jp-01' AND meta->>'person_id'='0007';

-- #0008 (1=中心部の立地/静かな部屋  2=温泉/静かな部屋  3=温泉/山ビュー/静かな部屋)
UPDATE public.travelers SET meta =
  jsonb_set(jsonb_set(jsonb_set(jsonb_set(jsonb_set(meta,
    '{room_type}',          to_jsonb('ダブル1室 · 2名'::text)),
    '{languages}',          '["ドイツ語","英語（流暢）"]'::jsonb),
    '{budget_tier}',        to_jsonb('mid_range'::text)),
    '{daily_timing}',       to_jsonb('standard'::text)),
    '{accommodation_musthaves}', CASE (meta->>'unit_order')::int
      WHEN 1 THEN '["中心部の立地","静かな部屋"]'::jsonb
      WHEN 2 THEN '["温泉","静かな部屋"]'::jsonb
      WHEN 3 THEN '["温泉","山ビュー","静かな部屋"]'::jsonb
      ELSE meta->'accommodation_musthaves'
    END)
  WHERE meta->>'seed_batch'='jp-01' AND meta->>'person_id'='0008';

-- #0009 (1=中心部の立地/キングベッド/静かな部屋  2=静かな部屋/朝食  3=静かな部屋  4=中心部の立地/キングベッド/庭園ビュー)
UPDATE public.travelers SET meta =
  jsonb_set(jsonb_set(jsonb_set(jsonb_set(jsonb_set(meta,
    '{room_type}',          to_jsonb('ダブル1室 · 2名'::text)),
    '{languages}',          '["英語（ネイティブ）","スペイン語（日常会話）"]'::jsonb),
    '{budget_tier}',        to_jsonb('luxury'::text)),
    '{daily_timing}',       to_jsonb('standard'::text)),
    '{accommodation_musthaves}', CASE (meta->>'unit_order')::int
      WHEN 1 THEN '["中心部の立地","キングベッド","静かな部屋"]'::jsonb
      WHEN 2 THEN '["静かな部屋","朝食"]'::jsonb
      WHEN 3 THEN '["静かな部屋"]'::jsonb
      WHEN 4 THEN '["中心部の立地","キングベッド","庭園ビュー"]'::jsonb
      ELSE meta->'accommodation_musthaves'
    END)
  WHERE meta->>'seed_batch'='jp-01' AND meta->>'person_id'='0009';

-- #0010 (1=中心部の立地/キングベッド/静かな部屋  2=温泉/静かな部屋  3=温泉/山ビュー/静かな部屋  4=中心部の立地/キングベッド/静かな部屋)
UPDATE public.travelers SET meta =
  jsonb_set(jsonb_set(jsonb_set(jsonb_set(jsonb_set(meta,
    '{room_type}',          to_jsonb('ダブル1室 · 2名'::text)),
    '{languages}',          '["フランス語（ネイティブ）","英語（流暢）"]'::jsonb),
    '{budget_tier}',        to_jsonb('mid_range'::text)),
    '{daily_timing}',       to_jsonb('standard'::text)),
    '{accommodation_musthaves}', CASE (meta->>'unit_order')::int
      WHEN 1 THEN '["中心部の立地","キングベッド","静かな部屋"]'::jsonb
      WHEN 2 THEN '["温泉","静かな部屋"]'::jsonb
      WHEN 3 THEN '["温泉","山ビュー","静かな部屋"]'::jsonb
      WHEN 4 THEN '["中心部の立地","キングベッド","静かな部屋"]'::jsonb
      ELSE meta->'accommodation_musthaves'
    END)
  WHERE meta->>'seed_batch'='jp-01' AND meta->>'person_id'='0010';

-- #0011 (1=中心部の立地/キングベッド/静かな部屋  2=温泉/山ビュー/静かな部屋  3=中心部の立地/庭園ビュー/キングベッド  4=中心部の立地/キングベッド)
UPDATE public.travelers SET meta =
  jsonb_set(jsonb_set(jsonb_set(jsonb_set(jsonb_set(meta,
    '{room_type}',          to_jsonb('ジュニアスイート1室 · 2名'::text)),
    '{languages}',          '["イタリア語","英語（流暢）","スペイン語（日常会話）"]'::jsonb),
    '{budget_tier}',        to_jsonb('luxury'::text)),
    '{daily_timing}',       to_jsonb('late'::text)),
    '{accommodation_musthaves}', CASE (meta->>'unit_order')::int
      WHEN 1 THEN '["中心部の立地","キングベッド","静かな部屋"]'::jsonb
      WHEN 2 THEN '["温泉","山ビュー","静かな部屋"]'::jsonb
      WHEN 3 THEN '["中心部の立地","庭園ビュー","キングベッド"]'::jsonb
      WHEN 4 THEN '["中心部の立地","キングベッド"]'::jsonb
      ELSE meta->'accommodation_musthaves'
    END)
  WHERE meta->>'seed_batch'='jp-01' AND meta->>'person_id'='0011';

-- #0012 (1=中心部の立地/朝食  2=温泉/静かな部屋/朝食  3=温泉/山ビュー/朝食)
UPDATE public.travelers SET meta =
  jsonb_set(jsonb_set(jsonb_set(jsonb_set(jsonb_set(meta,
    '{room_type}',          to_jsonb('ジュニアスイート1室 · 2名'::text)),
    '{languages}',          '["英語（ネイティブ）","中国語","マレー語（初級）"]'::jsonb),
    '{budget_tier}',        to_jsonb('luxury'::text)),
    '{daily_timing}',       to_jsonb('late'::text)),
    '{accommodation_musthaves}', CASE (meta->>'unit_order')::int
      WHEN 1 THEN '["中心部の立地","朝食"]'::jsonb
      WHEN 2 THEN '["温泉","静かな部屋","朝食"]'::jsonb
      WHEN 3 THEN '["温泉","山ビュー","朝食"]'::jsonb
      ELSE meta->'accommodation_musthaves'
    END)
  WHERE meta->>'seed_batch'='jp-01' AND meta->>'person_id'='0012';

-- #0013 (1=中心部の立地/キングベッド/静かな部屋  2=駅近/キングベッド  3=中心部の立地/キングベッド/静かな部屋  4=温泉/静かな部屋)
UPDATE public.travelers SET meta =
  jsonb_set(jsonb_set(jsonb_set(jsonb_set(jsonb_set(meta,
    '{room_type}',          to_jsonb('ジュニアスイート1室 · 2名'::text)),
    '{languages}',          '["スペイン語","カタルーニャ語","英語（流暢）"]'::jsonb),
    '{budget_tier}',        to_jsonb('luxury'::text)),
    '{daily_timing}',       to_jsonb('late'::text)),
    '{accommodation_musthaves}', CASE (meta->>'unit_order')::int
      WHEN 1 THEN '["中心部の立地","キングベッド","静かな部屋"]'::jsonb
      WHEN 2 THEN '["駅近","キングベッド"]'::jsonb
      WHEN 3 THEN '["中心部の立地","キングベッド","静かな部屋"]'::jsonb
      WHEN 4 THEN '["温泉","静かな部屋"]'::jsonb
      ELSE meta->'accommodation_musthaves'
    END)
  WHERE meta->>'seed_batch'='jp-01' AND meta->>'person_id'='0013';

-- #0014 (1=ファミリールーム/駅近/朝食  2=ファミリールーム/温泉  3=ファミリールーム/駅近/朝食  4=ファミリールーム/駅近/朝食)
UPDATE public.travelers SET meta =
  jsonb_set(jsonb_set(jsonb_set(jsonb_set(jsonb_set(meta,
    '{room_type}',          to_jsonb('コネクティング2室 · 4名（大人2・子供2）'::text)),
    '{languages}',          '["スペイン語","英語（中級）"]'::jsonb),
    '{budget_tier}',        to_jsonb('mid_range'::text)),
    '{daily_timing}',       to_jsonb('standard'::text)),
    '{accommodation_musthaves}', CASE (meta->>'unit_order')::int
      WHEN 1 THEN '["ファミリールーム","駅近","朝食"]'::jsonb
      WHEN 2 THEN '["ファミリールーム","温泉"]'::jsonb
      WHEN 3 THEN '["ファミリールーム","駅近","朝食"]'::jsonb
      WHEN 4 THEN '["ファミリールーム","駅近","朝食"]'::jsonb
      ELSE meta->'accommodation_musthaves'
    END)
  WHERE meta->>'seed_batch'='jp-01' AND meta->>'person_id'='0014';

-- #0015 (1=ファミリールーム/駅近/朝食  2=ファミリールーム/温泉/朝食  3=ファミリールーム/温泉/山ビュー)
UPDATE public.travelers SET meta =
  jsonb_set(jsonb_set(jsonb_set(jsonb_set(jsonb_set(meta,
    '{room_type}',          to_jsonb('コネクティング3室 · 5名（1室2名＋1名）'::text)),
    '{languages}',          '["オランダ語","英語（流暢）","ドイツ語（初級）"]'::jsonb),
    '{budget_tier}',        to_jsonb('mid_range'::text)),
    '{daily_timing}',       to_jsonb('standard'::text)),
    '{accommodation_musthaves}', CASE (meta->>'unit_order')::int
      WHEN 1 THEN '["ファミリールーム","駅近","朝食"]'::jsonb
      WHEN 2 THEN '["ファミリールーム","温泉","朝食"]'::jsonb
      WHEN 3 THEN '["ファミリールーム","温泉","山ビュー"]'::jsonb
      ELSE meta->'accommodation_musthaves'
    END)
  WHERE meta->>'seed_batch'='jp-01' AND meta->>'person_id'='0015';

-- #0016 (1=ファミリールーム/駅近/朝食  2=ファミリールーム/温泉  3=ファミリールーム/温泉/山ビュー  4=ファミリールーム/駅近/朝食)
UPDATE public.travelers SET meta =
  jsonb_set(jsonb_set(jsonb_set(jsonb_set(jsonb_set(meta,
    '{room_type}',          to_jsonb('コネクティング2室 · 4名（大人2・子供2）'::text)),
    '{languages}',          '["タイ語","英語（中級）"]'::jsonb),
    '{budget_tier}',        to_jsonb('mid_range'::text)),
    '{daily_timing}',       to_jsonb('standard'::text)),
    '{accommodation_musthaves}', CASE (meta->>'unit_order')::int
      WHEN 1 THEN '["ファミリールーム","駅近","朝食"]'::jsonb
      WHEN 2 THEN '["ファミリールーム","温泉"]'::jsonb
      WHEN 3 THEN '["ファミリールーム","温泉","山ビュー"]'::jsonb
      WHEN 4 THEN '["ファミリールーム","駅近","朝食"]'::jsonb
      ELSE meta->'accommodation_musthaves'
    END)
  WHERE meta->>'seed_batch'='jp-01' AND meta->>'person_id'='0016';

-- #0017 (1=中心部の立地/朝食  2=山ビュー/温泉/朝食  3=中心部の立地/庭園ビュー/朝食)
UPDATE public.travelers SET meta =
  jsonb_set(jsonb_set(jsonb_set(jsonb_set(jsonb_set(meta,
    '{room_type}',          to_jsonb('2室 · 3名（ダブル1・ツイン1〈ティーン用〉）'::text)),
    '{languages}',          '["英語（ネイティブ）","マオリ語（初級）"]'::jsonb),
    '{budget_tier}',        to_jsonb('mid_range'::text)),
    '{daily_timing}',       to_jsonb('standard'::text)),
    '{accommodation_musthaves}', CASE (meta->>'unit_order')::int
      WHEN 1 THEN '["中心部の立地","朝食"]'::jsonb
      WHEN 2 THEN '["山ビュー","温泉","朝食"]'::jsonb
      WHEN 3 THEN '["中心部の立地","庭園ビュー","朝食"]'::jsonb
      ELSE meta->'accommodation_musthaves'
    END)
  WHERE meta->>'seed_batch'='jp-01' AND meta->>'person_id'='0017';

-- #0018 (1=中心部の立地/駅近/静かな部屋  2=駅近/静かな部屋  3=温泉/静かな部屋  4=中心部の立地/駅近/静かな部屋)
UPDATE public.travelers SET meta =
  jsonb_set(jsonb_set(jsonb_set(jsonb_set(jsonb_set(meta,
    '{room_type}',          to_jsonb('ツイン2室 · 4名（1室2名）'::text)),
    '{languages}',          '["フィリピン語","英語（流暢）"]'::jsonb),
    '{budget_tier}',        to_jsonb('mid_range'::text)),
    '{daily_timing}',       to_jsonb('standard'::text)),
    '{accommodation_musthaves}', CASE (meta->>'unit_order')::int
      WHEN 1 THEN '["中心部の立地","駅近","静かな部屋"]'::jsonb
      WHEN 2 THEN '["駅近","静かな部屋"]'::jsonb
      WHEN 3 THEN '["温泉","静かな部屋"]'::jsonb
      WHEN 4 THEN '["中心部の立地","駅近","静かな部屋"]'::jsonb
      ELSE meta->'accommodation_musthaves'
    END)
  WHERE meta->>'seed_batch'='jp-01' AND meta->>'person_id'='0018';

-- #0019 (1=中心部の立地/静かな部屋  2=温泉/静かな部屋  3=温泉/山ビュー/静かな部屋)
UPDATE public.travelers SET meta =
  jsonb_set(jsonb_set(jsonb_set(jsonb_set(jsonb_set(meta,
    '{room_type}',          to_jsonb('2室 · 4名（1室2名）'::text)),
    '{languages}',          '["スウェーデン語","英語（流暢）","ドイツ語（初級）"]'::jsonb),
    '{budget_tier}',        to_jsonb('mid_range'::text)),
    '{daily_timing}',       to_jsonb('standard'::text)),
    '{accommodation_musthaves}', CASE (meta->>'unit_order')::int
      WHEN 1 THEN '["中心部の立地","静かな部屋"]'::jsonb
      WHEN 2 THEN '["温泉","静かな部屋"]'::jsonb
      WHEN 3 THEN '["温泉","山ビュー","静かな部屋"]'::jsonb
      ELSE meta->'accommodation_musthaves'
    END)
  WHERE meta->>'seed_batch'='jp-01' AND meta->>'person_id'='0019';

-- #0020 (1=中心部の立地/駅近/朝食  2=駅近/朝食  3=中心部の立地/駅近/朝食  4=静かな部屋/朝食)
UPDATE public.travelers SET meta =
  jsonb_set(jsonb_set(jsonb_set(jsonb_set(jsonb_set(meta,
    '{room_type}',          to_jsonb('2室 · 3名（ダブル1・シングル1）'::text)),
    '{languages}',          '["英語（ネイティブ）","ズールー語","アフリカーンス語（日常会話）"]'::jsonb),
    '{budget_tier}',        to_jsonb('mid_range'::text)),
    '{daily_timing}',       to_jsonb('standard'::text)),
    '{accommodation_musthaves}', CASE (meta->>'unit_order')::int
      WHEN 1 THEN '["中心部の立地","駅近","朝食"]'::jsonb
      WHEN 2 THEN '["駅近","朝食"]'::jsonb
      WHEN 3 THEN '["中心部の立地","駅近","朝食"]'::jsonb
      WHEN 4 THEN '["静かな部屋","朝食"]'::jsonb
      ELSE meta->'accommodation_musthaves'
    END)
  WHERE meta->>'seed_batch'='jp-01' AND meta->>'person_id'='0020';

-- Family hotel-budget bumps (total/night, per-pax, and the per-pax column)
UPDATE public.travelers SET meta = jsonb_set(jsonb_set(meta,'{hotel_budget_per_night_eur}',to_jsonb(132000)),'{hotel_budget_per_night_pax_eur}',to_jsonb(26400)), hotel_budget = 26400
  WHERE meta->>'seed_batch'='jp-01' AND meta->>'person_id'='0015';
UPDATE public.travelers SET meta = jsonb_set(jsonb_set(meta,'{hotel_budget_per_night_eur}',to_jsonb(112000)),'{hotel_budget_per_night_pax_eur}',to_jsonb(28000)), hotel_budget = 28000
  WHERE meta->>'seed_batch'='jp-01' AND meta->>'person_id'='0016';
