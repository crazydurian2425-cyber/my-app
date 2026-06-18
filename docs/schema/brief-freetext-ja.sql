-- ============================================================================
-- Traveler brief free-text JA — special_notes_ja + must_avoid_ja in meta.
--
-- The brief's free-text fields (the traveler memo "旅行者からのメモ" and
-- "must avoid") have no dict key, so they showed English in JA mode. This adds
-- a JA version into meta; the dashboard (travLocale) prefers meta.<field>_ja in
-- JA mode and falls back to the English column/value otherwise. Mirrors the
-- occasion_ja approach. Keyed by exact English text; idempotent (re-sets same
-- value). Rows whose text does not match are left to fall back to English.
-- ============================================================================

-- must_avoid (in meta)
UPDATE public.travelers SET meta = jsonb_set(meta,'{must_avoid_ja}',to_jsonb($ja$観光客向けすぎる場所、混雑、ありきたりな提案$ja$::text))
  WHERE meta->>'must_avoid' = $sn$Tourist traps, crowds, anything generic$sn$;

-- special_notes (top-level column) → meta.special_notes_ja
UPDATE public.travelers SET meta = jsonb_set(meta,'{special_notes_ja}',to_jsonb($ja$長編の写真集を仕上げたばかりで、創作の充電をしたいと思っています。東京、日光の社寺、箱根、そして京都の庭園や隠れた名所で、静かな光を追いかけたいです。$ja$::text))
  WHERE special_notes = $sn$Wrapped a long photo book and need a creative reset. Want to chase quiet light through Tokyo, Nikko's shrines, Hakone, and Kyoto's gardens and hidden corners.$sn$;
UPDATE public.travelers SET meta = jsonb_set(meta,'{special_notes_ja}',to_jsonb($ja$48歳を前に、自国にはない北国の風景を見たいと思っています。北海道でのハイキング、湯けむり立つ温泉、おいしいウイスキー、そして函館のじんわり染みる眺めを楽しみたいです。$ja$::text))
  WHERE special_notes = $sn$The year before 48, I want northern landscapes that aren't my own. Hokkaido hikes, steaming onsen, a good whisky, and Hakodate's slow-burn views.$sn$;
UPDATE public.travelers SET meta = jsonb_set(meta,'{special_notes_ja}',to_jsonb($ja$リードエンジニアに昇進したお祝いに、初めてのひとり旅を予約しました。大阪から姫路、広島、宮島まで、お城や本物の歴史、そしておいしい食事を楽しみたいです。$ja$::text))
  WHERE special_notes = $sn$Just made lead engineer and booked my first solo trip ever to celebrate. Want castles, real history, and great food from Osaka to Himeji, Hiroshima, and Miyajima.$sn$;
UPDATE public.travelers SET meta = jsonb_set(meta,'{special_notes_ja}',to_jsonb($ja$ビーチで過ごすのはもったいないと、3週間の休暇を取りました。別府、由布院、長崎を中心に、九州の温泉地や路地裏のラーメン、静かな丘の散策を楽しみたいです。$ja$::text))
  WHERE special_notes = $sn$Three weeks of leave I refused to waste on a beach. Chasing Kyushu's onsen towns, backstreet ramen, and quiet hill walks around Beppu, Yufuin, and Nagasaki.$sn$;
UPDATE public.travelers SET meta = jsonb_set(meta,'{special_notes_ja}',to_jsonb($ja$大変な契約をまとめ終え、少しペースを落としたいと思っています。東京、河口湖、京都で、庭園や美しい建築を眺めながら、おいしい食事や買い物を楽しむゆったりとした日々を過ごしたいです。$ja$::text))
  WHERE special_notes = $sn$Closed a tough deal and need to slow down. Want gardens, beautiful architecture, and easy days with great food and shopping across Tokyo, Kawaguchiko, and Kyoto.$sn$;
UPDATE public.travelers SET meta = jsonb_set(meta,'{special_notes_ja}',to_jsonb($ja$ドヒョンが激務の末にようやくパートナーに昇進し、そのご褒美の旅です。東京、日光、箱根、京都を巡りながら、朝はお寺、夜は温泉、そしてカメラ片手にゆったり過ごす時間を楽しみたいです。$ja$::text))
  WHERE special_notes = $sn$Do-hyun finally made partner after years of brutal hours, so this is our reward. We want temple mornings, onsen evenings, and time to slow down with our cameras across Tokyo, Nikko, Hakone and Kyoto.$sn$;
