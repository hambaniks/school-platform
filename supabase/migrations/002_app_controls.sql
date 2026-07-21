-- ============================================================================
-- APP CONTROLS: Feature flags, thresholds, runtime config
-- ============================================================================
CREATE TABLE IF NOT EXISTS app_controls (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  key TEXT UNIQUE NOT NULL,
  value JSONB NOT NULL,
  description TEXT,
  updated_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Default controls
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

-- Trigger-based audit logging
CREATE OR REPLACE FUNCTION audit_trigger() RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO audit_log (actor_id, action, entity_type, entity_id, old_values, new_values)
  VALUES (
    auth.uid(),
    TG_OP,
    TG_TABLE_NAME,
    COALESCE(NEW.id, OLD.id),
    CASE WHEN TG_OP IN ('UPDATE','DELETE') THEN row_to_json(OLD)::jsonb ELSE NULL END,
    CASE WHEN TG_OP IN ('INSERT','UPDATE') THEN row_to_json(NEW)::jsonb ELSE NULL END
  );
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Attach audit triggers to sensitive tables
DROP TRIGGER IF EXISTS audit_profiles ON profiles;
CREATE TRIGGER audit_profiles AFTER INSERT OR UPDATE OR DELETE ON profiles FOR EACH ROW EXECUTE FUNCTION audit_trigger();
DROP TRIGGER IF EXISTS audit_learners ON learners;
CREATE TRIGGER audit_learners AFTER INSERT OR UPDATE OR DELETE ON learners FOR EACH ROW EXECUTE FUNCTION audit_trigger();
DROP TRIGGER IF EXISTS audit_billing ON billing;
CREATE TRIGGER audit_billing AFTER INSERT OR UPDATE OR DELETE ON billing FOR EACH ROW EXECUTE FUNCTION audit_trigger();
DROP TRIGGER IF EXISTS audit_popia ON popia_consent;
CREATE TRIGGER audit_popia AFTER INSERT OR UPDATE OR DELETE ON popia_consent FOR EACH ROW EXECUTE FUNCTION audit_trigger();