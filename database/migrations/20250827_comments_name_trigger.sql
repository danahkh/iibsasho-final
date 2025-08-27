-- Ensure columns exist
alter table if exists public.comments
  add column if not exists user_name text,
  add column if not exists user_photo_url text;

create index if not exists idx_comments_user_name on public.comments (user_name);

-- Populate comments.user_name and user_photo_url from users at write time
-- Uses JSON accessors so it works even if some user columns are missing

create or replace function public.populate_comment_user_fields()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_name  text;
  v_photo text;
  v_email text;
begin
  select
    coalesce(
      to_jsonb(u)->>'display_name',
      to_jsonb(u)->>'name',
      to_jsonb(u)->>'full_name',
      to_jsonb(u)->>'username'
    ) as name,
    to_jsonb(u)->>'photo_url' as photo_url,
    coalesce(to_jsonb(u)->>'email', au.email) as email
  into v_name, v_photo, v_email
  from public.users u
  left join auth.users au on au.id = NEW.user_id
  where u.id = NEW.user_id;

  -- Only set/override when missing or placeholder
  if (NEW.user_name is null or NEW.user_name = '' or lower(NEW.user_name) = 'anonymous') then
    if (coalesce(v_name,'') <> '') then
      NEW.user_name := v_name;
    elsif (coalesce(v_email,'') <> '' and position('@' in v_email) > 0) then
      NEW.user_name := split_part(v_email, '@', 1);
    else
      NEW.user_name := 'Anonymous';
    end if;
  end if;

  if (NEW.user_photo_url is null or NEW.user_photo_url = '') then
    if (coalesce(v_photo,'') <> '') then
      NEW.user_photo_url := v_photo;
    end if;
  end if;

  return NEW;
end;
$$;

comment on function public.populate_comment_user_fields() is 'Trigger to fill comments.user_name and user_photo_url from users on insert/update.';

drop trigger if exists trg_comments_populate_user on public.comments;
create trigger trg_comments_populate_user
before insert or update of user_id on public.comments
for each row execute function public.populate_comment_user_fields();

-- Backfill existing rows that are empty or Anonymous
with src as (
  select
    u.id as user_id,
    coalesce(
      to_jsonb(u)->>'display_name',
      to_jsonb(u)->>'name',
      to_jsonb(u)->>'full_name',
      to_jsonb(u)->>'username'
    ) as name,
    to_jsonb(u)->>'email' as email,
    to_jsonb(u)->>'photo_url' as photo_url
  from public.users u
)
update public.comments c
set
  user_name = coalesce(src.name,
                       case when src.email is not null and position('@' in src.email) > 0
                            then split_part(src.email,'@',1)
                            else 'Anonymous' end),
  user_photo_url = coalesce(src.photo_url, c.user_photo_url)
from src
where c.user_id = src.user_id
  and (c.user_name is null or c.user_name = '' or lower(c.user_name) = 'anonymous');
