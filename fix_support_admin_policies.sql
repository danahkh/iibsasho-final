-- Align admin detection and support_requests status values
-- Safe to run multiple times

-- Create is_admin() that checks users.role, users.is_admin, and profiles.is_admin if present
create or replace function public.is_admin() returns boolean language plpgsql stable as $$
declare v boolean := false; begin
  begin
    select coalesce(u.role = 'admin', false) or coalesce(u.is_admin, false)
    into v
    from public.users u
    where u.id = auth.uid();
  exception when others then v := false; end;

  if not v then
    begin
      perform 1 from information_schema.tables where table_schema='public' and table_name='profiles';
      if found then
        select coalesce(p.is_admin,false) into v from public.profiles p where p.id = auth.uid();
      end if;
    exception when others then v := v; end;
  end if;
  return v;
end; $$;
grant execute on function public.is_admin() to authenticated;

-- Ensure support_requests.status allows 'open' and 'resolved'
do $$
declare has_constraint boolean;
begin
  select exists (
    select 1 from information_schema.constraint_column_usage c
    join information_schema.table_constraints t on t.constraint_name=c.constraint_name
    where c.table_schema='public' and c.table_name='support_requests' and c.column_name='status'
  ) into has_constraint;

  if has_constraint then
    -- Try to relax to simple check: status in ('open','resolved')
    begin
      alter table public.support_requests drop constraint if exists support_requests_status_check;
    exception when others then null; end;
  end if;

  begin
    alter table public.support_requests add constraint support_requests_status_check
      check (status in ('open','resolved'));
  exception when others then null; end;
end $$;

-- Recreate RLS policies to include admin via is_admin()
alter table public.support_requests enable row level security;
drop policy if exists "Select own support requests" on public.support_requests;
drop policy if exists "Insert support request" on public.support_requests;
drop policy if exists "Admin manage support requests" on public.support_requests;
create policy "Select own support requests" on public.support_requests for select using (user_id = auth.uid() or public.is_admin());
create policy "Insert support request" on public.support_requests for insert with check (user_id = auth.uid());
create policy "Admin manage support requests" on public.support_requests for all using (public.is_admin()) with check (public.is_admin());
grant select, insert, update on public.support_requests to authenticated;
