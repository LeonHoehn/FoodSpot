-- Merkliste: Restaurants, die sich ein Nutzer unabhängig von eigenen
-- Bewertungen vormerken kann. Anders als restaurants/dishes/ratings sind
-- Bookmarks privat - nur der eigene Nutzer darf sie lesen/schreiben.

create table if not exists public.bookmarks (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    restaurant_id uuid not null references public.restaurants(id) on delete cascade,
    created_at timestamptz not null default now(),
    unique (user_id, restaurant_id)
);

create index if not exists bookmarks_user_id_idx on public.bookmarks(user_id);

alter table public.bookmarks enable row level security;

create policy "bookmarks_select_own"
    on public.bookmarks for select
    to authenticated
    using (auth.uid() = user_id);

create policy "bookmarks_insert_own"
    on public.bookmarks for insert
    to authenticated
    with check (auth.uid() = user_id);

create policy "bookmarks_delete_own"
    on public.bookmarks for delete
    to authenticated
    using (auth.uid() = user_id);
