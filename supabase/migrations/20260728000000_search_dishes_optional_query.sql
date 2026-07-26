-- Ohne Sucheingabe soll man trotzdem etwas sehen: die bestbewerteten
-- Gerichte (global bzw. im gewählten Radius), statt eine leere Liste.
-- Beide RPCs behandeln eine leere/NULL search_query jetzt als "kein
-- Namensfilter" statt "kein Treffer".

create or replace function public.search_dishes(
    search_query text,
    user_lat double precision,
    user_lng double precision,
    radius_km double precision default 5
)
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
    rating_count bigint,
    distance_meters double precision
)
language sql
stable
as $$
    with user_point as (
        select st_setsrid(st_makepoint(user_lng, user_lat), 4326)::geography as geo
    ),
    matches as (
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
            dra.rating_count,
            st_distance(r.location, user_point.geo) as distance_meters
        from public.dishes d
        join public.restaurants r on r.id = d.restaurant_id
        join public.dish_ratings_avg dra on dra.dish_id = d.id
        cross join user_point
        where (btrim(coalesce(search_query, '')) = '' or d.name % search_query)
            and st_dwithin(r.location, user_point.geo, radius_km * 1000)
        order by r.id, similarity(d.name, coalesce(search_query, '')) desc, dra.avg_overall desc
    )
    select * from matches
    order by avg_overall desc, rating_count desc, distance_meters asc
$$;

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
        where btrim(coalesce(search_query, '')) = '' or d.name % search_query
        order by r.id, similarity(d.name, coalesce(search_query, '')) desc, dra.avg_overall desc
    )
    select * from matches
    order by avg_overall desc, rating_count desc
$$;
