-- ============================================================================
-- Japan travelers — make meta.room_type France-clear (rooms · guests · split)
--
-- The jp-01 seed stored bare room labels ("Family room", "Connecting rooms")
-- with no room count, so a planner couldn't tell how many rooms a 3+ guest
-- traveler wants. This rewrites room_type to the France style — e.g.
-- "2 connecting rooms · 4 guests (2 adults + 2 children)" — for ALL 20 people
-- (every brief now shows rooms + guests, exactly like the France market).
--
-- Keyed by meta.seed_batch='jp-01' + meta.person_id, so it updates every unit
-- row of each traveler. Idempotent — safe to re-run.
-- Pair of: docs/schema/seed-japan-travelers.sql (the seed now writes these too).
-- ============================================================================

UPDATE public.travelers AS t
SET meta = jsonb_set(t.meta, '{room_type}', to_jsonb(v.room_type::text), true)
FROM (VALUES
  ('0001', '1 single room · 1 guest'),
  ('0002', '1 single room · 1 guest'),
  ('0003', '1 single room · 1 guest'),
  ('0004', '1 single room · 1 guest'),
  ('0005', '1 single room · 1 guest'),
  ('0006', '1 double room · 2 guests'),
  ('0007', '1 double room · 2 guests'),
  ('0008', '1 double room · 2 guests'),
  ('0009', '1 double room · 2 guests'),
  ('0010', '1 double room · 2 guests'),
  ('0011', '1 junior suite · 2 guests'),
  ('0012', '1 junior suite · 2 guests'),
  ('0013', '1 junior suite · 2 guests'),
  ('0014', '2 connecting rooms · 4 guests (2 adults + 2 children)'),
  ('0015', '3 connecting rooms · 5 guests (2 per room + 1)'),
  ('0016', '2 connecting rooms · 4 guests (2 adults + 2 children)'),
  ('0017', '2 rooms · 3 guests (1 double + 1 twin for the teens)'),
  ('0018', '2 twin rooms · 4 guests (2 per room)'),
  ('0019', '2 rooms · 4 guests (2 per room)'),
  ('0020', '2 rooms · 3 guests (1 double + 1 single)')
) AS v(person_id, room_type)
WHERE t.meta->>'seed_batch' = 'jp-01'
  AND t.meta->>'person_id'  = v.person_id;

-- Verify (optional): one row per person with the new room_type.
-- SELECT meta->>'person_id' AS pid, name, group_size, meta->>'room_type' AS room_type
-- FROM public.travelers
-- WHERE meta->>'seed_batch' = 'jp-01'
-- GROUP BY meta->>'person_id', name, group_size, meta->>'room_type'
-- ORDER BY pid;
