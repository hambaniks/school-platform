-- ============================================================================
-- SCHOOL PLATFORM v3.0 — COMPLETE FIXED MIGRATION
-- Safe to re-run (uses IF NOT EXISTS / DROP IF EXISTS)
-- ============================================================================

-- PART 1: EXTENSIONS & ENUMS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

DO $$ BEGIN CREATE TYPE user_role AS ENUM ('superadmin','schooladmin','teacher','parent','clinic','finance_admin','compliance_officer','transport_admin'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE attendance_status AS ENUM ('present','late','absent','excused','sick'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE alert_severity AS ENUM ('low','medium','high','critical'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE alert_status AS ENUM ('inbound','contacted','escalated','resolved'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE billing_status AS ENUM ('pending','paid','overdue','exempt','refunded'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE consent_status AS ENUM ('granted','denied','pending'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- PART 2: CORE TABLES
CREATE TABLE IF NOT EXISTS schools (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL, code TEXT UNIQUE NOT NULL, address TEXT,
  phone TEXT, email TEXT, principal_name TEXT, region TEXT,
  is_active BOOLEAN DEFAULT true, created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL, full_name TEXT NOT NULL,
  role user_role NOT NULL DEFAULT 'parent',
  school_id UUID REFERENCES schools(id), clinic_id UUID,
  phone TEXT, avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT now(), updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS learners (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id UUID NOT NULL REFERENCES schools(id),
  id_number TEXT UNIQUE, full_name TEXT NOT NULL,
  grade TEXT NOT NULL, class_name TEXT, date_of_birth DATE,
  parent_id UUID REFERENCES profiles(id),
  chronic_conditions TEXT[], emergency_contact TEXT, emergency_phone TEXT,
  is_active BOOLEAN DEFAULT true, created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS attendance (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  learner_id UUID NOT NULL REFERENCES learners(id),
  school_id UUID NOT NULL REFERENCES schools(id),
  date DATE NOT NULL DEFAULT CURRENT_DATE, period INTEGER NOT NULL DEFAULT 1,
  status attendance_status NOT NULL, marked_by UUID NOT NULL REFERENCES profiles(id),
  notes TEXT, created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(learner_id, date, period)
);

CREATE TABLE IF NOT EXISTS clinical_alerts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  learner_id UUID NOT NULL REFERENCES learners(id),
  school_id UUID NOT NULL REFERENCES schools(id),
  consecutive_absences INTEGER NOT NULL DEFAULT 0,
  severity alert_severity DEFAULT 'low', status alert_status DEFAULT 'inbound',
  chronic_flag BOOLEAN DEFAULT false, assigned_to UUID REFERENCES profiles(id),
  notes TEXT, resolved_at TIMESTAMPTZ, created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS truancy_predictions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  learner_id UUID NOT NULL REFERENCES learners(id),
  school_id UUID NOT NULL REFERENCES schools(id),
  risk_score NUMERIC NOT NULL DEFAULT 0, attendance_rate NUMERIC DEFAULT 100,
  days_absent_30d INTEGER DEFAULT 0, trend TEXT DEFAULT 'stable',
  flags TEXT[] DEFAULT '{}', recommended_action TEXT, model_version TEXT,
  predicted_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS popia_consent (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  learner_id UUID NOT NULL REFERENCES learners(id),
  parent_id UUID NOT NULL REFERENCES profiles(id),
  status consent_status DEFAULT 'pending',
  consent_date TIMESTAMPTZ, revoked_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(), UNIQUE(learner_id, parent_id)
);

CREATE TABLE IF NOT EXISTS billing (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id UUID NOT NULL REFERENCES schools(id),
  learner_id UUID REFERENCES learners(id), parent_id UUID REFERENCES profiles(id),
  amount DECIMAL(10,2) NOT NULL, currency TEXT DEFAULT 'ZAR', description TEXT,
  status billing_status DEFAULT 'pending', due_date DATE, paid_at TIMESTAMPTZ,
  payfast_transaction_id TEXT, created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS immunization (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  learner_id UUID NOT NULL REFERENCES learners(id),
  vaccine_name TEXT NOT NULL, dose_number INTEGER,
  date_administered DATE, administered_by TEXT, next_due_date DATE,
  notes TEXT, created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS submissions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  learner_id UUID NOT NULL REFERENCES learners(id),
  subject TEXT NOT NULL, assignment_title TEXT NOT NULL,
  file_url TEXT, status TEXT DEFAULT 'pending',
  score DECIMAL(5,2), max_score DECIMAL(5,2) DEFAULT 100,
  confidence DECIMAL(5,2), feedback TEXT, graded_by UUID REFERENCES profiles(id),
  submitted_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS teacher_subjects (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  teacher_id UUID NOT NULL REFERENCES profiles(id),
  subject TEXT NOT NULL, school_id UUID REFERENCES schools(id),
  UNIQUE(teacher_id, subject)
);

CREATE TABLE IF NOT EXISTS audit_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  actor_id UUID REFERENCES profiles(id),
  action TEXT NOT NULL, entity_type TEXT NOT NULL, entity_id UUID,
  old_values JSONB, new_values JSONB, ip_address INET,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS badges (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  learner_id UUID NOT NULL REFERENCES learners(id),
  badge_type TEXT NOT NULL, badge_name TEXT NOT NULL,
  awarded_at TIMESTAMPTZ DEFAULT now(), UNIQUE(learner_id, badge_type)
);

CREATE TABLE IF NOT EXISTS app_controls (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  key TEXT UNIQUE NOT NULL, value JSONB NOT NULL, description TEXT,
  updated_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT now(), updated_at TIMESTAMPTZ DEFAULT now()
);

-- PART 3: DEFAULT CONTROLS
INSERT INTO app_controls (key, value, description) VALUES
  ('attendance_cutoff_time', '"14:00"', 'Daily attendance lock time'),
  ('truancy_threshold_days', '3', 'Days before truancy alert triggers'),
  ('billing_exempt_roles', '["superadmin"]', 'Roles exempt from auto-billing'),
  ('payfast_school_fee', '20', 'R20 per learner per month'),
  ('payfast_parent_fee', '100', 'R100 per parent per year'),
  ('health_pdf_day', '1', 'Day of month to generate health PDFs'),
  ('max_consecutive_absences', '10', 'Auto-escalate after this many'),
  ('maintenance_mode', 'false', 'Global maintenance toggle')
ON CONFLICT (key) DO NOTHING;

-- PART 4: AUDIT TRIGGER
CREATE OR REPLACE FUNCTION audit_trigger() RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO audit_log (actor_id, action, entity_type, entity_id, old_values, new_values)
  VALUES (auth.uid(), TG_OP, TG_TABLE_NAME, COALESCE(NEW.id, OLD.id),
    CASE WHEN TG_OP IN ('UPDATE','DELETE') THEN row_to_json(OLD)::jsonb ELSE NULL END,
    CASE WHEN TG_OP IN ('INSERT','UPDATE') THEN row_to_json(NEW)::jsonb ELSE NULL END);
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
DROP TRIGGER IF EXISTS audit_profiles ON profiles;
CREATE TRIGGER audit_profiles AFTER INSERT OR UPDATE OR DELETE ON profiles FOR EACH ROW EXECUTE FUNCTION audit_trigger();
DROP TRIGGER IF EXISTS audit_learners ON learners;
CREATE TRIGGER audit_learners AFTER INSERT OR UPDATE OR DELETE ON learners FOR EACH ROW EXECUTE FUNCTION audit_trigger();
DROP TRIGGER IF EXISTS audit_billing ON billing;
CREATE TRIGGER audit_billing AFTER INSERT OR UPDATE OR DELETE ON billing FOR EACH ROW EXECUTE FUNCTION audit_trigger();
DROP TRIGGER IF EXISTS audit_popia ON popia_consent;
CREATE TRIGGER audit_popia AFTER INSERT OR UPDATE OR DELETE ON popia_consent FOR EACH ROW EXECUTE FUNCTION audit_trigger();

-- PART 5: FIXED get_user_school_id() — BUG WAS: raw_user_meta_data->>'school_id'::UUID
-- The :: cast operator has higher precedence than ->>, so it tried to cast 'school_id' literal to UUID
CREATE OR REPLACE FUNCTION get_user_school_id() RETURNS UUID LANGUAGE SQL STABLE AS $$
  SELECT COALESCE(
    (SELECT school_id FROM profiles WHERE id = auth.uid()),
    ((SELECT raw_user_meta_data->>'school_id' FROM auth.users WHERE id = auth.uid()))::UUID
  );
$$;

-- PART 6: ROW LEVEL SECURITY (all tables)
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE schools ENABLE ROW LEVEL SECURITY;
ALTER TABLE learners ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE clinical_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE truancy_predictions ENABLE ROW LEVEL SECURITY;
ALTER TABLE popia_consent ENABLE ROW LEVEL SECURITY;
ALTER TABLE billing ENABLE ROW LEVEL SECURITY;
ALTER TABLE immunization ENABLE ROW LEVEL SECURITY;
ALTER TABLE submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_controls ENABLE ROW LEVEL SECURITY;

-- Profiles
DROP POLICY IF EXISTS "profiles_select_own" ON profiles;
CREATE POLICY "profiles_select_own" ON profiles FOR SELECT USING (id = auth.uid());
DROP POLICY IF EXISTS "profiles_select_school" ON profiles;
CREATE POLICY "profiles_select_school" ON profiles FOR SELECT USING (school_id = get_user_school_id());
DROP POLICY IF EXISTS "profiles_update_own" ON profiles;
CREATE POLICY "profiles_update_own" ON profiles FOR UPDATE USING (id = auth.uid()) WITH CHECK (id = auth.uid());

-- Learners: school-scoped + parent view
DROP POLICY IF EXISTS "learners_select_school" ON learners;
CREATE POLICY "learners_select_school" ON learners FOR SELECT USING (school_id = get_user_school_id());
DROP POLICY IF EXISTS "learners_parent_view" ON learners;
CREATE POLICY "learners_parent_view" ON learners FOR SELECT USING (parent_id = auth.uid());
DROP POLICY IF EXISTS "learners_insert_school" ON learners;
CREATE POLICY "learners_insert_school" ON learners FOR INSERT WITH CHECK (school_id = get_user_school_id());
DROP POLICY IF EXISTS "learners_update_school" ON learners;
CREATE POLICY "learners_update_school" ON learners FOR UPDATE USING (school_id = get_user_school_id());

-- Attendance
DROP POLICY IF EXISTS "attendance_select_school" ON attendance;
CREATE POLICY "attendance_select_school" ON attendance FOR SELECT USING (school_id = get_user_school_id());
DROP POLICY IF EXISTS "attendance_insert_school" ON attendance;
CREATE POLICY "attendance_insert_school" ON attendance FOR INSERT WITH CHECK (school_id = get_user_school_id());

-- Clinical Alerts
DROP POLICY IF EXISTS "alerts_select_school" ON clinical_alerts;
CREATE POLICY "alerts_select_school" ON clinical_alerts FOR SELECT USING (school_id = get_user_school_id());
DROP POLICY IF EXISTS "alerts_update_clinic" ON clinical_alerts;
CREATE POLICY "alerts_update_clinic" ON clinical_alerts FOR UPDATE USING (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('clinic','superadmin'))
);

-- Truancy Predictions
DROP POLICY IF EXISTS "truancy_select_school" ON truancy_predictions;
CREATE POLICY "truancy_select_school" ON truancy_predictions FOR SELECT USING (school_id = get_user_school_id());

-- Billing
DROP POLICY IF EXISTS "billing_select_own" ON billing;
CREATE POLICY "billing_select_own" ON billing FOR SELECT USING (parent_id = auth.uid() OR school_id = get_user_school_id());

-- Immunization
DROP POLICY IF EXISTS "immunization_select" ON immunization;
CREATE POLICY "immunization_select" ON immunization FOR SELECT USING (
  learner_id IN (SELECT id FROM learners WHERE school_id = get_user_school_id() OR parent_id = auth.uid())
);

-- Submissions
DROP POLICY IF EXISTS "submissions_select" ON submissions;
CREATE POLICY "submissions_select" ON submissions FOR SELECT USING (
  learner_id IN (SELECT id FROM learners WHERE school_id = get_user_school_id() OR parent_id = auth.uid())
);

-- Audit Log: compliance only
DROP POLICY IF EXISTS "audit_select_compliance" ON audit_log;
CREATE POLICY "audit_select_compliance" ON audit_log FOR SELECT USING (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('superadmin','compliance_officer'))
);

-- PART 7: STORED FUNCTIONS
CREATE OR REPLACE FUNCTION get_at_risk_students(p_risk_threshold INT DEFAULT 55)
RETURNS TABLE (student_id UUID, student_name TEXT, grade TEXT, class TEXT, risk_score NUMERIC, attendance_rate NUMERIC, days_absent INT, trend TEXT, flags TEXT[], recommended_action TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY SELECT l.id, l.full_name, l.grade, l.class_name, tp.risk_score, tp.attendance_rate, tp.days_absent_30d, tp.trend::TEXT, tp.flags, tp.recommended_action
  FROM truancy_predictions tp JOIN learners l ON l.id = tp.learner_id
  WHERE tp.risk_score >= p_risk_threshold AND l.school_id = get_user_school_id()
  ORDER BY tp.risk_score DESC;
END;
$$;

CREATE OR REPLACE FUNCTION get_visible_invoices()
RETURNS SETOF billing LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE user_role TEXT;
BEGIN
  SELECT role::TEXT INTO user_role FROM profiles WHERE id = auth.uid();
  IF user_role IN ('superadmin', 'finance_admin') THEN
    RETURN QUERY SELECT * FROM billing ORDER BY created_at DESC;
  ELSIF user_role = 'parent' THEN
    RETURN QUERY SELECT b.* FROM billing b JOIN learners l ON l.id = b.learner_id WHERE l.parent_id = auth.uid() ORDER BY b.created_at DESC;
  ELSE RETURN QUERY SELECT * FROM billing WHERE FALSE; END IF;
END;
$$;

-- PART 8: INDEXES
CREATE INDEX IF NOT EXISTS idx_attendance_learner_date ON attendance(learner_id, date);
CREATE INDEX IF NOT EXISTS idx_attendance_school_date ON attendance(school_id, date);
CREATE INDEX IF NOT EXISTS idx_alerts_status ON clinical_alerts(status);
CREATE INDEX IF NOT EXISTS idx_learners_school ON learners(school_id);
CREATE INDEX IF NOT EXISTS idx_billing_school ON billing(school_id);
CREATE INDEX IF NOT EXISTS idx_audit_actor ON audit_log(actor_id);
CREATE INDEX IF NOT EXISTS idx_truancy_risk ON truancy_predictions(risk_score DESC);
CREATE INDEX IF NOT EXISTS idx_submissions_learner ON submissions(learner_id);

-- PART 9: STORAGE BUCKETS
INSERT INTO storage.buckets (id, name, public) VALUES
  ('homework-submissions', 'homework-submissions', false),
  ('learning-resources', 'learning-resources', false),
  ('official-reports', 'official-reports', false)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "storage_select_school" ON storage.objects;
CREATE POLICY "storage_select_school" ON storage.objects FOR SELECT USING (
  bucket_id IN ('homework-submissions','learning-resources','official-reports')
  AND (storage.foldername(name))[1] = get_user_school_id()::text
);
DROP POLICY IF EXISTS "storage_insert_school" ON storage.objects;
CREATE POLICY "storage_insert_school" ON storage.objects FOR INSERT WITH CHECK (
  (storage.foldername(name))[1] = get_user_school_id()::text
);