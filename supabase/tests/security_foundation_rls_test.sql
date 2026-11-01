begin;

create extension if not exists pgtap with schema extensions;

select plan(22);

insert into auth.users (id, email)
values
  ('00000000-0000-0000-0000-000000000001', 'owner@test.invalid'),
  ('00000000-0000-0000-0000-000000000002', 'kitchen@test.invalid'),
  ('00000000-0000-0000-0000-000000000003', 'outsider@test.invalid'),
  ('00000000-0000-0000-0000-000000000004', 'admin@test.invalid');

update public.profiles
set platform_role = 'platform_admin'
where id = '00000000-0000-0000-0000-000000000004';

insert into public.restaurants (
  id,
  name,
  slug,
  publication_status
)
values
  (
    '10000000-0000-0000-0000-000000000001',
    'Published RLS Fixture',
    'published-rls-fixture',
    'published'
  ),
  (
    '10000000-0000-0000-0000-000000000002',
    'Owner Draft RLS Fixture',
    'owner-draft-rls-fixture',
    'draft'
  ),
  (
    '10000000-0000-0000-0000-000000000003',
    'Kitchen Draft RLS Fixture',
    'kitchen-draft-rls-fixture',
    'draft'
  );

insert into public.restaurant_memberships (
  restaurant_id,
  profile_id,
  role
)
values
  (
    '10000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000001',
    'owner'
  ),
  (
    '10000000-0000-0000-0000-000000000002',
    '00000000-0000-0000-0000-000000000001',
    'owner'
  ),
  (
    '10000000-0000-0000-0000-000000000003',
    '00000000-0000-0000-0000-000000000002',
    'kitchen'
  );

insert into public.restaurant_tables (id, restaurant_id, label)
values
  (
    '20000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000001',
    'RLS-1'
  ),
  (
    '20000000-0000-0000-0000-000000000002',
    '10000000-0000-0000-0000-000000000002',
    'RLS-2'
  ),
  (
    '20000000-0000-0000-0000-000000000003',
    '10000000-0000-0000-0000-000000000003',
    'RLS-3'
  );

insert into public.menu_categories (id, restaurant_id, name, is_active)
values
  (
    '30000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000001',
    'Published Fixture Category',
    true
  ),
  (
    '30000000-0000-0000-0000-000000000002',
    '10000000-0000-0000-0000-000000000002',
    'Draft Fixture Category',
    true
  );

insert into public.menu_items (
  id,
  restaurant_id,
  category_id,
  name,
  price,
  is_available
)
values
  (
    '40000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000001',
    '30000000-0000-0000-0000-000000000001',
    'Published Fixture Item',
    1,
    true
  ),
  (
    '40000000-0000-0000-0000-000000000002',
    '10000000-0000-0000-0000-000000000001',
    '30000000-0000-0000-0000-000000000001',
    'Unavailable Fixture Item',
    1,
    false
  ),
  (
    '40000000-0000-0000-0000-000000000003',
    '10000000-0000-0000-0000-000000000002',
    '30000000-0000-0000-0000-000000000002',
    'Draft Fixture Item',
    1,
    true
  );

insert into public.orders (
  id,
  order_code,
  restaurant_id,
  table_id,
  total_amount
)
values
  (
    '50000000-0000-0000-0000-000000000001',
    'RLS00001',
    '10000000-0000-0000-0000-000000000002',
    '20000000-0000-0000-0000-000000000002',
    1
  ),
  (
    '50000000-0000-0000-0000-000000000002',
    'RLS00002',
    '10000000-0000-0000-0000-000000000003',
    '20000000-0000-0000-0000-000000000003',
    1
  );

insert into public.order_items (
  id,
  order_id,
  item_name,
  unit_price,
  quantity
)
values
  (
    '60000000-0000-0000-0000-000000000001',
    '50000000-0000-0000-0000-000000000001',
    'Order Fixture Item',
    1,
    1
  ),
  (
    '60000000-0000-0000-0000-000000000002',
    '50000000-0000-0000-0000-000000000002',
    'Other Order Fixture Item',
    1,
    1
  );

