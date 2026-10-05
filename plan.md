# Plan: Pantalla inicial de cervecerías cercanas

## Objetivo

Crear una pantalla de descubrimiento centrada en un mapa, inspirada en la fluidez de Uber: mostrar la posición del usuario y las cervecerías disponibles alrededor, con búsqueda y filtros accesibles sin ocultar el mapa. La pantalla debe seguir siendo útil si el usuario deniega el permiso de ubicación o si una cervecería no tiene coordenadas.

## Experiencia propuesta

- **Mapa como superficie principal**, ocupando la mayor parte de la pantalla, con marcadores para cervecerías geolocalizadas y un control para volver a centrar en la posición actual.
- **Búsqueda superpuesta en la parte superior** para buscar cervecerías por coincidencia parcial de nombre usando OpenBreweryDB Search. Al elegir un resultado, centrar el mapa en sus coordenadas disponibles. La búsqueda no se presentará como geocodificación de ciudades/direcciones.
- **Filtros de tipo en chips desplazables**: micro, nano, regional, brewpub, large, planning, bar, contract y closed. Permitir seleccionar varios y ofrecer una acción clara para limpiar filtros.
- **Carrusel horizontal inferior de tarjetas** con las 40 cervecerías más próximas a la posición del usuario, ordenadas por distancia mediante `by_dist` en OpenBreweryDB. El mapa muestra los marcadores geolocalizados de esos resultados que correspondan al área actualmente visible. Cada tarjeta muestra nombre, tipo, teléfono, dirección completa y enlace al sitio web cuando estén disponibles; ciudad y distancia se incluyen como contexto. Los datos opcionales se omiten limpiamente. Al deslizar el carrusel se destaca y centra el marcador correspondiente; tocar un marcador desplaza el carrusel a su tarjeta. Se conserva una vista expandida/lista para explorar resultados con más espacio.
- **Estados visibles y recuperables**: cargando, resultados, sin resultados, error/reintento, permiso denegado y ubicación no disponible. Sin ubicación, permitir explorar el mapa y buscar una ciudad/lugar.
- **Acceso al detalle** al seleccionar una cervecería, sin mezclar la lógica del detalle con el estado del mapa.
- **Arranque y carga**: usar la splash nativa solo durante la inicialización breve del proceso. Tras abrir la app, mostrar el mapa con un indicador/estado de carga mientras se resuelven permiso, ubicación y datos; no bloquear la splash esperando la red. Si la carga tarda o falla, mantener acciones disponibles y mostrar reintento. Considerar caché/localización de la última zona solo si se aprueba persistencia.

## Suposiciones y límites que hay que validar

- OpenBreweryDB queda confirmada como fuente (`https://api.openbrewerydb.org/v1/breweries`). Su listado soporta `by_dist=latitud,longitud` para ordenar por distancia y `per_page` hasta 200; solicitar `per_page=40` para la lista inicial. Esto obtiene los 40 más cercanos disponibles con coordenadas, no todos los lugares de un radio garantizado.
- El endpoint Search hace coincidencia parcial, sin distinguir mayúsculas/minúsculas, contra nombres de cervecerías. No busca ni geocodifica por sí mismo una ciudad/dirección; en esta entrega, la búsqueda acordada es de cervecerías.
- Las coordenadas de `Brewery` son opcionales. Por tanto, los marcadores, la distancia y la ordenación por proximidad solo aplican a resultados con latitud y longitud válidas.
- Si la ubicación no está disponible o se deniega el permiso, no se puede solicitar “las más cercanas”: mostrar el mapa sin posición del usuario y permitir búsqueda de cervecerías, con estado explicativo y reintento de ubicación.
- Mapbox está confirmado. Pasar el token desde `.env` como entrada de compilación con `--dart-define-from-file=.env`; el archivo usa formato JSON, no se declara como asset y permanece en `.gitignore`. Documentar la variable en `.env.example`. El token público compilado en una app cliente se puede extraer, por lo que no debe contener credenciales privadas y debe restringirse por aplicación/plataforma y permisos.

## Arquitectura y contratos

### Data

