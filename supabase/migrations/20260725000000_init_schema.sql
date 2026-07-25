-- FoodSpot initial schema
-- Phase 1: restaurants, dishes, ratings + PostGIS + pg_trgm + RLS

create extension if not exists postgis;
create extension if not exists pg_trgm;

-- ---------------------------------------------------------------------------
-- restaurants
-- Reference copy of Apple MapKit POIs. Created lazily on first search hit.
-- ---------------------------------------------------------------------------
create table if not exists public.restaurants (
    id uuid primary key default gen_random_uuid(),
    apple_maps_id text unique,
    name text not null,
    lat double precision not null,
    lng double precision not null,
    address text,
    location geography(point, 4326) generated always as (
        st_setsrid(st_makepoint(lng, lat), 4326)::geography
    ) stored,
    created_at timestamptz not null default now()
);

create index if not exists restaurants_location_idx
    on public.restaurants using gist (location);

-- ---------------------------------------------------------------------------
-- dishes
-- No external source of truth: rows are created by users while rating.
-- ---------------------------------------------------------------------------
create table if not exists public.dishes (
    id uuid primary key default gen_random_uuid(),
    name text not null,
    restaurant_id uuid not null references public.restaurants(id) on delete cascade,
    created_at timestamptz not null default now(),
    unique (restaurant_id, name)
);

create index if not exists dishes_restaurant_id_idx on public.dishes(restaurant_id);
-- Fuzzy search on dish name (typos, Döner/Kebab/Dürüm-style variants)
create index if not exists dishes_name_trgm_idx
    on public.dishes using gin (name gin_trgm_ops);

-- ---------------------------------------------------------------------------
-- ratings
-- Two separate rating blocks per row: dish (taste/texture/appearance/smell)
-- and restaurant (service/ambience/value/wait_time). 0-5, half stars allowed.
-- One rating per user per dish.
-- ---------------------------------------------------------------------------
create table if not exists public.ratings (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    dish_id uuid not null references public.dishes(id) on delete cascade,
    restaurant_id uuid not null references public.restaurants(id) on delete cascade,

    -- Gericht-Block
    taste numeric(2,1) not null check (taste between 0 and 5),
    texture numeric(2,1) not null check (texture between 0 and 5),
    appearance numeric(2,1) not null check (appearance between 0 and 5),
    smell numeric(2,1) not null check (smell between 0 and 5),

    -- Restaurant-Block
    service numeric(2,1) not null check (service between 0 and 5),
    ambience numeric(2,1) not null check (ambience between 0 and 5),
    value numeric(2,1) not null check (value between 0 and 5),
    wait_time numeric(2,1) not null check (wait_time between 0 and 5),

    created_at timestamptz not null default now(),
    unique (user_id, dish_id)
);

create index if not exists ratings_dish_id_idx on public.ratings(dish_id);
create index if not exists ratings_restaurant_id_idx on public.ratings(restaurant_id);
create index if not exists ratings_user_id_idx on public.ratings(user_id);

-- ---------------------------------------------------------------------------
-- Aggregate views: per-dish and per-restaurant averages, computed in SQL,
-- not in the client.
-- ---------------------------------------------------------------------------
create or replace view public.dish_ratings_avg as
select
    dish_id,
    avg(taste) as avg_taste,
    avg(texture) as avg_texture,
    avg(appearance) as avg_appearance,
    avg(smell) as avg_smell,
    avg((taste + texture + appearance + smell) / 4.0) as avg_overall,
    count(*) as rating_count
from public.ratings
group by dish_id;

create or replace view public.restaurant_ratings_avg as
select
    restaurant_id,
    avg(service) as avg_service,
    avg(ambience) as avg_ambience,
    avg(value) as avg_value,
    avg(wait_time) as avg_wait_time,
    avg((service + ambience + value + wait_time) / 4.0) as avg_overall,
    count(*) as rating_count
from public.ratings
group by restaurant_id;

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------
alter table public.restaurants enable row level security;
alter table public.dishes enable row level security;
alter table public.ratings enable row level security;

-- restaurants: world-readable (map pins, search), created by any signed-in
-- user on first MapKit hit.
create policy "restaurants_select_all"
    on public.restaurants for select
    using (true);

create policy "restaurants_insert_authenticated"
    on public.restaurants for insert
    to authenticated
    with check (true);

-- dishes: world-readable, created by any signed-in user while rating.
create policy "dishes_select_all"
    on public.dishes for select
    using (true);

create policy "dishes_insert_authenticated"
    on public.dishes for insert
    to authenticated
    with check (true);

-- ratings: world-readable (needed to compute averages client-side/via views),
-- but a user may only write/change/delete their own rating.
create policy "ratings_select_all"
    on public.ratings for select
    using (true);

create policy "ratings_insert_own"
    on public.ratings for insert
    to authenticated
    with check (auth.uid() = user_id);

create policy "ratings_update_own"
    on public.ratings for update
    to authenticated
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);

create policy "ratings_delete_own"
    on public.ratings for delete
    to authenticated
    using (auth.uid() = user_id);
