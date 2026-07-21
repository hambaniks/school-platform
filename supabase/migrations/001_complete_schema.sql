-- ============================================================================
-- SCHOOL PLATFORM v3.0 — Complete Schema
-- Supabase PostgreSQL with RLS, Extensions, Storage Buckets
-- ============================================================================

-- Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

-- ENUMs
DO $$ BEGIN
  CREATE TYPE user_role AS ENUM ('superadmin','schooladmin','teacher','parent','clinic');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  CREATE TYPE attendance_status AS ENUM ('present','late','absent','excused','sick');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  CREATE TYPE alert_severity AS ENUM ('low','medium','high','critical');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  CREATE TYPE alert_status AS ENUM ('inbound','contacted','escalated','resolved');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  CREATE TYPE billing_status AS ENUM ('pending','paid','overdue','exempt','refunded');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  CREATE TYPE consent_status AS ENUM ('granted','denied','pending');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Profiles
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT NOT NULL,
  role user_role NOT NULL DEFAULT 'parent',
  school_id UUID,
  phone TEXT,
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Schools
CREATE TABLE IF NOT EXISTS schools (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  code TEXT UNIQUE NOT NULL,
  address TEXT,
  phone TEXT,
  email TEXT,
  principal_name TEXT,
  region TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Learners
CREATE TABLE IF NOT EXISTS learners (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id UUID NOT NULL REFERENCES schools(id),
  id_number TEXT UNIQUE,
  full_name TEXT NOT NULL,
  grade TEXT NOT NULL,
  class_name TEXT,
  date_of_birth DATE,
  parent_id UUID REFERENCES profiles(id),
  chronic_conditions TEXT[],
  emergency_contact TEXT,
  emergency_phone TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Attendance
CREATE TABLE IF NOT EXISTS attendance (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  learner_id UUID NOT NULL REFERENCES learners(id),
  school_id UUID NOT NULL REFERENCES schools(id),
  date DATE NOT NULL DEFAULT CURRENT_DATE,
  period INTEGER NOT NULL DEFAULT 1,
  status attendance_status NOT NULL,
  marked_by UUID NOT NULL REFERENCES profiles(id),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(learner_id, date, period)
);

-- Clinical Alerts (truancy watchdog results)
CREATE TABLE IF NOT EXISTS clinical_alerts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  learner_id UUID NOT NULL REFERENCES learners(id),
  school_id UUID NOT NULL REFERENCES schools(id),
  consecutive_absences INTEGER NOT NULL DEFAULT 0,
  severity alert_severity DEFAULT 'low',
  status alert_status DEFAULT 'inbound',
  chronic_flag BOOLEAN DEFAULT false,
  assigned_to UUID REFERENCES profiles(id),
  notes TEXT,
  resolved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- POPIA Consent
CREATE TABLE IF NOT EXISTS popia_consent (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  learner_id UUID NOT NULL REFERENCES learners(id),
  parent_id UUID NOT NULL REFERENCES profiles(id),
  status consent_status DEFAULT 'pending',
  consent_date TIMESTAMPTZ,
  revoked_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(learner_id, parent_id)
);

-- Billing
CREATE TABLE IF NOT EXISTS billing (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id UUID NOT NULL REFERENCES schools(id),
  learner_id UUID REFERENCES learners(id),
  parent_id UUID REFERENCES profiles(id),
  amount DECIMAL(10,2) NOT NULL,
  currency TEXT DEFAULT 'ZAR',
  description TEXT,
  status billing_status DEFAULT 'pending',
  due_date DATE,
  paid_at TIMESTAMPTZ,
  payfast_transaction_id TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Immunization Records
CREATE TABLE IF NOT EXISTS immunization (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  learner_id UUID NOT NULL REFERENCES learners(id),
  vaccine_name TEXT NOT NULL,
  dose_number INTEGER,
  date_administered DATE,
  administered_by TEXT,
  next_due_date DATE,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- POPIA Audit Trail
CREATE TABLE IF NOT EXISTS audit_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  actor_id UUID REFERENCES profiles(id),
  action TEXT NOT NULL,
  entity_type TEXT NOT NULL,
  entity_id UUID,
  old_values JSONB,
  new_values JSONB,
  ip_address INET,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Achievement Badges
CREATE TABLE IF NOT EXISTS badges (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  learner_id UUID NOT NULL REFERENCES learners(id),
  badge_type TEXT NOT NULL,
  badge_name TEXT NOT NULL,
  awarded_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(learner_id, badge_type)
);

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE schools ENABLE ROW LEVEL SECURITY;
ALTER TABLE learners ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE clinical_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE popia_consent ENABLE ROW LEVEL SECURITY;
ALTER TABLE billing ENABLE ROW LEVEL SECURITY;
ALTER TABLE immunization ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE badges ENABLE ROW LEVEL SECURITY;

-- RLS: users see their own school's data
CREATE OR REPLACE FUNCTION get_user_school_id() RETURNS UUID LANGUAGE SQL STABLE AS $$
  SELECT COALESCE(
    (SELECT school_id FROM profiles WHERE id = auth.uid()),
    (SELECT raw_user_meta_data->>'school_id'::UUID FROM auth.users WHERE id = auth.uid())
  );
$$;

-- Profiles RLS
CREATE POLICY "profiles_select_own" ON profiles FOR SELECT USING (id = auth.uid());
CREATE POLICY "profiles_select_school" ON profiles FOR SELECT USING (school_id = get_user_school_id());
CREATE POLICY "profiles_update_own" ON profiles FOR UPDATE USING (id = auth.uid()) WITH CHECK (id = auth.uid());

-- Learners RLS
CREATE POLICY "learners_select_school" ON learners FOR SELECT USING (school_id = get_user_school_id());
CREATE POLICY "learners_insert_school" ON learners FOR INSERT WITH CHECK (school_id = get_user_school_id());
CREATE POLICY "learners_update_school" ON learners FOR UPDATE USING (school_id = get_user_school_id());

-- Attendance RLS
CREATE POLICY "attendance_select_school" ON attendance FOR SELECT USING (school_id = get_user_school_id());
CREATE POLICY "attendance_insert_school" ON attendance FOR INSERT WITH CHECK (school_id = get_user_school_id());

-- Clinical Alerts RLS
CREATE POLICY "alerts_select_school" ON clinical_alerts FOR SELECT USING (school_id = get_user_school_id());
CREATE POLICY "alerts_update_clinic" ON clinical_alerts FOR UPDATE USING (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('clinic','superadmin'))
);

-- Billing RLS
CREATE POLICY "billing_select_own" ON billing FOR SELECT USING (parent_id = auth.uid() OR school_id = get_user_school_id());

-- Storage Buckets
INSERT INTO storage.buckets (id, name, public) VALUES
  ('homework-submissions', 'homework-submissions', false),
  ('learning-resources', 'learning-resources', false),
  ('official-reports', 'official-reports', false)
ON CONFLICT (id) DO NOTHING;

-- Storage RLS
CREATE POLICY "storage_select_school" ON storage.objects FOR SELECT USING (bucket_id IN ('homework-submissions','learning-resources','official-reports') AND (storage.foldername(name))[1] = get_user_school_id()::text);
CREATE POLICY "storage_insert_school" ON storage.objects FOR INSERT WITH CHECK ((storage.foldername(name))[1] = get_user_school_id()::text);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_attendance_learner_date ON attendance(learner_id, date);
CREATE INDEX IF NOT EXISTS idx_attendance_school_date ON attendance(school_id, date);
CREATE INDEX IF NOT EXISTS idx_alerts_status ON clinical_alerts(status);
CREATE INDEX IF NOT EXISTS idx_learners_school ON learners(school_id);
CREATE INDEX IF NOT EXISTS idx_billing_school ON billing(school_id);
CREATE INDEX IF NOT EXISTS idx_audit_actor ON audit_log(actor_id);