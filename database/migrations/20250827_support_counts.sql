-- Create RPC to return support request counts by status (open/resolved)
-- Returns a JSON object: { "open": <int>, "resolved": <int> }
-- RLS respected (no security definer), so non-admins get counts for rows they can see.

create or replace function public.support_counts()
returns jsonb
language sql
stable
as $$
  with s as (
    select
      coalesce(count(*) filter (where status = 'open'), 0) as open,
      coalesce(count(*) filter (where status = 'resolved'), 0) as resolved
    from public.support_requests
  )
  select jsonb_build_object('open', s.open, 'resolved', s.resolved)
  from s;
$$;

comment on function public.support_counts() is 'Counts support_requests by status (open/resolved). Respects RLS.';

-- Optional: ensure index to keep counts fast
create index if not exists idx_support_requests_status on public.support_requests(status);

-- Allow typical roles to execute
grant execute on function public.support_counts() to anon, authenticated;
