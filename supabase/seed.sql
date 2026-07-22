-- ============================================================
-- SCHOOLNET v3.0 — Seed Data
-- ============================================================

-- Schools
INSERT INTO schools (id, name, code, domain, address, phone, email, status) VALUES
  ('s0000000-0000-0000-0000-000000000001', 'Kwa-Langa Secondary School', 'KLS001', 'kwalanga.edu.za', '123 Main St, Soweto, Gauteng', '+27 11 123 4567', 'admin@kwalanga.edu.za', 'active'),
  ('s0000000-0000-0000-0000-000000000002', 'Mandela High School', 'MHS002', 'mandelahigh.edu.za', '456 Freedom Rd, Cape Town, WC', '+27 21 987 6543', 'admin@mandelahigh.edu.za', 'active'),
  ('s0000000-0000-0000-0000-000000000003', 'Sunrise Primary School', 'SPS003', 'sunriseprimary.edu.za', '789 Dawn Ave, Durban, KZN', '+27 31 555 7890', 'admin@sunriseprimary.edu.za', 'active')
ON CONFLICT (id) DO NOTHING;

-- Profiles (auth users would be created separately; these are reference profiles)
INSERT INTO profiles (id, full_name, role, school_id, email, phone) VALUES
  ('p0000000-0000-0000-0000-000000000001', 'Dr. Thabo Mbeki', 'superadmin', NULL, 'thabo@schoolnet.gov.za', '+27 82 111 1111'),
  ('p0000000-0000-0000-0000-000000000002', 'Sipho Zulu', 'schooladmin', 's0000000-0000-0000-0000-000000000001', 'sipho.zulu@kwalanga.edu.za', '+27 82 222 2222'),
  ('p0000000-0000-0000-0000-000000000003', 'Nomsa Nkosi', 'teacher', 's0000000-0000-0000-0000-000000000001', 'nomsa.nkosi@kwalanga.edu.za', '+27 82 333 3333'),
  ('p0000000-0000-0000-0000-000000000004', 'Grace Dlamini', 'parent', 's0000000-0000-0000-0000-000000000001', 'grace.dlamini@example.com', '+27 82 444 4444'),
  ('p0000000-0000-0000-0000-000000000005', 'Sister Mary Clinic', 'clinic', 's0000000-0000-0000-0000-000000000001', 'clinic@kwalanga.edu.za', '+27 82 555 5555')
ON CONFLICT (id) DO NOTHING;

-- Classes
INSERT INTO classes (id, school_id, name, grade, teacher_id) VALUES
  ('c0000000-0000-0000-0000-000000000001', 's0000000-0000-0000-0000-000000000001', 'Grade 10A', 10, 'p0000000-0000-0000-0000-000000000003'),
  ('c0000000-0000-0000-0000-000000000002', 's0000000-0000-0000-0000-000000000001', 'Grade 10B', 10, 'p0000000-0000-0000-0000-000000000003'),
  ('c0000000-0000-0000-0000-000000000003', 's0000000-0000-0000-0000-000000000001', 'Grade 11A', 11, 'p0000000-0000-0000-0000-000000000003')
ON CONFLICT (id) DO NOTHING;

-- Learners
INSERT INTO learners (id, school_id, full_name, grade, class_id, parent_id, learner_id_code, date_of_birth, status) VALUES
  ('l0000000-0000-0000-0000-000000000001', 's0000000-0000-0000-0000-000000000001', 'John Dlamini', 10, 'c0000000-0000-0000-0000-000000000001', 'p0000000-0000-0000-0000-000000000004', 'KLS-2024-001', '2008-04-15', 'active'),
  ('l0000000-0000-0000-0000-000000000002', 's0000000-0000-0000-0000-000000000001', 'Sarah Dlamini', 10, 'c0000000-0000-0000-0000-000000000001', 'p0000000-0000-0000-0000-000000000004', 'KLS-2024-002', '2009-01-22', 'active'),
  ('l0000000-0000-0000-0000-000000000003', 's0000000-0000-0000-0000-000000000001', 'Thando Zulu', 11, 'c0000000-0000-0000-0000-000000000003', NULL, 'KLS-2024-003', '2007-09-10', 'active')
ON CONFLICT (id) DO NOTHING;

-- Attendance records (last 7 days)
INSERT INTO attendance (id, learner_id, school_id, date, status, marked_by) SELECT
  gen_random_uuid(), l.id, l.school_id, d.d, 'present', 'p0000000-0000-0000-0000-000000000003'
FROM learners l, (SELECT CURRENT_DATE - generate_series(0,6) AS d) d
WHERE l.id IN ('l0000000-0000-0000-0000-000000000001', 'l0000000-0000-0000-0000-000000000002', 'l0000000-0000-0000-0000-000000000003')
ON CONFLICT DO NOTHING;

-- One truancy record for testing
INSERT INTO attendance (id, learner_id, school_id, date, status, marked_by) VALUES
  (gen_random_uuid(), 'l0000000-0000-0000-0000-000000000001', 's0000000-0000-0000-0000-000000000001', CURRENT_DATE - 2, 'absent', 'p0000000-0000-0000-0000-000000000003'),
  (gen_random_uuid(), 'l0000000-0000-0000-0000-000000000001', 's0000000-0000-0000-0000-000000000001', CURRENT_DATE - 1, 'absent', 'p0000000-0000-0000-0000-000000000003')
ON CONFLICT DO NOTHING;

-- App controls
INSERT INTO app_controls (key, value, description) VALUES
  ('billing.learner_fee', '20', 'Monthly learner fee (ZAR)'),
  ('billing.parent_fee', '100', 'Monthly parent fee (ZAR)'),
  ('truancy.threshold_days', '3', 'Days before truancy alert triggers'),
  ('truancy.alert_enabled', 'true', 'Enable truancy watchdog automation'),
  ('app.name', 'SchoolNet v3.0', 'Application display name'),
  ('app.theme', 'cyberpunk', 'UI theme')
ON CONFLICT (key) DO NOTHING;
