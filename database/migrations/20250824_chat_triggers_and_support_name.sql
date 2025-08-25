-- Ensure indexes and triggers to keep chats metadata fresh and unread counts accurate
-- Safe to run multiple times

BEGIN;

-- Helpful indexes
CREATE INDEX IF NOT EXISTS idx_messages_chat_id_created_at
  ON public.messages (chat_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_chats_last_message_time
  ON public.chats (last_message_time DESC NULLS LAST);

-- Add missing columns used by app logic (no-op if exist)
ALTER TABLE public.support_requests
  ADD COLUMN IF NOT EXISTS name text;

-- Function: after a new message, update chats.last_message/_time and increment receiver's unread_count
CREATE OR REPLACE FUNCTION public.chat_on_message_insert() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_seller uuid;
  v_buyer uuid;
  v_receiver uuid;
  v_uc jsonb;
  v_key text;
  v_old int;
BEGIN
  SELECT seller_id, buyer_id INTO v_seller, v_buyer
  FROM public.chats
  WHERE id = NEW.chat_id;

  IF NOT FOUND THEN
    RETURN NEW; -- unknown chat, nothing to update
  END IF;

  v_receiver := CASE WHEN NEW.sender_id = v_seller THEN v_buyer ELSE v_seller END;
  v_key := v_receiver::text;
  SELECT COALESCE(unread_count, '{}'::jsonb) INTO v_uc FROM public.chats WHERE id = NEW.chat_id;
  v_old := COALESCE((v_uc ->> v_key)::int, 0);

  UPDATE public.chats
     SET last_message = NEW.content,
         last_message_time = NEW.created_at,
         unread_count = jsonb_set(COALESCE(unread_count, '{}'::jsonb), ARRAY[v_key], to_jsonb(v_old + 1), true)
   WHERE id = NEW.chat_id;

  RETURN NEW;
END$$;

-- Function: when a message is marked read, decrement the recipient's unread_count by 1 (not dropping below 0)
CREATE OR REPLACE FUNCTION public.chat_on_message_mark_read() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_seller uuid;
  v_buyer uuid;
  v_recipient uuid;
  v_key text;
  v_uc jsonb;
  v_old int;
  v_new int;
BEGIN
  -- Only act on transition false -> true
  IF (OLD.is_read IS DISTINCT FROM TRUE) AND (NEW.is_read = TRUE) THEN
    SELECT seller_id, buyer_id INTO v_seller, v_buyer
    FROM public.chats
    WHERE id = NEW.chat_id;

    IF NOT FOUND THEN
      RETURN NEW;
    END IF;

    -- Recipient is the non-sender side
    v_recipient := CASE WHEN NEW.sender_id = v_seller THEN v_buyer ELSE v_seller END;
    v_key := v_recipient::text;
    SELECT COALESCE(unread_count, '{}'::jsonb) INTO v_uc FROM public.chats WHERE id = NEW.chat_id;
    v_old := COALESCE((v_uc ->> v_key)::int, 0);
    v_new := GREATEST(v_old - 1, 0);

    UPDATE public.chats
       SET unread_count = jsonb_set(COALESCE(unread_count, '{}'::jsonb), ARRAY[v_key], to_jsonb(v_new), true)
     WHERE id = NEW.chat_id;
  END IF;

  RETURN NEW;
END$$;

-- Attach triggers (idempotent)
DROP TRIGGER IF EXISTS trg_chat_on_message_insert ON public.messages;
CREATE TRIGGER trg_chat_on_message_insert
AFTER INSERT ON public.messages
FOR EACH ROW EXECUTE FUNCTION public.chat_on_message_insert();

DROP TRIGGER IF EXISTS trg_chat_on_message_mark_read ON public.messages;
CREATE TRIGGER trg_chat_on_message_mark_read
AFTER UPDATE OF is_read ON public.messages
FOR EACH ROW EXECUTE FUNCTION public.chat_on_message_mark_read();

-- Backfill existing chats metadata from messages
-- 1) last_message and last_message_time from the latest message
WITH latest AS (
  SELECT m.chat_id, m.content, m.created_at,
         ROW_NUMBER() OVER (PARTITION BY m.chat_id ORDER BY m.created_at DESC) rn
  FROM public.messages m
), agg AS (
  SELECT chat_id,
         MAX(content) FILTER (WHERE rn = 1) AS last_content,
         MAX(created_at) FILTER (WHERE rn = 1) AS last_time
  FROM latest
  GROUP BY chat_id
)
UPDATE public.chats c
SET last_message = a.last_content,
    last_message_time = a.last_time
FROM agg a
WHERE c.id = a.chat_id;

-- 2) unread_count per user (seller and buyer)
WITH counts AS (
  SELECT c.id AS chat_id,
         c.seller_id,
         c.buyer_id,
         COALESCE((
           SELECT COUNT(*) FROM public.messages m
           WHERE m.chat_id = c.id AND m.sender_id <> c.seller_id AND m.is_read = false
         ), 0) AS seller_unread,
         COALESCE((
           SELECT COUNT(*) FROM public.messages m
           WHERE m.chat_id = c.id AND m.sender_id <> c.buyer_id AND m.is_read = false
         ), 0) AS buyer_unread
  FROM public.chats c
)
UPDATE public.chats c
SET unread_count = jsonb_build_object(
      c.seller_id::text, counts.seller_unread,
      c.buyer_id::text, counts.buyer_unread
    )
FROM counts
WHERE c.id = counts.chat_id;

COMMIT;
