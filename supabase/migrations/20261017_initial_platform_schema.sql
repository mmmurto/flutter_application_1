create extension if not exists pgcrypto;

do $$
begin
  create type public.user_role as enum (
    'platform_admin',
    'restaurant_owner',
    'restaurant_staff'
  );
exception
  when duplicate_object then null;
end $$;

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text,
  role public.user_role not null default 'restaurant_owner',
  created_at timestamptz not null default now()
);

create table public.restaurants (
  id uuid primary key default gen_random_uuid (),
  owner_id uuid references public.profiles (id) on delete set null,
  name text not null,
  slug text not null unique,
  description text,
  address text,
  latitude numeric,
  longitude numeric,
  phone text,
  cover_image_url text,
  logo_image_url text,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.restaurant_staff (
  restaurant_id uuid not null references public.restaurants (id) on delete cascade,
  profile_id uuid not null references public.profiles (id) on delete cascade,
  role public.user_role not null default 'restaurant_staff',
  created_at timestamptz not null default now(),
  primary key (restaurant_id, profile_id)
);

create table public.restaurant_tables (
  id uuid primary key default gen_random_uuid (),
  restaurant_id uuid not null references public.restaurants (id) on delete cascade,
  label text not null,
  qr_token uuid not null unique default gen_random_uuid (),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  unique (restaurant_id, label)
);

create table public.menu_categories (
  id uuid primary key default gen_random_uuid (),
  restaurant_id uuid not null references public.restaurants (id) on delete cascade,
  name text not null,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.menu_items (
  id uuid primary key default gen_random_uuid (),
  restaurant_id uuid not null references public.restaurants (id) on delete cascade,
  category_id uuid references public.menu_categories (id) on delete set null,
  name text not null,
  description text,
  price numeric(10, 2) not null check (price >= 0),
  image_url text,
  is_vegetarian boolean not null default false,
  is_spicy boolean not null default false,
  is_available boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table public.orders (
  id uuid primary key default gen_random_uuid (),
  order_code text not null unique default upper(
    substring(
      replace(gen_random_uuid ()::text, '-', '')
      from
        1 for 8
    )
  ),
  restaurant_id uuid not null references public.restaurants (id) on delete restrict,
  table_id uuid references public.restaurant_tables (id) on delete set null,
  status text not null default 'new' check (
    status in (
      'new',
      'preparing',
      'ready',
      'served',
      'cancelled'
    )
  ),
  total_amount numeric(10, 2) not null default 0 check (total_amount >= 0),
  currency char(3) not null default 'AZN',
  customer_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.order_items (
  id uuid primary key default gen_random_uuid (),
  order_id uuid not null references public.orders (id) on delete cascade,
  menu_item_id uuid references public.menu_items (id) on delete set null,
  item_name text not null,
  unit_price numeric(10, 2) not null check (unit_price >= 0),
  quantity integer not null check (quantity > 0),
  created_at timestamptz not null default now()
);

create index restaurants_owner_id_idx on public.restaurants (owner_id);

create index restaurant_tables_restaurant_id_idx on public.restaurant_tables (restaurant_id);

create index menu_categories_restaurant_id_idx on public.menu_categories (restaurant_id);

create index menu_items_restaurant_id_idx on public.menu_items (restaurant_id);

create index menu_items_category_id_idx on public.menu_items (category_id);

create index orders_restaurant_id_idx on public.orders (restaurant_id);

create index orders_table_id_idx on public.orders (table_id);

create index orders_status_idx on public.orders (status);

create index order_items_order_id_idx on public.order_items (order_id);

alter table public.profiles enable row level security;

alter table public.restaurants enable row level security;

alter table public.restaurant_staff enable row level security;

alter table public.restaurant_tables enable row level security;

alter table public.menu_categories enable row level security;

alter table public.menu_items enable row level security;

alter table public.orders enable row level security;

alter table public.order_items enable row level security;