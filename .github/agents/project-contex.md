# Business & Domain Context: Breweries For The World (`breweries_for_the_world`)

## App Objective
A fast brewery search application supporting localizations (English/Spanish), proximity search, route calculation research, and location-based brewery details.

## Technical Requirements & Constraints
- **Framework & Language:** Flutter 3.41.2 / Dart 3.11.0
- **Architecture:** Clean Architecture / Layered (Domain / Data / Presentation)[cite: 1]
- **API Base URL:** `https://api.openbrewerydb.org/v1/breweries`[cite: 1]

## Endpoints Specification
1. **List Breweries (Paginated):** `GET /breweries?per_page=20&page={page}`[cite: 1]
2. **Search Breweries:** `GET /breweries/search?query={q}`[cite: 2]
3. **Brewery Detail:** `GET /breweries/{id}`[cite: 2]

## Domain Entities & Data Contracts
### Entity: `Brewery`
- `id`: String
- `name`: String
- `breweryType`: String (`micro`, `nano`, `regional`, `brewpub`, `large`, `planning`, `bar`, `contract`, `closed`)
- `city`: String
- `address`: String? (address_1)
- `phone`: String?
- `websiteUrl`: String?
- `latitude`: double?
- `longitude`: double?
- `distanceKm`: double? (Computed property)

## UI & Functional Acceptance Criteria
1. **Brewery List Screen:**
   - Displays paginated list (Name, Type, City)[cite: 2].
   - Must handle UI states explicitly: `Loading`, `Success`, `Error`, `Empty`[cite: 2].
   - Debounced search bar using `bloc_concurrency`.
2. **Brewery Detail Screen:**
   - Displays Name, Address, Phone, Website, and Location Map.
3. **Bonus Feature (Proximity & Sort):**
   - Geolocation permission via `geolocator`.
   - Calculate distance with Haversine formula and sort items by distance.
4. **Improvement Feature (Route & Transit Spike):**
   - Route calculation research using Mapbox Directions API between user's location and selected brewery.
   - Support modal transport types (`walking`, `cycling`, `driving`).
5. **Localization (i18n):**
   - Full support for Spanish (`es`) and English (`en`).