- `BreweryDto`: parseo de `id`, `name`, `brewery_type`, `city`, `address_1`, `phone`, `website_url`, `latitude` y `longitude`; validar coordenadas ausentes o inválidas sin descartar el resto de la cervecería.
- `BreweryRemoteDataSource` sobre Dio: métodos para listado cercano (`by_dist={latitude},{longitude}&per_page=40`), búsqueda por nombre y detalle, usando OpenBreweryDB. Aplicar los filtros de tipo sin perder el orden por distancia y definir mediante prueba de contrato cómo combinar tipos múltiples con el parámetro `by_type`.
- `LocationDataSource`: encapsular `geolocator`, permisos, servicio habilitado y posición actual; traducir errores de plataforma a resultados/errores tipados.
- `BreweryRepositoryImpl`: mapear DTO a entidad y traducir fallos de Dio a excepciones de dominio tipadas (`NetworkException`, `ServerException`, `ParsingException` u otras acordadas). No ocultar errores.

### Domain

- Entidad `Brewery`: `id`, `name`, `breweryType`, `address1`, `address2`, `address3`, `street`, `city`, `state`, `stateProvince`, `postalCode`, `country`, `phone`, `websiteUrl`, `latitude`, `longitude` y `distanceKm` opcional/calculada. Mantener los campos de dirección en la entidad para formar una dirección legible sin perder la estructura del API; evitar duplicar segmentos idénticos al presentarlos.
- Repositorios abstractos para cervecerías y ubicación.
- Casos de uso sugeridos: `GetNearestBreweries` (origen y límite de 40), `SearchBreweries` (texto con debounce en presentación), `GetCurrentLocation` y `CalculateDistance`/presentación de distancia.
- Aplicar filtros de tipo y cálculo Haversine en dominio o servicio de dominio, exclusivamente sobre ubicaciones válidas. Mantener la sincronización entre área visible, marcadores y lista como una entrada explícita del estado de presentación.

### Presentation

- `NearbyBreweriesBloc` como propietario del estado de la pantalla; el widget no debe llamar a `GetIt` directamente.
- Eventos previstos: `LocationRequested`, `SearchQueryChanged`, `SearchResultSelected`, `BrewerySelected`, `BreweryTypesChanged`, `FiltersCleared` y `RetryRequested`. `MapAreaChanged` solo actualiza qué marcadores quedan visibles; no cambia el origen de proximidad, que sigue siendo la posición del usuario.
- Estados sellados: `Loading`, `Success`, `Empty` y `Error`, incluyendo en los datos de estado la posición/área actual, resultados, filtros activos, selección y estado del permiso para que las interacciones del mapa no pierdan contexto.
- Debounce para texto y control de concurrencia con `bloc_concurrency`; descartar respuestas antiguas al cambiar rápidamente la consulta o el área del mapa.
- Widgets de presentación sugeridos: pantalla del mapa, barra de búsqueda, filtros, marcador/selección, carrusel horizontal inferior de tarjetas, vista expandida de resultados y vistas de estado. Inyectar el Bloc con `BlocProvider` o constructor.
- Mantener un índice/id de tarjeta seleccionada en el estado de presentación. Evitar que el evento de centrado del mapa y el desplazamiento del carrusel se realimenten indefinidamente; definir cuál interacción origina cada selección y probar esa sincronización.

### Inyección y dependencias

- Registrar fuentes remotas, repositorios, casos de uso y `NearbyBreweriesBloc` con `get_it`/`injectable`, respetando los módulos y convenciones aprobados.
- Dependencias a incorporar: `flutter_bloc`, `bloc_concurrency`, `dio`, `get_it`, `injectable`, `mapbox_maps_flutter`, `geolocator` y las dependencias/generadores elegidos para i18n. El `pubspec.yaml` actual solo contiene dependencias del scaffold Flutter.
- Leer `MAPBOX_ACCESS_TOKEN` con `String.fromEnvironment`, suministrado mediante `--dart-define-from-file=.env`. Mantener `.env` fuera del control de versiones y añadir `.env.example` como JSON con el nombre de variable y un valor ilustrativo; el usuario completará las variables reales. No incluir credenciales privadas en el cliente.
- No agregar Turf si Haversine cubre este alcance y no se necesitan otras operaciones geoespaciales.

## Internacionalización

Añadir inglés (`en`) y español (`es`) mediante i18n, con un control accesible para cambiar el idioma dentro de la app y actualización inmediata de los textos de interfaz:

