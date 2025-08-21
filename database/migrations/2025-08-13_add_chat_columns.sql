-- Adds columns used by the enhanced chat service for ordering and metadata
-- Safe to run multiple times with IF NOT EXISTS checks

alter table if exists public.chats
  add column if not exists last_message_time timestamptz null,
  add column if not exists last_message_sender_id text null;

-- Optional: create an index to improve ordering/filtering by last_message_time
create index if not exists idx_chats_last_message_time
  on public.chats (last_message_time desc nulls last);

-- Optional: if you often filter by updated_at as fallback
create index if not exists idx_chats_updated_at
  on public.chats (updated_at desc nulls last);