UPDATE public.travelers SET meta = jsonb_set(meta,'{special_notes_ja}',to_jsonb($ja$末っ子が大学に進学し、11年ぶりに夫婦だけの旅です。大阪、姫路、広島、宮島を巡りながら、お城や歴史、そして地元の暮らしを存分に味わいたいです。$ja$::text))
  WHERE special_notes = $sn$First trip without the kids in eleven years now the youngest is off to uni. We're craving castles, history and proper local life through Osaka, Himeji, Hiroshima and Miyajima.$sn$;
UPDATE public.travelers SET meta = jsonb_set(meta,'{special_notes_ja}',to_jsonb($ja$第一子を授かる前に、かねてより計画していた夏の旅です。札幌、小樽、ニセコを巡りながら、静かな散策路や写真映えする風景、そしておいしい日本酒とともに過ごす温泉の夜を楽しみたいです。$ja$::text))
  WHERE special_notes = $sn$A long-planned summer escape before we try for our first child. We want quiet trails, photogenic corners and slow onsen nights with good sake across Sapporo, Otaru and Niseko.$sn$;
UPDATE public.travelers SET meta = jsonb_set(meta,'{special_notes_ja}',to_jsonb($ja$結婚10周年、ずっと先延ばしにしてきた旅をついに実現します。大阪から高山、白川郷、金沢まで、印象的な建築や職人の町、そしておいしい日本酒を巡りたいです。$ja$::text))
  WHERE special_notes = $sn$Tenth anniversary, finally cashing in the trip we kept postponing. We're after striking architecture, craft towns and great sake from Osaka to Takayama, Shirakawa-go and Kanazawa.$sn$;
UPDATE public.travelers SET meta = jsonb_set(meta,'{special_notes_ja}',to_jsonb($ja$1年間の遠距離を経て、ようやく一緒に過ごせる旅です。福岡、別府、由布院、長崎を巡りながら、温泉地やおいしい食事、のんびりした散歩など、二人で急がない時間を過ごしたいです。$ja$::text))
  WHERE special_notes = $sn$Reuniting at last after a year of long-distance apart. We just want unhurried days together — onsen towns, good food and easy walks through Fukuoka, Beppu, Yufuin and Nagasaki.$sn$;
UPDATE public.travelers SET meta = jsonb_set(meta,'{special_notes_ja}',to_jsonb($ja$新婚旅行です。東京や大阪の賑わいのあとは、静かなお寺の朝、庭園に差す光、そして温泉でのひとときを楽しみたいです。京都はずっと夢見ていた場所です。$ja$::text))
  WHERE special_notes = $sn$On our honeymoon and chasing quiet temple mornings, garden light, and an onsen soak after the buzz of Tokyo and Osaka. Kyoto is the one I've dreamed of.$sn$;
UPDATE public.travelers SET meta = jsonb_set(meta,'{special_notes_ja}',to_jsonb($ja$結婚したばかりで、二人で北海道の雄大な自然を満喫したいです。散策路や雪原、湯けむり立つ温泉、そして合間には小樽の古い街並みを歩きたいです。$ja$::text))
  WHERE special_notes = $sn$Just married and craving Hokkaido's wild side together — trails, snowfields and steaming onsen, with Otaru's old streets to wander between adventures.$sn$;
UPDATE public.travelers SET meta = jsonb_set(meta,'{special_notes_ja}',to_jsonb($ja$日本の歴史を巡る新婚旅行です。姫路城、広島、宮島の鳥居を訪ね、最後は大阪でおいしい日本酒とともにくつろぎたいです。$ja$::text))
  WHERE special_notes = $sn$Honeymooning through Japan's history — Himeji's castle, Hiroshima, the torii at Miyajima — then unwinding over good sake back in Osaka.$sn$;
UPDATE public.travelers SET meta = jsonb_set(meta,'{special_notes_ja}',to_jsonb($ja$結婚15周年を記念して、子どもたちが夢見た日本旅行をついに実現します。東京でアニメ巡り、京都でお寺めぐり、そして箱根の温泉でゆっくり過ごしたいです。$ja$::text))
  WHERE special_notes = $sn$Marking 15 years married by finally giving the kids their dream Japan trip — anime hunts in Tokyo, temples in Kyoto, and a Hakone onsen to slow down.$sn$;
