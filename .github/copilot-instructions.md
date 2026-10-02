# Context & Constraints: Breweries For The World (`breweries_for_the_world`)

## Environment & Tech Stack
- **Flutter Version:** 3.41.2
- **Dart Version:** 3.11.0
- **App Name:** `breweries_for_the_world`
- **Core Architecture:** Clean Architecture / Layered (Domain / Data / Presentation)
- **State Management:** `flutter_bloc` with `bloc_concurrency` (Transformers, Debounce for search)
- **Dependency Injection:** `get_it` and `injectable`
- **Networking:** `dio` with custom interceptors and typed exceptions
- **Testing:** `mocktail` and `bloc_test`
- **Maps & Location:** `mapbox_maps_flutter` / `geolocator`
- **Internationalization (i18n):** English and Spanish support (`flutter_localizations` / `slang` / `easy_localization`)

## SDLC Rules & Human-in-the-Loop (HITL)
1. **Planning First:** NO CODE MUST BE WRITTEN before an architectural plan is defined and explicit human approval is received.
2. **TDD Workflow:**
   - **RED:** Write unit/bloc test that fails first.
   - **GREEN:** Write minimum code to satisfy the test.
   - **REFACTOR:** Clean up code without breaking tests.
3. **Strict Boundaries:**
   - Widgets MUST NOT call `GetIt` directly. Inject BLoCs via `BlocProvider` or constructor.
   - Repositories MUST catch exceptions and throw Domain-Specific Typed Exceptions.
   - BLoCs/Cubits MUST emit Sealed States handling Loading, Success, Error, and Empty states.
   - Avoid silent failures and empty catch blocks.

## Scope & Bonus Features
- **Core:** 
  1. Brewery List (Paginated, Loading/Error/Empty states, Name, Type, City).
  2. Brewery Detail (Name, Address, Phone, Website).
  3. Search with Debounce (`bloc_concurrency`).
- **Bonus Feature (Selected):** Distance sorting (Geolocator + Haversine/Turf) & Proximity Search.
- **Improvement / Research Spike:** Route between two points & transit mode recommendations (Mapbox Directions API / Mapbox Navigation).