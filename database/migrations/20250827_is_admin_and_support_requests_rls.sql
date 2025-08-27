-- Ensure admin detection function and align support_requests schema, constraint, and RLS
-- Safe and idempotent; can be run multiple times

BEGIN;

-- 1) Admin detection helper
CREATE OR REPLACE FUNCTION public.is_admin() RETURNS boolean
LANGUAGE plpgsql STABLE AS $$
DECLARE v boolean := false; BEGIN
  BEGIN
    SELECT COALESCE(u.role = 'admin', false) OR COALESCE(u.is_admin, false)
    INTO v
    FROM public.users u
    WHERE u.id = auth.uid();
  EXCEPTION WHEN OTHERS THEN v := false; END;

  IF NOT v THEN
    BEGIN
      PERFORM 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='profiles';
      IF FOUND THEN
        SELECT COALESCE(p.is_admin,false) INTO v FROM public.profiles p WHERE p.id = auth.uid();
      END IF;
    EXCEPTION WHEN OTHERS THEN v := v; END;
  END IF;
  RETURN v;
END; $$;
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;

-- 2) support_requests: add missing columns used by app
ALTER TABLE public.support_requests
  ADD COLUMN IF NOT EXISTS title text,
  ADD COLUMN IF NOT EXISTS message text,
  ADD COLUMN IF NOT EXISTS details text,
  ADD COLUMN IF NOT EXISTS user_email text,
  ADD COLUMN IF NOT EXISTS resolved_at timestamptz,
  ADD COLUMN IF NOT EXISTS resolved_by uuid;

-- 3) Relax/align status constraint to expected enum values
DO $$
DECLARE has_constraint boolean;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM information_schema.constraint_column_usage c
    JOIN information_schema.table_constraints t ON t.constraint_name=c.constraint_name
    WHERE c.table_schema='public' AND c.table_name='support_requests' AND c.column_name='status'
  ) INTO has_constraint;

  IF has_constraint THEN
    BEGIN
      ALTER TABLE public.support_requests DROP CONSTRAINT IF EXISTS support_requests_status_check;
    EXCEPTION WHEN OTHERS THEN NULL; END;
  END IF;

  BEGIN
    ALTER TABLE public.support_requests ADD CONSTRAINT support_requests_status_check
      CHECK (status IN ('open','resolved'));
  EXCEPTION WHEN OTHERS THEN NULL; END;
END $$;

-- 4) RLS policies: owner can read/insert own; admin can manage all
ALTER TABLE public.support_requests ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Select own support requests" ON public.support_requests;
DROP POLICY IF EXISTS "Insert support request" ON public.support_requests;
DROP POLICY IF EXISTS "Admin manage support requests" ON public.support_requests;
CREATE POLICY "Select own support requests" ON public.support_requests FOR SELECT USING (user_id = auth.uid() OR public.is_admin());
CREATE POLICY "Insert support request" ON public.support_requests FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Admin manage support requests" ON public.support_requests FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());
-- Also allow owners to update their own requests (explicit owner policy)
DROP POLICY IF EXISTS "Owner update support requests" ON public.support_requests;
CREATE POLICY "Owner update support requests" ON public.support_requests FOR UPDATE USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
GRANT SELECT, INSERT, UPDATE ON public.support_requests TO authenticated;

COMMIT;
