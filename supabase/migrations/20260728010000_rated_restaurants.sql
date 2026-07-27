-- Pins auf der Karte sollen nur für Restaurants mit mindestens einer
-- Bewertung erscheinen (nicht für jedes per "+" oder Kartentipp neu
-- angelegte, aber noch unbewertete Restaurant).

create or replace view public.rated_restaurants as
select r.id, r.apple_maps_id, r.name, r.lat, r.lng, r.address
from public.restaurants r
where exists (
    select 1 from public.ratings rt where rt.restaurant_id = r.id
);

grant select on public.rated_restaurants to anon, authenticated;