- `nearbyBreweriesTitle`, `searchBreweriesHint`, `filtersTitle`, `clearFilters`, `myLocation`, `distance`, `phone`, `address`, `website`, `openWebsite`, `language`, `english`, `spanish`, `noBreweriesNearby`, `noResults`, `locationPermissionDenied`, `locationServiceDisabled`, `locationUnavailable`, `mapLoadError`, `searchError`, `retry`, `loadingBreweries`, `openBreweryDetails`.
- Traducir también nombres de tipos si se muestran localizados, conservando el valor API para filtrado. Los campos de contenido recibidos de OpenBreweryDB (nombre, dirección, ciudad, etc.) se muestran tal como los devuelve la API; cambiar idioma solo cambia los textos propios de la app.

## Plan de pruebas TDD

1. **RED - dominio/datos:** probar el mapeo DTO con coordenadas nulas e inválidas, solicitud de `by_dist` con `per_page=40`, cálculo Haversine, filtros de tipos y conversión de errores del repositorio.
2. **RED - Bloc:** probar carga inicial de 40 resultados cercanos, ubicación permitida/denegada, búsqueda de cervecerías con debounce, filtros múltiples, selección y sincronización carrusel-marcador, cambio de idioma, lista vacía, error/reintento y respuestas fuera de orden.
3. **GREEN:** implementar los contratos y el mínimo código para hacer pasar cada conjunto de pruebas.
4. **REFACTOR:** validar límites de capas e inyección, accesibilidad de controles, traducciones y comportamiento responsive; completar pruebas de widgets para los estados principales y sincronización lista-marcador.

## Criterios de aceptación

- La pantalla abre en el mapa y los resultados/marcadores/carrusel corresponden a la consulta y al área elegida; seleccionar una tarjeta y seleccionar su marcador mantienen la selección sincronizada.
- Las tarjetas muestran nombre, teléfono, dirección y sitio web cuando hay datos; la ausencia de campos opcionales no genera etiquetas vacías ni errores.
- Se puede buscar cervecerías por coincidencia parcial de nombre; seleccionar un resultado con coordenadas centra el mapa.
- Se pueden aplicar y limpiar varios filtros de tipo.
- La ubicación y la distancia se muestran solo con permiso y coordenadas válidas; denegar ubicación no bloquea exploración y búsqueda.
- La interfaz cubre carga, éxito, vacío, error con reintento y los estados de ubicación sin fallos silenciosos.
- Los textos propios de la app se pueden cambiar entre español e inglés; los datos originales de OpenBreweryDB no se traducen.
- Se solicitan las 40 cervecerías más próximas usando la posición del usuario y el orden `by_dist`; sin ubicación se muestra un estado alternativo y no se simula proximidad.
- El token público de Mapbox se pasa desde `.env` mediante `--dart-define-from-file`, sin empaquetar el archivo como asset. No se incluye un token real en el repositorio y el usuario puede configurar su variable. El valor del token sí queda dentro de la app compilada.
- La splash nativa no espera llamadas de red; la carga de datos tiene estados visibles, conserva acceso a reintentar y no bloquea la exploración más tiempo del necesario.

## Decisiones confirmadas y límites de alcance

1. Fuente confirmada: OpenBreweryDB; se utilizará `by_dist` para pedir 40 resultados cercanos.
2. Búsqueda confirmada: endpoint Search de OpenBreweryDB para coincidencias parciales de nombres; no se implementará geocodificación de lugares en este alcance.
3. Mapa confirmado: Mapbox, con token público suministrado en compilación desde `.env` JSON mediante `--dart-define-from-file`; el usuario proporcionará el valor.
4. Presentación confirmada: carrusel con las 40 cervecerías más próximas a la ubicación del usuario.
5. Idiomas confirmados: inglés y español para textos de interfaz; los datos entregados por la API conservan su idioma original.

## Tareas

### Tarea 1: Contratos API y distancia

**RED:** añadir tests de `BreweryDto` que verifiquen todos los campos de dirección del ejemplo, coordenadas nulas/fuera de rango y campos obligatorios inválidos; testear con adaptador HTTP falso la ruta y los parámetros `by_dist` y `per_page=40`; cubrir respuesta inválida, errores de servidor y red. Añadir tests Haversine con distancias conocidas y coordenadas ausentes.

