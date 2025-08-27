-- Backfill support_requests.user_id from email and allow owners to update their own requests
-- Safe to run multiple times

BEGIN;

-- 1) Backfill user_id using user_email/email match with auth.users
UPDATE public.support_requests sr
SET user_id = au.id,
    user_email = COALESCE(sr.user_email, au.email)
FROM auth.users au
WHERE sr.user_id IS NULL
  AND COALESCE(sr.user_email, sr.email) IS NOT NULL
  AND LOWER(COALESCE(sr.user_email, sr.email)) = LOWER(au.email);

-- 2) Coerce legacy statuses to valid values (open/resolved)
UPDATE public.support_requests
SET status = 'open'
WHERE status IS NULL OR status NOT IN ('open','resolved');

-- 3) Policy: allow owners to update their own support requests (in addition to admins)
ALTER TABLE public.support_requests ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Owner update support requests" ON public.support_requests;
CREATE POLICY "Owner update support requests" ON public.support_requests
  FOR UPDATE USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

COMMIT;
