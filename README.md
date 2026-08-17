## Project Scenario
Safari Connect is a Nairobi-based online booking platform for long-distance bus and matatu travel, operating since 2024. As booking volumes have grown into the hundreds per month, the company's records — previously tracked in a shared Excel file — became difficult to manage and analyze reliably.

This project involved cleaning and structuring the raw booking data, building a proper data model, and developing an interactive Power BI dashboard to give leadership visibility into route profitability, driver performance, revenue trends, passenger origin, cancellation impact, and peak travel times. The goal is to move Safari Connect from ad-hoc spreadsheet tracking to data-driven decision-making — surfacing which routes and drivers to invest in, where operational risk (cancellations, no-shows) is costing revenue, and how demand patterns should shape scheduling and capacity planning.

The findings in this report are drawn directly from 248 completed bookings across 10 routes and 8 drivers, spanning January 2024 to early January 2025, and are intended to support the board presentation on route strategy, driver recognition, and cancellation reduction.

## Dashboard Preview

![Safari Connect Dashboard preview]((Dashboard/Safari-Connect_Dashboard.png))

## Revenue & Growth

* Total revenue: KES 223,970 across 248 completed trips (Jan 2024 – early Jan 2025), with an average fare of KES 903/trip.
* Revenue is volatile month-to-month, swinging between roughly -23% and +38% from one month to the next, with no sustained upward trend across the year — worth flagging as a growth/consistency problem, not just seasonality.

## Routes

* Nairobi → Mombasa is the top earner (KES 51,600, 26 bookings, highest average fare at ~KES 1,292), nearly double the next-best route.
* Nairobi → Machakos and Kisumu → Kakamega are the weakest (~KES 6,900–6,930 each) despite similar booking volumes to other routes — their fares are simply too low to be worthwhile at current volume.
* Recommendation: protect and potentially expand capacity on Mombasa/Eldoret/Kisumu routes; review pricing or consolidate low-yield routes like Machakos and Kakamega.

## Cancellations (a genuine risk area)

* Across all scheduled trips, 7.4% are cancelled and another 4.9% are no-shows — combined, ~12% of scheduled trips never complete.
* Mombasa → Malindi has the worst cancellation rate (20%) — 1 in 5 bookings on that route falls through, despite decent per-route revenue.
* Nairobi → Eldoret is the most reliable route (3.7% cancellation) and also a top-3 revenue earner — a route worth using as the operational benchmark.
* Recommendation: investigate root cause on Malindi and Machakos routes specifically (driver availability, timing, overbooking).

## Drivers

* Revenue leaders: Isaac Korir (KES 32,505), Kelvin Omondi (KES 30,855), Brian Kamau (KES 28,290).
* Notable gap worth flagging: Moses Kipchoge has the highest driver rating (4.8) but the lowest trip rating (3.12) of anyone — passengers are rating the trip experience much lower than they're rating the driver personally. That split usually points to a vehicle, route, or timing issue rather than the driver's conduct, and is worth a direct look.
* **Who to promote:** Samuel Gitonga is the strongest all-round candidate — highest combined passenger/driver rating (4.1 avg across both), solid revenue (KES 28,235) and volume (33 trips), no red flags. Hassan Abdi and Brian Kamau are close behind and also worth considering.
* Isaac Korir brings in the most revenue (KES 32,505) but has the lowest driver rating (3.8) of the group — good for volume, but ratings should improve before a promotion, not after.

## Cancellation Cost

* Estimated revenue lost to cancellations and no-shows: **~KES 17,240** (roughly 7% of actual revenue earned), based on lost bookings valued at each route's average fare.
* Cancellations alone account for ~KES 12,840 of that; no-shows account for the remaining ~KES 4,400.
* Nairobi → Mombasa loses the most in absolute terms (~KES 5,170) simply because its fares are highest — even a handful of cancellations there costs more than a full route's worth of cancellations elsewhere.
* Recommendation: pair this with the route-level cancellation rates above — Mombasa → Malindi and Nairobi → Machakos are the two routes losing money proportionally, not just in absolute terms.

## Busiest Travel Times

* **Peak departure slots:** 06:00 (24 bookings), 10:30 and 19:00 (23 each), 09:00 (22), 21:00 (21) — demand clusters around early morning, late morning, and evening commute-style windows rather than one single peak.
* **Busiest days:** Wednesday (49 bookings), Tuesday (46), and Monday (45) lead the week; the weekend is markedly quieter, with Sunday the lowest at just 10 bookings.
* Monday brings in the most revenue (KES 47,350) despite Wednesday having more bookings — worth noting fare mix varies by day.
* Recommendation: prioritize vehicle and driver availability early week and around the 06:00/10:30/19:00 slots; weekend capacity could likely be trimmed without hurting revenue.

## Passenger Satisfaction

* 46% Satisfied, 29% Neutral, 19.4% Unsatisfied, 5.6% unrated.
* Combined with an average trip rating of 3.53/5, satisfaction is middling rather than strong — nearly 1 in 5 passengers are actively unhappy, which is a bigger flag than the average score alone suggests.

## Operational Mix

* Nairobi dominates: 111 of 248 bookings and KES 110,410 (49% of total revenue) — the business is heavily concentrated in one city.
* Matatu and Bus are roughly tied as the top revenue vehicle types (~KES 84–85K each); Minibus lags at KES 55,330.
* M-Pesa is the dominant payment method (53% of bookings), Card is the smallest (20%) — useful context if you're considering any payment-partner negotiations.
