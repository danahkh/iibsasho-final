-- Setup storage buckets for iibsasho app
-- Run this in your Supabase SQL editor

-- Create listings bucket for listing images and videos
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'listings',
  'listings', 
  true,
  10485760, -- 10MB limit
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'video/mp4', 'video/quicktime', 'video/avi', 'video/x-msvideo']
)
ON CONFLICT (id) DO NOTHING;

-- Create avatars bucket for profile images
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'avatars',
  'avatars',
  true,
  5242880, -- 5MB limit
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']
)
ON CONFLICT (id) DO NOTHING;

-- Set up RLS policies for listings bucket
CREATE POLICY "Anyone can view listing files" ON storage.objects
  FOR SELECT USING (bucket_id = 'listings');

CREATE POLICY "Authenticated users can upload listing files" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'listings' 
    AND auth.role() = 'authenticated'
  );

CREATE POLICY "Users can update their own listing files" ON storage.objects
  FOR UPDATE WITH CHECK (
    bucket_id = 'listings' 
    AND auth.role() = 'authenticated'
  );

CREATE POLICY "Users can delete their own listing files" ON storage.objects
  FOR DELETE USING (
    bucket_id = 'listings' 
    AND auth.role() = 'authenticated'
  );

-- Set up RLS policies for avatars bucket
CREATE POLICY "Anyone can view avatar files" ON storage.objects
  FOR SELECT USING (bucket_id = 'avatars');

CREATE POLICY "Authenticated users can upload avatar files" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'avatars' 
    AND auth.role() = 'authenticated'
  );

CREATE POLICY "Users can update their own avatar files" ON storage.objects
  FOR UPDATE WITH CHECK (
    bucket_id = 'avatars' 
    AND auth.role() = 'authenticated'
  );

CREATE POLICY "Users can delete their own avatar files" ON storage.objects
  FOR DELETE USING (
    bucket_id = 'avatars' 
    AND auth.role() = 'authenticated'
  );