**GREEN:** completar/ajustar DTO y datasource para que las entradas inválidas produzcan excepciones tipadas; calcular `distanceKm` desde la posición actual solo cuando ambas coordenadas sean válidas. Mantener el orden de cercanía de la API.

**Aceptación:** consultas verificables sin red real; los datos opcionales se preservan; no se calculan distancias con coordenadas inválidas; las fallas de red, HTTP y parseo se distinguen.

### Tarea 2: Ubicación y carga inicial

**RED:** probar servicio de ubicación deshabilitado, permiso concedido, denegado y denegado permanentemente, además de ubicación válida; probar que la primera carga pide ubicación, que el error/denegación no provoca una consulta de proximidad falsa y que reintentar vuelve a solicitarla.

**GREEN:** añadir `LocationDataSource`, repositorio/caso de uso de ubicación, errores de dominio y eventos del Bloc para cargar/reintentar ubicación. El Bloc obtiene las coordenadas en vez de recibirlas como una acción ya resuelta por la UI.

**Aceptación:** permiso denegado no bloquea búsqueda posterior; no se llama a `by_dist` sin una posición válida; carga/error/ubicación no disponible quedan representados explícitamente.

### Tarea 3: Búsqueda y filtros

**RED:** probar el endpoint Search con query URL-encoded y sus resultados; Bloc con búsqueda vacía, debounce, éxito/vacío/error, tipos múltiples, limpiar filtros y respuestas fuera de orden; cubrir que una respuesta antigua no reemplace la consulta más reciente.

**GREEN:** agregar búsqueda al datasource/repositorio/caso de uso; introducir `bloc_concurrency` y eventos/estado para consulta, tipos activos y resultados; aplicar filtros sin perder el orden por distancia y definir el comportamiento de tipos múltiples según el contrato real de OpenBreweryDB.

**Aceptación:** búsqueda por nombre funciona sin llamadas por cada pulsación; los filtros se pueden combinar/limpiar; concurrencia no muestra resultados obsoletos.

### Tarea 4: Configuración, DI y arranque

**RED:** conservar y adaptar `test/core/di/injection_container_test.dart` para verificar que el registro generado resuelve las dependencias actuales usando un contenedor aislado, sin estado compartido entre pruebas. Cubrir también que `AppConfig` se registra antes de construir `Dio` y el datasource de Mapbox, y que el arranque solo ejecuta `runApp` después de configurar DI. Probar carga de configuración y fallo claro si falta `MAPBOX_ACCESS_TOKEN`.

**GREEN:** incorporar `injectable` como integración de generación de registros sobre `get_it`, junto con `injectable_generator` como dependencia de desarrollo; reutilizar `build_runner` ya presente. Añadir `@InjectableInit` en el punto de composición y anotaciones/módulos para las implementaciones y dependencias del grafo (Dio, datasources, repositorios, casos de uso y BLoCs). Mantener `AppConfig` como dependencia de runtime: registrarla antes de ejecutar el inicializador generado y proveerla al módulo que construye Dio y Mapbox Directions. Sustituir el registro manual repetitivo de `configureDependencies` por una función pequeña que registre la configuración y llame al inicializador generado. Confirmar en la versión instalada de Injectable cómo dirigir la generación a una instancia `GetIt` aislada para pruebas; no sacrificar el aislamiento actual usando silenciosamente el singleton global. Regenerar los archivos con `build_runner` y no editarlos a mano. Mantener `getIt` solo en el composition root (`main`/bootstrap), sin llamadas desde widgets. Configurar `MAPBOX_ACCESS_TOKEN` con `String.fromEnvironment` desde `--dart-define-from-file=.env`, añadir `.env.example` y excluir `.env` en `.gitignore`.

**REFACTOR:** eliminar imports y registros manuales que queden obsoletos; revisar que el ciclo de vida de cada dependencia generado corresponda al actual (singleton perezoso para servicios/casos de uso y factory para BLoCs); mantener nombres y contratos públicos usados por `main` y pruebas siempre que sea viable.

**Aceptación:** `injectable` genera el grafo de dependencias y `get_it` sigue siendo el contenedor en runtime; la prueba de DI verifica todas las dependencias principales con un contenedor aislado y puede ejecutarse repetidamente sin colisiones; `AppConfig` llega correctamente a Dio y Mapbox; los widgets no acceden al service locator; `.env` real no se versiona ni se empaqueta como asset; el ejemplo contiene solo un valor dummy; el arranque nunca espera peticiones de red en la splash. El token público se considera extraíble del binario.

