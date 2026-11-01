-- Production security foundation.
--
-- This migration deliberately does not permit client-side writes to restaurants,
-- menus, tables, memberships, or orders. Those operations will be exposed later
-- through reviewed server-side functions with validation and audit logging.

create schema if not exists private;
revoke all on schema private from public, anon, authenticated;
grant usage on schema private to authenticated;

-- New database objects must start closed and receive explicit grants in the
-- migration that creates them.
alter default privileges in schema public
  revoke all on tables from anon, authenticated;
alter default privileges in schema public
  revoke execute on functions from public, anon, authenticated;
alter default privileges in schema private
  revoke execute on functions from public, anon, authenticated;

do $$
begin
  create type public.platform_role as enum ('customer', 'platform_admin');
exception
  when duplicate_object then null;
end $$;

do $$
begin
  create type public.restaurant_member_role as enum (
    'owner',
    'manager',
    'kitchen',
    'cashier',
    'server'
  );
exception
  when duplicate_object then null;
end $$;

do $$
begin
  create type public.restaurant_publication_status as enum (
    'draft',
    'pending_review',
    'published',
    'suspended'
  );
exception
  when duplicate_object then null;
end $$;

-- Platform permissions and restaurant permissions are intentionally separate.
alter table public.profiles
  add column platform_role public.platform_role not null default 'customer',
  add column updated_at timestamptz not null default now();

update public.profiles
set platform_role = 'platform_admin'
where role = 'platform_admin';

alter table public.restaurant_staff
  alter column role drop default;

alter table public.restaurant_staff
  alter column role type public.restaurant_member_role
  using (
    case role::text
      when 'restaurant_owner' then 'owner'
      else 'server'
    end
  )::public.restaurant_member_role;

alter table public.restaurant_staff
  add column is_active boolean not null default true,
  add column updated_at timestamptz not null default now();

-- Preserve any existing owners as explicit restaurant memberships before the
-- old denormalized owner column is removed.
insert into public.restaurant_staff (restaurant_id, profile_id, role)
select id, owner_id, 'owner'::public.restaurant_member_role
from public.restaurants
where owner_id is not null
on conflict (restaurant_id, profile_id)
do update set role = 'owner'::public.restaurant_member_role, is_active = true;

drop index if exists public.restaurants_owner_id_idx;

alter table public.restaurants
  drop column owner_id,
  add column publication_status public.restaurant_publication_status not null default 'draft',
  add column updated_at timestamptz not null default now();

alter table public.profiles drop column role;

drop type public.user_role;

alter table public.restaurant_staff rename to restaurant_memberships;

comment on table public.restaurant_memberships is
  'Restaurant-scoped authorization. Platform roles are stored separately on profiles.';
comment on column public.restaurants.publication_status is
  'Only platform-reviewed published restaurants are visible to the public.';

create index restaurant_memberships_profile_id_idx
  on public.restaurant_memberships (profile_id)
  where is_active;

create index restaurants_publication_status_idx
  on public.restaurants (publication_status)
  where is_active;

-- Ensure every Supabase Auth user receives a least-privilege customer profile.
create or replace function private.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, full_name)
  values (
    new.id,
    nullif(btrim(new.raw_user_meta_data ->> 'full_name'), '')
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function private.handle_new_user();

insert into public.profiles (id, full_name)
select
  users.id,
  nullif(btrim(users.raw_user_meta_data ->> 'full_name'), '')
from auth.users as users
on conflict (id) do nothing;

-- Security-definer helpers centralize tenant checks and bypass policy recursion.
create or replace function private.is_platform_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.profiles
    where id = (select auth.uid())
      and platform_role = 'platform_admin'
  );
$$;

create or replace function private.is_restaurant_member(target_restaurant_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.restaurant_memberships
    where restaurant_id = target_restaurant_id
      and profile_id = (select auth.uid())
      and is_active
  );
$$;

create or replace function private.can_manage_restaurant(target_restaurant_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.restaurant_memberships
    where restaurant_id = target_restaurant_id
      and profile_id = (select auth.uid())
      and is_active
      and role in ('owner', 'manager')
  );
$$;

revoke all on function private.handle_new_user() from public, anon, authenticated;
revoke all on function private.is_platform_admin() from public, anon, authenticated;
revoke all on function private.is_restaurant_member(uuid) from public, anon, authenticated;
revoke all on function private.can_manage_restaurant(uuid) from public, anon, authenticated;

grant execute on function private.is_platform_admin() to authenticated;
grant execute on function private.is_restaurant_member(uuid) to authenticated;
grant execute on function private.can_manage_restaurant(uuid) to authenticated;

-- Maintain reliable modification timestamps on server-controlled records.
create or replace function private.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function private.set_updated_at();

drop trigger if exists restaurants_set_updated_at on public.restaurants;
create trigger restaurants_set_updated_at
before update on public.restaurants
for each row execute function private.set_updated_at();