select results_eq(
  $$
    select count(*)
    from public.profiles
    where platform_role = 'customer'
      and id in (
        '00000000-0000-0000-0000-000000000001',
        '00000000-0000-0000-0000-000000000002',
        '00000000-0000-0000-0000-000000000003'
      )
  $$,
  array[3::bigint],
  'new accounts receive customer profiles'
);

set local role anon;

select results_eq(
  'select count(*) from public.restaurants',
  array[1::bigint],
  'anonymous users see only published restaurants'
);

select results_eq(
  'select count(*) from public.menu_categories',
  array[1::bigint],
  'anonymous users see categories only for published restaurants'
);

select results_eq(
  'select count(*) from public.menu_items',
  array[1::bigint],
  'anonymous users see only available items for published restaurants'
);

select throws_ok(
  'select * from public.restaurant_tables',
  '42501',
  null,
  'anonymous users cannot read table QR records'
);

select throws_ok(
  'select * from public.orders',
  '42501',
  null,
  'anonymous users cannot read orders'
);

set local role authenticated;
set local request.jwt.claim.sub = '00000000-0000-0000-0000-000000000001';

select results_eq(
  'select count(*) from public.restaurants',
  array[2::bigint],
  'an owner sees published restaurants and their own draft restaurant'
);

select results_eq(
  'select count(*) from public.restaurant_memberships',
  array[2::bigint],
  'an owner sees memberships for restaurants they manage'
);

select results_eq(
  'select count(*) from public.restaurant_tables',
  array[2::bigint],
  'an owner sees tables only for their restaurants'
);

select results_eq(
  'select count(*) from public.orders',
  array[1::bigint],
  'an owner sees orders only for their restaurants'
);

select results_eq(
  'select count(*) from public.order_items',
  array[1::bigint],
  'an owner sees order items only for their restaurants'
);

select results_eq(
  $$
    update public.profiles
    set full_name = 'Updated Test Name'
    where id = '00000000-0000-0000-0000-000000000001'
    returning full_name
  $$,
  array['Updated Test Name'::text],
  'a user can update their own display name'
);

select throws_ok(
  $$
    update public.profiles
    set platform_role = 'platform_admin'
    where id = '00000000-0000-0000-0000-000000000001'
  $$,
  '42501',
  null,
  'a user cannot promote their platform role'
);

select throws_ok(
  $$
    update public.menu_items
    set price = 0
    where id = '40000000-0000-0000-0000-000000000001'
  $$,
  '42501',
  null,
  'a restaurant member cannot directly change an authoritative price'
);

select throws_ok(
  $$
    insert into public.orders (restaurant_id, total_amount)
    values ('10000000-0000-0000-0000-000000000001', 0)
  $$,
  '42501',
  null,
  'a client cannot directly create an order'
);

set local request.jwt.claim.sub = '00000000-0000-0000-0000-000000000003';

select results_eq(
  'select count(*) from public.restaurants',
  array[1::bigint],
  'an outsider sees only published restaurants'
);

select results_eq(
  'select count(*) from public.restaurant_memberships',
  array[0::bigint],
  'an outsider cannot read restaurant memberships'
);

select results_eq(
  'select count(*) from public.restaurant_tables',
  array[0::bigint],
  'an outsider cannot read table QR records'
);

select results_eq(
  'select count(*) from public.orders',
  array[0::bigint],
  'an outsider cannot read orders'
);

set local request.jwt.claim.sub = '00000000-0000-0000-0000-000000000002';

select results_eq(
  'select count(*) from public.restaurant_tables',
  array[1::bigint],
  'kitchen staff see tables only for their restaurant'
);

select results_eq(
  'select count(*) from public.orders',
  array[1::bigint],
  'kitchen staff see orders only for their restaurant'
);

set local request.jwt.claim.sub = '00000000-0000-0000-0000-000000000004';

select results_eq(
  'select count(*) from public.restaurants',
  array[3::bigint],
  'a platform administrator can review every restaurant'
);

select * from finish();

rollback;
