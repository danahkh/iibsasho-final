-- ============================================================================
-- Master Schema & RLS Definition Script (WITH FEATURE CREDIT MIGRATION BLOCK)
-- ============================================================================

create extension if not exists "pgcrypto";

-- Admin function resilient to missing profiles
create or replace function public.is_admin() returns boolean language plpgsql stable as $$
declare exists_profiles boolean := false; is_admin_role boolean := false; begin
  select exists (select 1 from information_schema.tables where table_schema='public' and table_name='profiles') into exists_profiles;
  if exists_profiles then
    begin
      select coalesce(p.is_admin,false) into is_admin_role from public.profiles p where p.id = auth.uid();
    exception when others then is_admin_role := false; end;
  end if; return is_admin_role; end; $$;
grant execute on function public.is_admin() to authenticated;

-- FEATURE CREDIT ACCOUNTS ----------------------------------------------------
create table if not exists public.feature_credit_accounts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users(id) on delete cascade,
  credits_total int not null default 0,
  credits_used int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Migration: add & backfill columns if they were absent / legacy names existed
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='feature_credit_accounts' AND column_name='credits_total'
  ) THEN
    ALTER TABLE public.feature_credit_accounts ADD COLUMN credits_total int NOT NULL DEFAULT 0;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='feature_credit_accounts' AND column_name='credits') THEN
      EXECUTE 'UPDATE public.feature_credit_accounts SET credits_total = credits';
    ELSIF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='feature_credit_accounts' AND column_name='total_credits') THEN
      EXECUTE 'UPDATE public.feature_credit_accounts SET credits_total = total_credits';
    END IF;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='feature_credit_accounts' AND column_name='credits_used'
  ) THEN
    ALTER TABLE public.feature_credit_accounts ADD COLUMN credits_used int NOT NULL DEFAULT 0;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='feature_credit_accounts' AND column_name='used_credits') THEN
      EXECUTE 'UPDATE public.feature_credit_accounts SET credits_used = used_credits';
    ELSIF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='feature_credit_accounts' AND column_name='credits_consumed') THEN
      EXECUTE 'UPDATE public.feature_credit_accounts SET credits_used = credits_consumed';
    END IF;
  END IF;
END $$;

create index if not exists idx_feature_credit_accounts_user on public.feature_credit_accounts(user_id);

-- Rebuild view (drop first to allow column name adjustments idempotently)
drop view if exists public.v_feature_credit_balance;
create view public.v_feature_credit_balance as
select
  user_id,
  credits_total,
  credits_used,
  (credits_total - credits_used) as credits_available
from public.feature_credit_accounts;

-- PROMOTION REQUESTS ---------------------------------------------------------
create table if not exists public.promotion_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  listing_id text,
  promotion_type text not null check (promotion_type in ('standard','premium','featured')),
  payment_message text,
  credits_used int not null default 0,
  status text not null default 'pending',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists idx_promotion_requests_user on public.promotion_requests(user_id);
create index if not exists idx_promotion_requests_created on public.promotion_requests(created_at desc);

-- COMMENTS -------------------------------------------------------------------
create table if not exists public.comments (
  id text primary key,
  listing_id text not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  user_name text,
  user_photo_url text,
  text text not null,
  parent_id text references public.comments(id) on delete cascade,
  like_count int not null default 0,
  created_at timestamptz not null default now()
);
-- Migration for legacy comments table (add missing columns safely)
DO $$
BEGIN
  -- parent_id
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='comments' AND column_name='parent_id'
  ) THEN
    ALTER TABLE public.comments ADD COLUMN parent_id text;
    ALTER TABLE public.comments
      ADD CONSTRAINT comments_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.comments(id) ON DELETE CASCADE;
  END IF;
  -- like_count
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='comments' AND column_name='like_count'
  ) THEN
    ALTER TABLE public.comments ADD COLUMN like_count int NOT NULL DEFAULT 0;
  END IF;
  -- user_name (if previously named username)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='comments' AND column_name='user_name'
  ) THEN
    IF EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema='public' AND table_name='comments' AND column_name='username'
    ) THEN
      EXECUTE 'ALTER TABLE public.comments RENAME COLUMN username TO user_name';
    ELSE
      ALTER TABLE public.comments ADD COLUMN user_name text;
    END IF;
  END IF;
  -- user_photo_url
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='comments' AND column_name='user_photo_url'
  ) THEN
    ALTER TABLE public.comments ADD COLUMN user_photo_url text;
  END IF;
END $$;
create index if not exists idx_comments_listing_created on public.comments(listing_id, created_at desc);
create index if not exists idx_comments_parent on public.comments(parent_id);

