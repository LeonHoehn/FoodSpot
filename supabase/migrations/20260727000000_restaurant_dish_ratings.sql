-- Phase 6: View für die Anzeige aller bewerteten Gerichte eines Restaurants
-- inkl. ihrer Gericht-Block-Durchschnitte (für das Restaurant-Detail-Sheet).

create or replace view public.restaurant_dish_ratings as
select
    d.restaurant_id,
    d.id as dish_id,
    d.name as dish_name,
    dra.avg_taste,
    dra.avg_texture,
    dra.avg_appearance,
    dra.avg_smell,
    dra.avg_overall,
    dra.rating_count
from public.dishes d
join public.dish_ratings_avg dra on dra.dish_id = d.id;

grant select on public.restaurant_dish_ratings to anon, authenticated;
grant select on public.restaurant_ratings_avg to anon, authenticated;
grant select on public.dish_ratings_avg to anon, authenticated;
