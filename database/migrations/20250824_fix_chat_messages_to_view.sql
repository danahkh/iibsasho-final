-- Fix: convert chat_messages into an updatable view over messages (and migrate any table data)
-- Safe to run multiple times.

BEGIN;

-- Ensure uuid generator exists
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Ensure messages table exists (no-op if it already does)
CREATE TABLE IF NOT EXISTS public.messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  chat_id uuid NOT NULL,
  sender_id uuid NOT NULL,
  content text NOT NULL,
  type text NOT NULL DEFAULT 'text',
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  is_read boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- If chat_messages is currently a TABLE, migrate rows to messages then drop/replace with a VIEW
DO $$
DECLARE obj_kind text;
DECLARE has_content boolean;
DECLARE has_message boolean;
DECLARE has_type boolean;
DECLARE has_metadata boolean;
DECLARE has_is_read boolean;
DECLARE has_created_at boolean;
DECLARE has_timestamp boolean;
DECLARE sel_content text;
DECLARE sel_type text;
DECLARE sel_metadata text;
DECLARE sel_is_read text;
DECLARE sel_created_at text;
DECLARE insert_sql text;
BEGIN
  SELECT c.relkind INTO obj_kind
  FROM pg_class c
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = current_schema() AND c.relname = 'chat_messages';

  IF obj_kind = 'r' THEN -- ordinary table
    -- Rename to legacy for migration
    EXECUTE 'ALTER TABLE public.chat_messages RENAME TO chat_messages_legacy';

    -- Column existence checks
    SELECT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema = current_schema() AND table_name = 'chat_messages_legacy' AND column_name = 'content'
    ) INTO has_content;

    SELECT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema = current_schema() AND table_name = 'chat_messages_legacy' AND column_name = 'message'
    ) INTO has_message;

    SELECT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema = current_schema() AND table_name = 'chat_messages_legacy' AND column_name = 'type'
    ) INTO has_type;

    SELECT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema = current_schema() AND table_name = 'chat_messages_legacy' AND column_name = 'metadata'
    ) INTO has_metadata;

    SELECT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema = current_schema() AND table_name = 'chat_messages_legacy' AND column_name = 'is_read'
    ) INTO has_is_read;

    SELECT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema = current_schema() AND table_name = 'chat_messages_legacy' AND column_name = 'created_at'
    ) INTO has_created_at;

    SELECT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema = current_schema() AND table_name = 'chat_messages_legacy' AND column_name = 'timestamp'
    ) INTO has_timestamp;

    -- Build select expressions based on available columns
    sel_content := CASE WHEN has_content THEN 'content::text'
                        WHEN has_message THEN 'message::text'
                        ELSE quote_literal('') END;

    sel_type := CASE WHEN has_type THEN 'type::text' ELSE quote_literal('text') END;

    sel_metadata := CASE WHEN has_metadata THEN 'metadata::jsonb' ELSE quote_literal('{}') || '::jsonb' END;

    sel_is_read := CASE WHEN has_is_read THEN 'is_read::boolean' ELSE 'false' END;

    sel_created_at := CASE WHEN has_created_at THEN 'created_at::timestamptz'
                           WHEN has_timestamp THEN '"timestamp"::timestamptz'
                           ELSE 'now()' END;

    insert_sql := 'INSERT INTO public.messages (chat_id, sender_id, content, type, metadata, is_read, created_at) '
               || 'SELECT chat_id::uuid, sender_id::uuid, '
               || sel_content || ' AS content, '
               || sel_type || ' AS type, '
               || sel_metadata || ' AS metadata, '
               || sel_is_read || ' AS is_read, '
               || sel_created_at || ' AS created_at '
               || 'FROM public.chat_messages_legacy';

    EXECUTE insert_sql;
  END IF;
END $$;

-- Drop legacy table after migration (if it exists)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = current_schema() AND table_name = 'chat_messages_legacy'
  ) THEN
    EXECUTE 'DROP TABLE public.chat_messages_legacy';
  END IF;
END $$;

-- Drop an existing view to recreate cleanly
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_views WHERE schemaname = current_schema() AND viewname = 'chat_messages'
  ) THEN
    EXECUTE 'DROP VIEW public.chat_messages CASCADE';
  END IF;
END $$;

-- Create the updatable VIEW
CREATE VIEW public.chat_messages AS
SELECT id, chat_id, sender_id, content, type, metadata, is_read, created_at
FROM public.messages;

-- Updatable view trigger functions
CREATE OR REPLACE FUNCTION public.chat_messages_view_ins() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO public.messages (chat_id, sender_id, content, type, metadata, is_read, created_at)
  VALUES (
    NEW.chat_id,
    NEW.sender_id,
    COALESCE(NEW.content, ''),
    COALESCE(NEW.type, 'text'),
    COALESCE(NEW.metadata, '{}'::jsonb),
    COALESCE(NEW.is_read, false),
    COALESCE(NEW.created_at, now())
  ) RETURNING * INTO NEW;
  RETURN NEW;
END$$;

CREATE OR REPLACE FUNCTION public.chat_messages_view_upd() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  UPDATE public.messages
     SET content   = COALESCE(NEW.content, content),
         type      = COALESCE(NEW.type, type),
         metadata  = COALESCE(NEW.metadata, metadata),
         is_read   = COALESCE(NEW.is_read, is_read),
         created_at= COALESCE(NEW.created_at, created_at)
   WHERE id = OLD.id
  RETURNING * INTO NEW;
  RETURN NEW;
END$$;

CREATE OR REPLACE FUNCTION public.chat_messages_view_del() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  DELETE FROM public.messages WHERE id = OLD.id;
  RETURN OLD;
END$$;

-- Attach INSTEAD OF triggers to the view
DROP TRIGGER IF EXISTS chat_messages_view_ins_tr ON public.chat_messages;
CREATE TRIGGER chat_messages_view_ins_tr
INSTEAD OF INSERT ON public.chat_messages
FOR EACH ROW EXECUTE FUNCTION public.chat_messages_view_ins();

DROP TRIGGER IF EXISTS chat_messages_view_upd_tr ON public.chat_messages;
CREATE TRIGGER chat_messages_view_upd_tr
INSTEAD OF UPDATE ON public.chat_messages
FOR EACH ROW EXECUTE FUNCTION public.chat_messages_view_upd();

DROP TRIGGER IF EXISTS chat_messages_view_del_tr ON public.chat_messages;
CREATE TRIGGER chat_messages_view_del_tr
INSTEAD OF DELETE ON public.chat_messages
FOR EACH ROW EXECUTE FUNCTION public.chat_messages_view_del();

-- Ensure chats has columns used by the app
ALTER TABLE public.chats ADD COLUMN IF NOT EXISTS unread_count jsonb NOT NULL DEFAULT '{}'::jsonb;
ALTER TABLE public.chats ADD COLUMN IF NOT EXISTS last_message text;
ALTER TABLE public.chats ADD COLUMN IF NOT EXISTS last_message_time timestamptz;

-- Ensure support_requests has email column used by the app (no-op if it already exists)
ALTER TABLE public.support_requests ADD COLUMN IF NOT EXISTS email text;

COMMIT;
