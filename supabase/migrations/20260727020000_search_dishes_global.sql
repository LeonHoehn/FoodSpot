-- Phase "Global/Umgebung": globale Gerichtsuche ohne jede Geo-Einschränkung,
-- als Gegenstück zu search_dishes (das immer einen Radius verlangt).

create or replace function public.search_dishes_global(search_query text)
returns table (
    restaurant_id uuid,
    restaurant_name text,
    restaurant_address text,
    restaurant_lat double precision,
    restaurant_lng double precision,
    dish_id uuid,
    dish_name text,
    avg_taste numeric,
    avg_texture numeric,
    avg_appearance numeric,
    avg_smell numeric,
    avg_overall numeric,
    rating_count bigint
)
language sql
stable
as $$
    with matches as (
        select distinct on (r.id)
            r.id as restaurant_id,
            r.name as restaurant_name,
            r.address as restaurant_address,
            r.lat as restaurant_lat,
            r.lng as restaurant_lng,
            d.id as dish_id,
            d.name as dish_name,
            dra.avg_taste,
            dra.avg_texture,
            dra.avg_appearance,
            dra.avg_smell,
            dra.avg_overall,
            dra.rating_count
        from public.dishes d
        join public.restaurants r on r.id = d.restaurant_id
        join public.dish_ratings_avg dra on dra.dish_id = d.id
        where d.name % search_query
        order by r.id, similarity(d.name, search_query) desc, dra.avg_overall desc
    )
    select * from matches
    order by avg_overall desc, rating_count desc
$$;

grant execute on function public.search_dishes_global(text) to anon, authenticated;