**Verificación:** ejecutar generación con `dart run build_runner build --delete-conflicting-outputs`, la prueba focal de DI, las pruebas de `app_startup` y `flutter analyze`. Revisar el diff para asegurar que los archivos generados están actualizados y que no se editan manualmente.

### Tarea 5: Mapa Mapbox y ubicación visible

**RED:** pruebas de widget sobre estado del mapa, posición/cámara inicial, marcadores solo para coordenadas válidas, selección de marcador y control para recentrar; añadir smoke/integration test en dispositivo para creación real del mapa y permisos nativos.

**GREEN:** incorporar Mapbox, inicializar cámara con ubicación disponible, representar usuario y marcadores, manejar permisos/plataforma y recentrado. Mantener una frontera de widget/adaptador para poder probar interacciones sin depender del canal nativo en tests unitarios.

**Aceptación:** mapa es el elemento principal; permisos denegados o coordenadas ausentes no causan crash; el token se obtiene de configuración; el mapa muestra los resultados de la lista cercana que tienen coordenadas.

### Tarea 6: Carrusel, selección y detalle

**RED:** pruebas de widget para las 40 tarjetas, campos opcionales ocultos, dirección sin segmentos duplicados, selección desde carrusel que centra/resalta marcador y selección desde marcador que desplaza al elemento; probar lista expandida y apertura de detalle.

**GREEN:** construir tarjetas/carrusel inferior sincronizado con el mapa y selección en estado; crear vista expandida/lista; añadir navegación o vista de detalle con nombre, dirección, teléfono, web y mapa si hay coordenadas.

**Aceptación:** las tarjetas muestran nombre, tipo, teléfono, dirección, web, ciudad y distancia disponibles; no aparecen etiquetas vacías; la sincronización no crea bucles de eventos.

## Ajustes previos a Tareas 7 y 8: área segura y cámara inicial

**Estado:** propuesta pendiente de aprobación humana. No implementar hasta aprobar este plan.

### Objetivo

- Restringir el mapa interactivo al área segura para que los gestos del mapa no lleguen a las barras del sistema ni a recortes de pantalla en Android/iOS.
- Evitar que el primer viewport muestre el mundo completo y cargue mosaicos de una región innecesariamente amplia, causa probable del ANR observado.
- Mantener la ubicación real como prioridad cuando esté disponible y dejar un viewport regional útil mientras se resuelve o se deniega el permiso.

### Evidencia y comportamiento actual

- `MapboxBreweryMapAdapter` usa `(0, 0)` y zoom `2` cuando no recibe una ubicación inicial; este encuadre muestra el mundo a escala global.
- `NearbyBreweriesMapPage` compone el mapa y sus controles en un `Stack` dentro del `Scaffold`, pero no declara un límite `SafeArea` para esa escena.
- La pantalla ya recentra a zoom `12` al recibir ubicación y al seleccionar una tarjeta; la cámara inicial no debe reiniciarse en cada actualización de resultados o selección.

### Política propuesta de cámara

1. Si existe una ubicación actual válida, usarla como centro inicial con zoom `12`.
2. Mientras la ubicación se resuelve, o si no está disponible, usar un punto regional fijo y un zoom de detalle: propuesta provisional para aprobación, centro continental de EE. UU. (`39.8283, -98.5795`) y zoom `5.5`. La fuente tiene una concentración importante de resultados en EE. UU.; confirmar este punto o proporcionar otro antes de implementar.
3. Cuando llegue la ubicación real, cambiar una sola vez del fallback al centro del usuario. Cambios posteriores en resultados, tarjetas o selección no deben restaurar el fallback ni encuadrar automáticamente todos los marcadores.
4. Mantener el recenter actual de ubicación/tarjeta a zoom `12`. No añadir carga de datos, ajuste de límites geográficos ni encuadre global para resolver el ANR.
5. Centralizar centro y zoom fallback en una configuración de presentación testeable; no duplicar literales en la página y el adaptador.

### Área segura

