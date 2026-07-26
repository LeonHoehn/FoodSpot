-- Phase 4: Gerichtsuche mit Fuzzy-Match (pg_trgm) + Geo-Radius (PostGIS)
--
-- Liefert pro Restaurant das best passende Gericht zur Suchanfrage
-- (Ähnlichkeit + Bewertung), eingeschränkt auf einen Radius um den Nutzer,
-- sortiert nach Durchschnittsbewertung des jeweiligen Gerichts. Restaurants
-- ohne Bewertung für ein passendes Gericht tauchen nicht auf (inner join
-- auf dish_ratings_avg).

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
        where d.name % search_query
            and st_dwithin(r.location, user_point.geo, radius_km * 1000)
        order by r.id, similarity(d.name, search_query) desc, dra.avg_overall desc
    )
    select * from matches
    order by avg_overall desc, rating_count desc, distance_meters asc
$$;

grant execute on function public.search_dishes(text, double precision, double precision, double precision)
    to anon, authenticated;