UPDATE public.travelers SET meta = jsonb_set(meta,'{special_notes_ja}',to_jsonb($ja$受験で夏休みがなくなる前に、家族で最後の大きな冒険を。北海道でハイキングをし、小樽で写真を撮り、みんなで温泉に浸かりたいです。$ja$::text))
  WHERE special_notes = $sn$One last big family adventure before exam years swallow our summers — hiking Hokkaido, photographing Otaru, and soaking in an onsen all together.$sn$;
UPDATE public.travelers SET meta = jsonb_set(meta,'{special_notes_ja}',to_jsonb($ja$両親からの贈り物で、40歳の節目を祝う旅です。子どもたちが初めての温泉でどんな顔をするのか、今から楽しみでなりません。静かな温泉地やおいしい食事、そして穴場の発見を楽しみたいです。$ja$::text))
  WHERE special_notes = $sn$Turning 40 with a trip my parents gifted us, and I cannot wait to see the kids' faces at their very first onsen. Want quiet hot-spring towns, great food, and a few off-the-map finds.$sn$;
UPDATE public.travelers SET meta = jsonb_set(meta,'{special_notes_ja}',to_jsonb($ja$双子が学校を終えてそれぞれの道に進む前の、最後の大きな旅です。お寺や静かな散策路、そして一緒に写真に収めたくなるような光や景色を楽しみたいです。$ja$::text))
  WHERE special_notes = $sn$My last big adventure with the twins before school ends and they scatter. I want temples, quiet trails, and the kind of light and views worth photographing together.$sn$;
UPDATE public.travelers SET meta = jsonb_set(meta,'{special_notes_ja}',to_jsonb($ja$10年前の卒業時に交わした約束を、4人でついに実現します。昼はお寺を巡り、合間にラーメンや屋台のグルメを味わい、生活に追われる前の今のうちに、夜はしっかり遊びたいです。$ja$::text))
  WHERE special_notes = $sn$Four of us finally cashing in a graduation promise from a decade ago. We want temples by day, ramen and street food between, and proper nights out before life gets in the way.$sn$;
UPDATE public.travelers SET meta = jsonb_set(meta,'{special_notes_ja}',to_jsonb($ja$両親の結婚40周年に、子ども二人も一緒の旅です。冷蔵庫に貼ってあった行きたい場所リストから、北海道をついに実現します。雄大な自然や気持ちのいい温泉、庭園、そして地元の日本酒を楽しみたいです。$ja$::text))
  WHERE special_notes = $sn$Mum and Dad's 40th anniversary, with us two kids along, finally crossing Hokkaido off their fridge list. We want big nature, good soaks, gardens, and a local sake or two.$sn$;
UPDATE public.travelers SET meta = jsonb_set(meta,'{special_notes_ja}',to_jsonb($ja$歴史教師仲間3人で、20年間職員室で語り合ってきた念願の旅です。日本のお城や戦争の歴史、封建時代の足跡を巡りたいです。$ja$::text))
  WHERE special_notes = $sn$Three old history-teacher mates on the bucket-list trip we've plotted in staffrooms for twenty years, chasing Japan's castles, wartime stories, and feudal past.$sn$;
UPDATE public.travelers SET meta = jsonb_set(meta,'{special_notes_ja}',to_jsonb($ja$多忙な一年のご褒美に、京都で数日間ゆっくり過ごします。上質な懐石、静かなお寺の朝、そして泊まる価値のある部屋を楽しみたいです。$ja$::text))
  WHERE special_notes = $sn$Treating myself to a few slow days in Kyoto after a relentless year — refined kaiseki, quiet temple mornings, and a room worth staying in.$sn$;
UPDATE public.travelers SET meta = jsonb_set(meta,'{special_notes_ja}',to_jsonb($ja$記念日の旅です。食にはこだわりがあります。おまかせのカウンター、忘れられない一度きりのコース、そして眺めのよい高層階の部屋を希望します。$ja$::text))
  WHERE special_notes = $sn$Our anniversary. We are serious about food — omakase counters, one unforgettable tasting menu, and a high-floor room with a view.$sn$;
UPDATE public.travelers SET meta = jsonb_set(meta,'{special_notes_ja}',to_jsonb($ja$新婚旅行です。貸切の露天風呂、部屋食の懐石、そして二人だけで過ごす予定のない時間を楽しみたいです。$ja$::text))
  WHERE special_notes = $sn$Our honeymoon. A private open-air bath, in-room kaiseki, and nothing on the schedule but each other.$sn$;