drop trigger if exists restaurant_memberships_set_updated_at
  on public.restaurant_memberships;
create trigger restaurant_memberships_set_updated_at
before update on public.restaurant_memberships
for each row execute function private.set_updated_at();

drop trigger if exists orders_set_updated_at on public.orders;
create trigger orders_set_updated_at
before update on public.orders
for each row execute function private.set_updated_at();

revoke all on function private.set_updated_at() from public, anon, authenticated;

-- Remove broad client grants. The service role remains unaffected.
revoke all on table public.profiles from anon, authenticated;
revoke all on table public.restaurants from anon, authenticated;
revoke all on table public.restaurant_memberships from anon, authenticated;
revoke all on table public.restaurant_tables from anon, authenticated;
revoke all on table public.menu_categories from anon, authenticated;
revoke all on table public.menu_items from anon, authenticated;
revoke all on table public.orders from anon, authenticated;
revoke all on table public.order_items from anon, authenticated;

grant select on table public.restaurants to anon, authenticated;
grant select on table public.menu_categories to anon, authenticated;
grant select on table public.menu_items to anon, authenticated;

grant select on table public.profiles to authenticated;
grant update (full_name) on table public.profiles to authenticated;
grant select on table public.restaurant_memberships to authenticated;
grant select on table public.restaurant_tables to authenticated;
grant select on table public.orders to authenticated;
grant select on table public.order_items to authenticated;

-- Re-create every policy explicitly so this migration remains reviewable.
drop policy if exists profiles_select_own on public.profiles;
create policy profiles_select_own
on public.profiles
for select
to authenticated
using (id = (select auth.uid()));

drop policy if exists profiles_select_platform_admin on public.profiles;
create policy profiles_select_platform_admin
on public.profiles
for select
to authenticated
using ((select private.is_platform_admin()));

drop policy if exists profiles_update_own_name on public.profiles;
create policy profiles_update_own_name
on public.profiles
for update
to authenticated
using (id = (select auth.uid()))
with check (id = (select auth.uid()));

drop policy if exists restaurants_select_published on public.restaurants;
create policy restaurants_select_published
on public.restaurants
for select
to anon, authenticated
using (is_active and publication_status = 'published');

drop policy if exists restaurants_select_membership on public.restaurants;
create policy restaurants_select_membership
on public.restaurants
for select
to authenticated
using (
  (select private.is_restaurant_member(id))
  or (select private.is_platform_admin())
);

drop policy if exists restaurant_memberships_select_own on public.restaurant_memberships;
create policy restaurant_memberships_select_own
on public.restaurant_memberships
for select
to authenticated
using (profile_id = (select auth.uid()));

drop policy if exists restaurant_memberships_select_managers
  on public.restaurant_memberships;
create policy restaurant_memberships_select_managers
on public.restaurant_memberships
for select
to authenticated
using (
  (select private.can_manage_restaurant(restaurant_id))
  or (select private.is_platform_admin())
);

drop policy if exists restaurant_tables_select_membership
  on public.restaurant_tables;
create policy restaurant_tables_select_membership
on public.restaurant_tables
for select
to authenticated
using (
  (select private.is_restaurant_member(restaurant_id))
  or (select private.is_platform_admin())
);

drop policy if exists menu_categories_select_published
  on public.menu_categories;
create policy menu_categories_select_published
on public.menu_categories
for select
to anon, authenticated
using (
  is_active
  and exists (
    select 1
    from public.restaurants
    where restaurants.id = menu_categories.restaurant_id
      and restaurants.is_active
      and restaurants.publication_status = 'published'
  )
);

drop policy if exists menu_categories_select_membership
  on public.menu_categories;
create policy menu_categories_select_membership
on public.menu_categories
for select
to authenticated
using (
  (select private.is_restaurant_member(restaurant_id))
  or (select private.is_platform_admin())
);

drop policy if exists menu_items_select_published on public.menu_items;
create policy menu_items_select_published
on public.menu_items
for select
to anon, authenticated
using (
  is_available
  and exists (
    select 1
    from public.restaurants
    where restaurants.id = menu_items.restaurant_id
      and restaurants.is_active
      and restaurants.publication_status = 'published'
  )
);

drop policy if exists menu_items_select_membership on public.menu_items;
create policy menu_items_select_membership
on public.menu_items
for select
to authenticated
using (
  (select private.is_restaurant_member(restaurant_id))
  or (select private.is_platform_admin())
);

drop policy if exists orders_select_membership on public.orders;
create policy orders_select_membership
on public.orders
for select
to authenticated
using (
  (select private.is_restaurant_member(restaurant_id))
  or (select private.is_platform_admin())
);

drop policy if exists order_items_select_membership on public.order_items;
create policy order_items_select_membership
on public.order_items
for select
to authenticated
using (
  exists (
    select 1
    from public.orders
    where orders.id = order_items.order_id
      and (
        (select private.is_restaurant_member(orders.restaurant_id))
        or (select private.is_platform_admin())
      )
  )
);