- Envolver la superficie del mapa y los controles superpuestos de la pantalla principal en `SafeArea`, incluyendo insets laterales y el borde inferior de navegación/gestos.
- Dejar que `Scaffold`/`AppBar` gestione el área superior y evitar aplicar dos veces el inset superior.
- Asegurar que el carrusel y los botones flotantes permanezcan dentro del área segura; el mapa podrá ocupar el resto del viewport, pero no recibir hit tests en los insets del sistema.
- Revisar también la vista de detalle para que el mapa incrustado respete los insets de su contenido desplazable.

### Plan TDD

**RED:**

- Prueba de widget con `MediaQuery.viewPadding` simulado que verifica que los límites hit-testables del mapa no invaden el inset inferior/lateral y que los controles quedan dentro del área segura.
- Pruebas unitarias de la política de cámara: ubicación válida prevalece sobre fallback; ubicación ausente/inválida produce el punto y zoom regional aprobados; nunca se usa `(0, 0)`/zoom `2` como arranque normal.
- Prueba de widget/adaptador que confirma que cambios de resultados no vuelven a aplicar el fallback ni cambian el centro inicial del usuario.
- Registrar las expectativas del smoke de dispositivo: apertura en frío, cámara inicial regional, recepción de ubicación, uso de carrusel/recenter y ausencia de ANR.

**GREEN:**

- Añadir el wrapper de área segura en la pantalla de mapa y ajustar la posición de overlays según los insets.
- Introducir una política/configuración pequeña de cámara inicial y pasar su centro/zoom explícitamente al adaptador Mapbox.
- Aplicar el objetivo fallback una sola vez; conservar el centro actual ante actualizaciones de estado que no representen una nueva ubicación inicial.

**REFACTOR y verificación:**

- Ejecutar el test focal, `flutter analyze` y la suite completa.
- Con token configurado, hacer smoke en emulador Android y revisar logs para confirmar que el arranque ya no presenta ANR; comprobar gestos y controles junto a las barras del sistema.
- Verificar en iOS con insets de safe area cuando el entorno esté disponible. No incluir ni imprimir el valor del token en logs o documentación.

### Criterios de aceptación

- Ningún gesto sobre la barra de estado, barra de navegación o área de gestos se entrega a Mapbox.
- Con ubicación válida, el mapa abre centrado en el usuario; sin ella, abre en el punto/zoom regional aprobados, no en una vista mundial.
- Las actualizaciones normales de Bloc no restablecen la cámara ni disparan encuadres repetidos.
- En el smoke Android no se observa ANR durante la apertura y el mapa sigue siendo usable; quedan documentados los límites de verificación en iOS si no hay dispositivo disponible.

### Límites de alcance

- Este ajuste no adelanta i18n, estados de experiencia ni pruebas de integración general de Tareas 7 y 8.
- No cambia la fuente de ubicación, permisos nativos, consulta OpenBreweryDB ni el conjunto de marcadores.
- El punto fallback propuesto es provisional y requiere confirmación humana antes de escribir código.

### Tarea 7: Internacionalización y estados de experiencia

**RED:** tests para alternar inglés/español en controles y estados, mantener los datos originales de OpenBreweryDB sin traducir, y renderizar carga, vacío, error/reintento, permiso denegado y ubicación no disponible.

**GREEN:** elegir e integrar una sola estrategia i18n, añadir catálogo `en`/`es` y selector accesible, traducir filtros y estados, completar estados visuales responsive y accesibles.

**Aceptación:** cambiar idioma actualiza textos propios de la app sin alterar nombres/direcciones del API; todos los estados tienen acción o salida clara; controles principales son accesibles.

### Tarea 8: Verificación integrada

**RED:** añadir pruebas de flujo de primera apertura a mapa/lista, búsqueda/filtros/selección, pérdida o denegación de ubicación, error de red/reintento y cambio de idioma; correr análisis estático y pruebas en Android/iOS cuando los entornos estén disponibles.

**GREEN:** conectar el flujo completo, corregir errores detectados y verificar comportamiento en tamaños móviles relevantes y permisos reales. Confirmar que los permisos y configuración nativa estén presentes en Android e iOS.

**Aceptación:** suite automatizada y análisis pasan; smoke test manual/dispositivo confirma mapa, ubicación, marcadores y carrusel; sin secretos reales en el repositorio.