UPDATE public.travelers SET meta = jsonb_set(meta,'{special_notes_ja}',to_jsonb($ja$金沢への工芸とアートの旅です。金箔細工の工房、古い茶屋街、そして予約の取れる最高の寿司店を楽しみたいです。$ja$::text))
  WHERE special_notes = $sn$A craft-and-art trip to Kanazawa — gold-leaf workshops, the old geisha streets, and the best sushi counter you can get me into.$sn$;
UPDATE public.travelers SET meta = jsonb_set(meta,'{special_notes_ja}',to_jsonb($ja$結婚25周年です。アマンクラスの宿泊、貸切の茶道体験、そして混雑のない京都の庭園を楽しみたいです。$ja$::text))
  WHERE special_notes = $sn$Twenty-five years married. We would love an Aman-level stay, a private tea ceremony, and Kyoto gardens without the crowds.$sn$;
UPDATE public.travelers SET meta = jsonb_set(meta,'{special_notes_ja}',to_jsonb($ja$子どもたちと過ごす夏休みです。沖縄で、ビーチフロントのファミリースイート、ハラル対応の食事、そして海辺でのんびり過ごす日々を希望します。$ja$::text))
  WHERE special_notes = $sn$Summer with the children. We need a beachfront family suite, halal-friendly dining, and easy days by the water in Okinawa.$sn$;
UPDATE public.travelers SET meta = jsonb_set(meta,'{special_notes_ja}',to_jsonb($ja$新婚旅行です。川沿いのスイート、ミシュランの懐石を一夜、そして可能であれば芸妓さんとの一夕を楽しみたいです。$ja$::text))
  WHERE special_notes = $sn$Our honeymoon — a riverside suite, one Michelin kaiseki night, and an evening with a geiko if it can be arranged.$sn$;
UPDATE public.travelers SET meta = jsonb_set(meta,'{special_notes_ja}',to_jsonb($ja$5人での節目のお祝いの旅です。隣り合うスイート、プライベートダイニング、そして普段はお金では買えないような体験を楽しみたいです。$ja$::text))
  WHERE special_notes = $sn$Celebrating a milestone as a group of five. Connecting suites, private dining, and a few experiences money usually cannot buy.$sn$;
UPDATE public.travelers SET meta = jsonb_set(meta,'{special_notes_ja}',to_jsonb($ja$ティーンエイジャーの子どもたちと、グリーンシーズンのニセコへ。温泉付きの2ベッドルームスイート、山の空気、そして一日外で過ごしたあとの本格的な食事を楽しみたいです。$ja$::text))
  WHERE special_notes = $sn$Green-season Niseko with the teenagers — a two-bedroom suite with onsen, mountain air, and proper food after a day outdoors.$sn$;
UPDATE public.travelers SET meta = jsonb_set(meta,'{special_notes_ja}',to_jsonb($ja$箱根での特別な記念日の旅です。専用風呂付きのグランドスイート、彫刻の森美術館、そして晴れた朝の富士山を楽しみたいです。$ja$::text))
  WHERE special_notes = $sn$A special anniversary in Hakone — a grand suite with a private bath, the open-air museum, and Fuji on a clear morning.$sn$;
UPDATE public.travelers SET meta = jsonb_set(meta,'{special_notes_ja}',to_jsonb($ja$費用を惜しまない新婚旅行です。アマンのスイート、専用庭園、そして二人だけで過ごす夜の静かなお寺のひとときを楽しみたいです。$ja$::text))
  WHERE special_notes = $sn$Our honeymoon, no expense spared — an Aman suite, a private garden, and a quiet after-hours temple moment for the two of us.$sn$;
UPDATE public.travelers SET meta = jsonb_set(meta,'{special_notes_ja}',to_jsonb($ja$三世代で一緒の旅です。父のために隣接するバリアフリーのスイートが必要で、みんなが一緒に楽しめる、穏やかで負担の少ない日々を希望します。$ja$::text))
  WHERE special_notes = $sn$Three generations, one trip. We need adjoining, barrier-free suites for my father, and calm, accessible days everyone can share.$sn$;

-- Verify: SELECT special_notes, meta->>'special_notes_ja' FROM public.travelers
--   WHERE coalesce(meta->>'special_notes_ja','') <> '' ORDER BY 1;
