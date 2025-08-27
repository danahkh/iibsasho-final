-- Create support_messages table and RLS for threaded support conversations
-- Safe to run multiple times

BEGIN;

CREATE TABLE IF NOT EXISTS public.support_messages (
  id bigserial PRIMARY KEY,
  support_request_id uuid NOT NULL REFERENCES public.support_requests(id) ON DELETE CASCADE,
  message text NOT NULL,
  sender_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  sender_role text CHECK (sender_role IN ('admin','user')),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_support_messages_request_created
  ON public.support_messages (support_request_id, created_at ASC);

ALTER TABLE public.support_messages ENABLE ROW LEVEL SECURITY;

-- Select: owner or admin can see messages for their request
DROP POLICY IF EXISTS "Select support messages" ON public.support_messages;
CREATE POLICY "Select support messages" ON public.support_messages
  FOR SELECT USING (
    public.is_admin() OR
    EXISTS (
      SELECT 1 FROM public.support_requests r
      WHERE r.id = support_request_id AND r.user_id = auth.uid()
    )
  );

-- Insert: requester can add messages to their own request; admins to any
DROP POLICY IF EXISTS "Insert support messages" ON public.support_messages;
CREATE POLICY "Insert support messages" ON public.support_messages
  FOR INSERT WITH CHECK (
    public.is_admin() OR
    EXISTS (
      SELECT 1 FROM public.support_requests r
      WHERE r.id = support_request_id AND r.user_id = auth.uid()
    )
  );

GRANT SELECT, INSERT ON public.support_messages TO authenticated;

COMMIT;
