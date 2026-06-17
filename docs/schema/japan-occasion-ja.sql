-- ============================================================================
-- Japan travelers — Japanese occasion (シーン) for the planner dashboard.
--
-- The occasion is free-text and can't be dict-localized, so we store a JA
-- version alongside the English one: meta.occasion (EN, backend) is untouched;
-- meta.occasion_ja (JA) is added. The planner dashboard shows occasion_ja in
-- Japanese mode, falling back to the English occasion when absent.
--
-- Keyed by the exact English occasion text, so every unit-row of a traveler
-- gets it. Idempotent (re-running just re-sets the same value). Rows whose
-- occasion doesn't match are left unchanged (dashboard falls back to English).
-- ============================================================================
UPDATE public.travelers SET meta = jsonb_set(meta,'{occasion_ja}',to_jsonb('長編写真集を完成させた後の、創作をリフレッシュするひとり旅'::text))
  WHERE meta->>'occasion' = 'Solo creative reset after finishing a long photo book project';
UPDATE public.travelers SET meta = jsonb_set(meta,'{occasion_ja}',to_jsonb('48歳を迎える前年の節目のひとり旅。自国にはない北国の風景を求めて'::text))
  WHERE meta->>'occasion' = 'Milestone solo trip the year before turning 48, chasing northern landscapes that aren''t his own';
UPDATE public.travelers SET meta = jsonb_set(meta,'{occasion_ja}',to_jsonb('初めての海外ひとり旅。リードエンジニアに昇進した週に予約'::text))
  WHERE meta->>'occasion' = 'First solo trip abroad, booked the week she got promoted to lead engineer';
UPDATE public.travelers SET meta = jsonb_set(meta,'{occasion_ja}',to_jsonb('ビーチリゾートでは過ごしたくない、3週間の永年勤続休暇'::text))
  WHERE meta->>'occasion' = 'Three weeks of long-service leave he refused to spend on a beach resort';
UPDATE public.travelers SET meta = jsonb_set(meta,'{occasion_ja}',to_jsonb('大きな契約をまとめた後、心を整えるための静かなひとり旅'::text))
  WHERE meta->>'occasion' = 'Quiet solo trip to reset after closing a demanding deal at work';
UPDATE public.travelers SET meta = jsonb_set(meta,'{occasion_ja}',to_jsonb('激務の末についに事務所のパートナーになったドヒョンさんのお祝い'::text))
  WHERE meta->>'occasion' = 'Celebrating Do-hyun finally making partner at his firm after years of brutal hours';
UPDATE public.travelers SET meta = jsonb_set(meta,'{occasion_ja}',to_jsonb('末っ子が大学に入り、11年ぶりとなる子ども抜きの旅行'::text))
  WHERE meta->>'occasion' = 'First trip without the kids in eleven years, now that the youngest started university';
UPDATE public.travelers SET meta = jsonb_set(meta,'{occasion_ja}',to_jsonb('第一子を授かる前に、かねてより計画していた夏の休暇'::text))
  WHERE meta->>'occasion' = 'A long-planned summer escape before trying for their first child';
UPDATE public.travelers SET meta = jsonb_set(meta,'{occasion_ja}',to_jsonb('結婚10周年。先延ばしにしてきた旅行をついに実現'::text))
  WHERE meta->>'occasion' = 'Tenth wedding anniversary, finally cashing in the trip they kept postponing';
UPDATE public.travelers SET meta = jsonb_set(meta,'{occasion_ja}',to_jsonb('1年間の遠距離恋愛を経て、久しぶりに二人で過ごす本物の休暇'::text))
  WHERE meta->>'occasion' = 'Reuniting for a real holiday after a year apart in a long-distance relationship';
UPDATE public.travelers SET meta = jsonb_set(meta,'{occasion_ja}',to_jsonb('新婚旅行 — 二人で初めての日本。東京と、富士山麓の静かな湖畔の旅館で過ごす'::text))
  WHERE meta->>'occasion' = 'Honeymoon — a first trip to Japan together, splitting time between Tokyo and a quiet lakeside ryokan beneath Mt. Fuji.';
UPDATE public.travelers SET meta = jsonb_set(meta,'{occasion_ja}',to_jsonb('北海道での新婚旅行 — 結婚式の慌ただしさの後、涼やかな夏の空気と新鮮な海の幸、静かな温泉の夜を'::text))
  WHERE meta->>'occasion' = 'Honeymoon in Hokkaido — cool summer air, fresh seafood, and quiet onsen evenings after the wedding rush.';
UPDATE public.travelers SET meta = jsonb_set(meta,'{occasion_ja}',to_jsonb('瀬戸内海をめぐる新婚旅行 — 姫路城、広島、そして宮島の旅館で一泊'::text))
  WHERE meta->>'occasion' = 'Honeymoon along the Seto Inland Sea — Himeji Castle, Hiroshima, and a night in a ryokan on Miyajima.';
UPDATE public.travelers SET meta = jsonb_set(meta,'{occasion_ja}',to_jsonb('結婚15周年を記念し、子どもたちに約束していた念願の旅行をついに実現'::text))
  WHERE meta->>'occasion' = 'Celebrating our 15th wedding anniversary by finally taking the kids on the bucket-list trip we promised them';
UPDATE public.travelers SET meta = jsonb_set(meta,'{occasion_ja}',to_jsonb('長子が受験期に入り、家族の夏が終わってしまう前の、大きな家族の冒険'::text))
  WHERE meta->>'occasion' = 'A big family adventure before our eldest starts exam years and the summers stop being ours';
