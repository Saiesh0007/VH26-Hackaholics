create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null,
  email text not null unique,
  role text not null default 'customer' check (role in ('customer', 'admin')),
  created_at timestamptz not null default now()
);
create or replace function public.handle_new_user() returns trigger language plpgsql security definer
set search_path = public as $$ begin
insert into public.profiles (id, name, email, role)
values (
    new.id,
    coalesce(
      new.raw_user_meta_data->>'name',
      split_part(new.email, '@', 1)
    ),
    new.email,
    'customer'
  );
return new;
end;
$$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after
insert on auth.users for each row execute procedure public.handle_new_user();
create table if not exists public.products (
  id text primary key,
  name text not null,
  category text not null,
  price numeric(10, 2) not null,
  stock integer not null default 0,
  rating numeric(2, 1) not null default 0,
  color text not null,
  tag text not null,
  created_at timestamptz not null default now()
);
create table if not exists public.orders (
  id text primary key,
  user_id uuid not null references public.profiles(id) on delete cascade,
  items jsonb not null,
  total numeric(10, 2) not null,
  status text not null default 'Processing',
  shipping_address text not null,
  created_at timestamptz not null default now()
);
create table if not exists public.pipeline_events (
  id text primary key,
  type text not null,
  priority text not null,
  decision text not null,
  queue text not null,
  pressure numeric not null default 0,
  worker numeric not null default 0,
  reason text not null,
  created_at timestamptz not null default now()
);
alter table public.profiles enable row level security;
alter table public.products enable row level security;
alter table public.orders enable row level security;
alter table public.pipeline_events enable row level security;
drop policy if exists "profiles own row" on public.profiles;
drop policy if exists "products readable by authenticated users" on public.products;
drop policy if exists "orders own rows" on public.orders;
drop policy if exists "pipeline events admin readable" on public.pipeline_events;
create policy "profiles own row" on public.profiles for
select using (auth.uid() = id);
create policy "products readable by authenticated users" on public.products for
select using (auth.role() = 'authenticated');
create policy "orders own rows" on public.orders for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "pipeline events admin readable" on public.pipeline_events for
select using (
    exists (
      select 1
      from public.profiles
      where id = auth.uid()
        and role = 'admin'
    )
  );
insert into public.products (
    id,
    name,
    category,
    price,
    stock,
    rating,
    color,
    tag
  )
values (
    'p1',
    'AeroFlex Runner',
    'Footwear',
    129,
    248,
    4.8,
    '#dff2ef',
    'Fast mover'
  ),
  (
    'p2',
    'Orbit Sound Pro',
    'Electronics',
    249,
    84,
    4.7,
    '#e8eef9',
    'New arrival'
  ),
  (
    'p3',
    'Daybreak Carryall',
    'Accessories',
    98,
    132,
    4.6,
    '#f6eadb',
    'Staff pick'
  ),
  (
    'p4',
    'Terra Knit Set',
    'Apparel',
    149,
    61,
    4.9,
    '#e9e5f5',
    'Limited'
  ),
  (
    'p5',
    'Pulse Smartwatch',
    'Electronics',
    199,
    39,
    4.5,
    '#dfeaf3',
    'Trending'
  ),
  (
    'p6',
    'Cloud Lounge Chair',
    'Home',
    329,
    17,
    4.8,
    '#f0e8df',
    'Premium'
  ),
  (
    'p7',
    'Northstar Backpack',
    'Accessories',
    118,
    96,
    4.7,
    '#e4f0ed',
    'Best seller'
  ),
  (
    'p8',
    'Ember Desk Lamp',
    'Home',
    74,
    143,
    4.4,
    '#f8e9d9',
    'New arrival'
  ),
  (
    'p9',
    'Drift Linen Shirt',
    'Apparel',
    89,
    73,
    4.6,
    '#edf1e5',
    'Staff pick'
  ),
  (
    'p10',
    'Cinder Mechanical Keyboard',
    'Electronics',
    159,
    42,
    4.8,
    '#e5e9f2',
    'Trending'
  ),
  (
    'p11',
    'Solstice Water Bottle',
    'Accessories',
    36,
    211,
    4.5,
    '#e0edf4',
    'Fast mover'
  ),
  (
    'p12',
    'Field Notes Travel Journal',
    'Stationery',
    28,
    187,
    4.9,
    '#f3e8df',
    'Limited'
  ) on conflict (id) do nothing;