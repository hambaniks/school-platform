-- ============================================================
-- SCHOOLNET v3.0 — Storage Buckets & Policies
-- ============================================================

-- Create buckets
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types) VALUES
  ('avatars', 'avatars', true, 2097152, ARRAY['image/png', 'image/jpeg', 'image/webp', 'image/gif']),
  ('attachments', 'attachments', false, 10485760, ARRAY[
    'application/pdf', 'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'image/png', 'image/jpeg', 'image/webp'
  ]),
  ('exports', 'exports', false, 52428800, ARRAY[
    'application/pdf', 'text/csv',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/vnd.ms-excel'
  ]),
  ('health-uploads', 'health-uploads', false, 20971520, ARRAY[
    'application/pdf', 'image/png', 'image/jpeg', 'image/webp'
  ])
ON CONFLICT (id) DO NOTHING;

-- Bucket RLS policies
CREATE POLICY "Avatars are public" ON storage.objects
  FOR SELECT USING (bucket_id = 'avatars');

CREATE POLICY "Users can upload own avatar" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can delete own avatar" ON storage.objects
  FOR DELETE USING (
    bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Authenticated users can read attachments" ON storage.objects
  FOR SELECT USING (bucket_id = 'attachments' AND auth.role() = 'authenticated');

CREATE POLICY "Staff can upload attachments" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'attachments' AND EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('teacher','schooladmin','superadmin','clinic')
    )
  );

CREATE POLICY "Authenticated users can read exports" ON storage.objects
  FOR SELECT USING (bucket_id = 'exports' AND auth.role() = 'authenticated');

CREATE POLICY "Staff can upload exports" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'exports' AND EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('teacher','schooladmin','superadmin','clinic')
    )
  );

CREATE POLICY "Clinic staff can manage health uploads" ON storage.objects
  FOR ALL USING (
    bucket_id = 'health-uploads' AND EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('clinic','schooladmin','superadmin')
    )
  );