UPDATE public.travelers SET meta = jsonb_set(meta,'{occasion_ja}',to_jsonb('40歳の誕生日を祝う九州の家族旅行 — 子どもたちは初めての温泉を体験'::text))
  WHERE meta->>'occasion' = 'A 40th-birthday family trip through Kyushu — the children experience their very first onsen.';
UPDATE public.travelers SET meta = jsonb_set(meta,'{occasion_ja}',to_jsonb('母と双子の旅 — 娘たちが学校を卒業して巣立つ前の、最後の大きな冒険'::text))
  WHERE meta->>'occasion' = 'A mother-and-twins trip — my last big adventure with the girls before they finish school and scatter';
UPDATE public.travelers SET meta = jsonb_set(meta,'{occasion_ja}',to_jsonb('大学時代の仲間4人組。10年前の卒業時に交わした「子どもや住宅ローンで叶わなくなる前に一緒に日本へ」という約束をついに実現'::text))
  WHERE meta->>'occasion' = 'Four college barkada finally cashing in a promise made at graduation a decade ago to do Japan together before kids and mortgages made it impossible';
UPDATE public.travelers SET meta = jsonb_set(meta,'{occasion_ja}',to_jsonb('二世代の家族旅行 — 退職した両親と成人した二人の子ども。両親の結婚40周年を記念し、長年冷蔵庫に貼っていた「行きたい場所リスト」から北海道をついに実現'::text))
  WHERE meta->>'occasion' = 'A two-generation family trip — retired parents and their two grown children — for the parents'' 40th wedding anniversary, finally crossing Hokkaido off the list they kept on the fridge for years';
UPDATE public.travelers SET meta = jsonb_set(meta,'{occasion_ja}',to_jsonb('20年前に新人歴史教師として出会った3人の友人。職員室で語り合い続けてきた念願の旅をついに実現 — 日本の戦争史と封建時代の歴史をめぐって'::text))
  WHERE meta->>'occasion' = 'Three friends who met as junior history teachers two decades ago, now taking the bucket-list trip they''ve talked about in every staffroom since — built around Japan''s wartime and feudal history';
UPDATE public.travelers SET meta = jsonb_set(meta,'{occasion_ja}',to_jsonb('多忙な一年を経た心の充電のひとり旅。京都で過ごす上質な数日間'::text))
  WHERE meta->>'occasion' = 'Solo reset after a relentless year, a few refined days in Kyoto';
UPDATE public.travelers SET meta = jsonb_set(meta,'{occasion_ja}',to_jsonb('食にこだわる夫婦の記念日旅行'::text))
  WHERE meta->>'occasion' = 'Anniversary trip for a couple who take food seriously';
UPDATE public.travelers SET meta = jsonb_set(meta,'{occasion_ja}',to_jsonb('新婚旅行 — 貸切温泉、部屋食の懐石、完全なプライバシー'::text))
  WHERE meta->>'occasion' = 'Honeymoon — private onsen, in-room kaiseki, total privacy';
UPDATE public.travelers SET meta = jsonb_set(meta,'{occasion_ja}',to_jsonb('工芸とアートを巡る金沢への旅'::text))
  WHERE meta->>'occasion' = 'Craft-and-art pilgrimage to Kanazawa';
UPDATE public.travelers SET meta = jsonb_set(meta,'{occasion_ja}',to_jsonb('結婚25周年'::text))
  WHERE meta->>'occasion' = '25th wedding anniversary';
UPDATE public.travelers SET meta = jsonb_set(meta,'{occasion_ja}',to_jsonb('沖縄での夏の家族旅行'::text))
  WHERE meta->>'occasion' = 'Summer family holiday in Okinawa';
UPDATE public.travelers SET meta = jsonb_set(meta,'{occasion_ja}',to_jsonb('京都での新婚旅行'::text))
  WHERE meta->>'occasion' = 'Honeymoon in Kyoto';
UPDATE public.travelers SET meta = jsonb_set(meta,'{occasion_ja}',to_jsonb('5人家族の節目のお祝い'::text))
  WHERE meta->>'occasion' = 'Milestone celebration for a family group of five';
UPDATE public.travelers SET meta = jsonb_set(meta,'{occasion_ja}',to_jsonb('ティーンエイジャーの子どもと行く、グリーンシーズンのニセコ家族旅行'::text))
  WHERE meta->>'occasion' = 'Green-season family trip to Niseko with teenagers';
UPDATE public.travelers SET meta = jsonb_set(meta,'{occasion_ja}',to_jsonb('箱根での特別な記念日'::text))
  WHERE meta->>'occasion' = 'Special anniversary in Hakone';
UPDATE public.travelers SET meta = jsonb_set(meta,'{occasion_ja}',to_jsonb('費用を惜しまない新婚旅行'::text))
  WHERE meta->>'occasion' = 'Honeymoon, no expense spared';
UPDATE public.travelers SET meta = jsonb_set(meta,'{occasion_ja}',to_jsonb('三世代でのお祝い旅行'::text))
  WHERE meta->>'occasion' = 'Three-generation celebration trip';

-- Verify: SELECT meta->>'occasion' AS en, meta->>'occasion_ja' AS ja FROM public.travelers
--   WHERE meta ? 'occasion' ORDER BY 1;
