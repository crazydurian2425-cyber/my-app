-- ============================================================================
-- Japan travelers — move the LAST-unit flight home to ~16:00-17:00 (4-5pm)
--
-- The jp-01 seed had final international flights departing 10:30-14:30, which
-- forced an early checkout and left no usable last day. Travelers now check out
-- ~11:00, have lunch, head to the airport ~3h early (airport_buffer_minutes is
-- already 180), and fly home mid-afternoon.
--
-- Updates ONLY each person's final leg: unit_order = unit_total AND
-- unit_departure_method = 'flight'. Keyed by seed_batch='jp-01' + person_id.
-- Idempotent. Pairs with docs/schema/seed-japan-travelers.sql (seed updated too).
-- ============================================================================

UPDATE public.travelers AS t
SET meta = jsonb_set(t.meta, '{unit_departure_time}', to_jsonb(v.dep_time::text), true)
FROM (VALUES
  ('0001', '16:40'),
  ('0002', '16:30'),
  ('0003', '16:55'),
  ('0004', '16:20'),
  ('0005', '16:50'),
  ('0006', '16:15'),
  ('0007', '16:35'),
  ('0008', '17:00'),
  ('0009', '16:25'),
  ('0010', '16:45'),
  ('0011', '16:55'),
  ('0012', '16:30'),
  ('0013', '16:50'),
  ('0014', '16:20'),
  ('0015', '17:00'),
  ('0016', '16:35'),
  ('0017', '16:45'),
  ('0018', '16:30'),
  ('0019', '16:40'),
  ('0020', '16:55')
) AS v(person_id, dep_time)
WHERE t.meta->>'seed_batch'           = 'jp-01'
  AND t.meta->>'person_id'            = v.person_id
  AND (t.meta->>'unit_order')::int    = (t.meta->>'unit_total')::int
  AND t.meta->>'unit_departure_method' = 'flight';

-- Verify (optional):
-- SELECT meta->>'person_id' AS pid, destination, meta->>'unit_departure_time' AS flight_time,
--        meta->>'unit_departure_to' AS flying_to
-- FROM public.travelers
-- WHERE meta->>'seed_batch' = 'jp-01'
--   AND (meta->>'unit_order')::int = (meta->>'unit_total')::int
-- ORDER BY pid;