create table if not exists public.comment_likes (
  id uuid primary key default gen_random_uuid(),
  comment_id text not null references public.comments(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique(comment_id, user_id)
);
create index if not exists idx_comment_likes_comment on public.comment_likes(comment_id);
create index if not exists idx_comment_likes_user on public.comment_likes(user_id);

create or replace function public.increment_comment_like_count(p_comment_id text)
returns void language sql security definer as $$
  update public.comments set like_count = like_count + 1 where id = p_comment_id; $$;
create or replace function public.decrement_comment_like_count(p_comment_id text)
returns void language sql security definer as $$
  update public.comments set like_count = greatest(like_count - 1,0) where id = p_comment_id; $$;
grant execute on function public.increment_comment_like_count(text) to authenticated;
grant execute on function public.decrement_comment_like_count(text) to authenticated;

-- CHATS ----------------------------------------------------------------------
create table if not exists public.chats (
  id text primary key,
  participants text[] not null,
  listing_id text,
  listing_title text,
  last_message text,
  last_message_time timestamptz,
  last_message_sender_id uuid references auth.users(id),
  unread_count jsonb not null default '{}'::jsonb,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists idx_chats_participants_gin on public.chats using gin(participants);
create index if not exists idx_chats_updated on public.chats(updated_at desc);

create or replace function public.set_updated_at() returns trigger language plpgsql as $$ begin new.updated_at = now(); return new; end; $$;
drop trigger if exists trg_chats_updated_at on public.chats;
create trigger trg_chats_updated_at before update on public.chats for each row execute function public.set_updated_at();

-- MESSAGES -------------------------------------------------------------------
create table if not exists public.messages (
  id text primary key,
  chat_id text not null references public.chats(id) on delete cascade,
  sender_id uuid not null references auth.users(id) on delete cascade,
  content text not null,
  type text not null default 'text',
  metadata jsonb,
  is_read boolean not null default false,
  is_edited boolean not null default false,
  is_deleted boolean not null default false,
  created_at timestamptz not null default now()
);
create index if not exists idx_messages_chat_created on public.messages(chat_id, created_at desc);
create index if not exists idx_messages_sender on public.messages(sender_id);

-- SUPPORT REQUESTS -----------------------------------------------------------
create table if not exists public.support_requests (
  id bigserial primary key,
  user_id uuid references auth.users(id) on delete set null,
  name text,
  email text,
  category text,
  reason text,
  description text,
  status text not null default 'open',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists idx_support_requests_user on public.support_requests(user_id);
create index if not exists idx_support_requests_status on public.support_requests(status);

-- ADMIN ACTIONS --------------------------------------------------------------
create table if not exists public.admin_actions (
  id uuid primary key default gen_random_uuid(),
  admin_id uuid not null references auth.users(id) on delete set null,
  action_type text not null,
  target_user_id uuid references auth.users(id) on delete set null,
  metadata jsonb,
  created_at timestamptz not null default now()
);
create index if not exists idx_admin_actions_admin on public.admin_actions(admin_id);

-- Enable RLS -----------------------------------------------------------------
alter table if exists public.feature_credit_accounts enable row level security;
alter table if exists public.promotion_requests enable row level security;
alter table if exists public.comments enable row level security;
alter table if exists public.comment_likes enable row level security;
alter table if exists public.chats enable row level security;
alter table if exists public.messages enable row level security;
alter table if exists public.support_requests enable row level security;
alter table if exists public.admin_actions enable row level security;

-- FEATURE CREDIT ACCOUNTS RLS
drop policy if exists "Select own feature credits" on public.feature_credit_accounts;
drop policy if exists "Update own feature credits" on public.feature_credit_accounts;
drop policy if exists "Admin manage feature credits" on public.feature_credit_accounts;
create policy "Select own feature credits" on public.feature_credit_accounts for select using (user_id = auth.uid() or public.is_admin());
create policy "Update own feature credits" on public.feature_credit_accounts for update using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "Admin manage feature credits" on public.feature_credit_accounts for all using (public.is_admin()) with check (public.is_admin());
revoke all on public.feature_credit_accounts from public; grant select, update on public.feature_credit_accounts to authenticated;

-- PROMOTION REQUESTS RLS
drop policy if exists "Select own promotion requests" on public.promotion_requests;
drop policy if exists "Insert promotion request" on public.promotion_requests;
drop policy if exists "Admin manage promotion requests" on public.promotion_requests;
create policy "Select own promotion requests" on public.promotion_requests for select using (user_id = auth.uid() or public.is_admin());
create policy "Insert promotion request" on public.promotion_requests for insert with check (user_id = auth.uid());
create policy "Admin manage promotion requests" on public.promotion_requests for all using (public.is_admin()) with check (public.is_admin());
revoke all on public.promotion_requests from public; grant select, insert on public.promotion_requests to authenticated;

-- COMMENTS RLS
drop policy if exists "Select comments" on public.comments;
drop policy if exists "Insert own comment" on public.comments;
drop policy if exists "Delete own comment" on public.comments;
drop policy if exists "Admin manage comments" on public.comments;
create policy "Select comments" on public.comments for select using (true);
create policy "Insert own comment" on public.comments for insert with check (user_id = auth.uid());
create policy "Delete own comment" on public.comments for delete using (user_id = auth.uid());
create policy "Admin manage comments" on public.comments for all using (public.is_admin()) with check (public.is_admin());
revoke all on public.comments from public; grant select, insert, delete on public.comments to authenticated;

-- COMMENT LIKES RLS
drop policy if exists "Select own comment likes" on public.comment_likes;
drop policy if exists "Insert own comment like" on public.comment_likes;
drop policy if exists "Delete own comment like" on public.comment_likes;
drop policy if exists "Admin manage comment likes" on public.comment_likes;
create policy "Select own comment likes" on public.comment_likes for select using (user_id = auth.uid() or public.is_admin());
create policy "Insert own comment like" on public.comment_likes for insert with check (user_id = auth.uid());
create policy "Delete own comment like" on public.comment_likes for delete using (user_id = auth.uid());
create policy "Admin manage comment likes" on public.comment_likes for all using (public.is_admin()) with check (public.is_admin());
revoke all on public.comment_likes from public; grant select, insert, delete on public.comment_likes to authenticated;

-- CHATS RLS
drop policy if exists "Select own chats" on public.chats;
drop policy if exists "Insert own chat" on public.chats;
drop policy if exists "Update own chat" on public.chats;
drop policy if exists "Admin manage chats" on public.chats;
create policy "Select own chats" on public.chats for select using (auth.uid()::text = any(participants) or public.is_admin());
create policy "Insert own chat" on public.chats for insert with check (auth.uid()::text = any(participants));
create policy "Update own chat" on public.chats for update using (auth.uid()::text = any(participants)) with check (auth.uid()::text = any(participants));
create policy "Admin manage chats" on public.chats for all using (public.is_admin()) with check (public.is_admin());
revoke all on public.chats from public; grant select, insert, update on public.chats to authenticated;

-- MESSAGES RLS
drop policy if exists "Select own messages" on public.messages;
drop policy if exists "Insert own message" on public.messages;
drop policy if exists "Update own message" on public.messages;
drop policy if exists "Admin manage messages" on public.messages;
create policy "Select own messages" on public.messages for select using (
  exists (select 1 from public.chats c where c.id = messages.chat_id and (auth.uid()::text = any(c.participants) or public.is_admin()))
);
create policy "Insert own message" on public.messages for insert with check (
  sender_id = auth.uid() and exists (select 1 from public.chats c where c.id = messages.chat_id and auth.uid()::text = any(c.participants))
);
create policy "Update own message" on public.messages for update using (sender_id = auth.uid()) with check (sender_id = auth.uid());
create policy "Admin manage messages" on public.messages for all using (public.is_admin()) with check (public.is_admin());
revoke all on public.messages from public; grant select, insert, update on public.messages to authenticated;

-- SUPPORT REQUESTS RLS
drop policy if exists "Select own support requests" on public.support_requests;
drop policy if exists "Insert support request" on public.support_requests;
drop policy if exists "Admin manage support requests" on public.support_requests;
create policy "Select own support requests" on public.support_requests for select using (user_id = auth.uid() or public.is_admin());
create policy "Insert support request" on public.support_requests for insert with check (user_id = auth.uid());
create policy "Admin manage support requests" on public.support_requests for all using (public.is_admin()) with check (public.is_admin());
revoke all on public.support_requests from public; grant select, insert on public.support_requests to authenticated;

-- ADMIN ACTIONS RLS
drop policy if exists "Select own admin actions" on public.admin_actions;
drop policy if exists "Insert admin action" on public.admin_actions;
drop policy if exists "Admin manage admin actions" on public.admin_actions;
create policy "Select own admin actions" on public.admin_actions for select using (admin_id = auth.uid() or public.is_admin());
create policy "Insert admin action" on public.admin_actions for insert with check (admin_id = auth.uid() and public.is_admin());
create policy "Admin manage admin actions" on public.admin_actions for all using (public.is_admin()) with check (public.is_admin());
revoke all on public.admin_actions from public; grant select, insert on public.admin_actions to authenticated;

-- Harden grants --------------------------------------------------------------
revoke all on all tables in schema public from public;
revoke all on all sequences in schema public from public;
revoke all on all functions in schema public from public;

-- End -----------------------------------------------------------------------