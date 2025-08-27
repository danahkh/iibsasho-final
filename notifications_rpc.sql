-- Create a SECURITY DEFINER function to insert notifications reliably via RPC
-- Safe to re-run
CREATE OR REPLACE FUNCTION public.fn_create_notification(
  p_user_id UUID,
  p_title TEXT,
  p_message TEXT,
  p_type TEXT,
  p_related_id UUID DEFAULT NULL,
  p_related_type TEXT DEFAULT NULL,
  p_metadata JSONB DEFAULT '{}'::jsonb
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id UUID;
BEGIN
  -- Enforce allowed types to respect table CHECK constraint
  IF p_type NOT IN ('comment','message','favorite') THEN
    p_type := 'message';
  END IF;

  INSERT INTO public.notifications(
    user_id, title, message, type, related_id, related_type, is_read, created_at, metadata
  ) VALUES (
    p_user_id, p_title, p_message, p_type, p_related_id, p_related_type, FALSE, timezone('utc'::text, now()), COALESCE(p_metadata, '{}'::jsonb)
  ) RETURNING id INTO v_id;

  RETURN v_id;
END;
$$;

-- Ensure only minimal rights to execute
REVOKE ALL ON FUNCTION public.fn_create_notification(UUID, TEXT, TEXT, TEXT, UUID, TEXT, JSONB) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.fn_create_notification(UUID, TEXT, TEXT, TEXT, UUID, TEXT, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fn_create_notification(UUID, TEXT, TEXT, TEXT, UUID, TEXT, JSONB) TO anon;
