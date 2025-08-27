-- Increment view_count for a listing atomically and safely via RPC
create or replace function public.increment_listing_view(p_listing_id uuid)
returns void
language sql
security definer
set search_path = public
as $$
  update public.listings
  set view_count = coalesce(view_count, 0) + 1
  where id = p_listing_id;
$$;

comment on function public.increment_listing_view(uuid) is 'RPC: increments listings.view_count by 1 for the given listing id';

grant execute on function public.increment_listing_view(uuid) to anon, authenticated;
