# Plan de rediseño de la experiencia de cervecerías

## Objetivo

Rediseñar la pantalla principal para que explorar cervecerías cercanas sea visualmente claro y rápido. El mapa seguirá siendo el foco, mientras la búsqueda, los filtros, la posición del usuario y la selección de lugares permanecen accesibles. La propuesta toma como referencia las imágenes compartidas, adaptando sus patrones a una app de cervecerías sin copiar marcas ni elementos propietarios.

## Dirección visual

- **Mapa protagonista**: usar la mayor parte de la pantalla para el mapa, manteniendo visibles los lugares y la posición actual. Inspirarse en la primera referencia para la superposición de controles y el carrusel; en la segunda, para la lectura rápida de marcadores y acciones.
- **Paleta con mayor contraste**: verde bosque profundo (`#123B32`) para acciones principales y ubicación; carbón (`#202522`) para texto e iconos; cobre oscuro (`#8A4B2A`) como acento cervecero; superficies claras para controles y tarjetas. Los tonos oscuros se reservan para controles, tipografía y contornos para conservar la legibilidad del mapa.
- **App bar flotante**: buscador visible en la parte superior con acción de filtros e indicador de filtros activos. Mantener controles compactos y dentro del área segura.
- **Iconografía de cervecerías**: usar un pin con símbolo relacionado con elaboración/servicio cervecero (por ejemplo, jarra o fermentador), contorno oscuro y estado seleccionado perceptible por tamaño, halo y contraste. El tipo de cervecería se comunica como etiqueta, no mediante una paleta arbitraria de muchos colores.
- **Ubicación del usuario**: utilizar un símbolo de objetivo o flecha distinto del pin cervecero, con centro verde oscuro, borde claro y halo de precisión cuando el SDK lo proporcione. El control de recentrado debe comunicar si la cámara sigue al usuario o si este la desplazó.
- **Carrusel inferior**: tarjetas compactas con nombre y tipo como primera jerarquía, distancia y ciudad como contexto, y dirección/teléfono/sitio web cuando existan. Seleccionar una tarjeta destaca y centra su marcador; tocar un marcador selecciona su tarjeta. Permitir expandir el carrusel a una lista.
- **Carga y estados**: conservar el mapa y los controles durante la carga; mostrar placeholders en tarjetas y actividad discreta. Vacío, error, permiso denegado y ubicación no disponible deben tener textos breves y acciones recuperables.
- **Responsive y accesibilidad**: mantener carrusel y controles fuera de notch, barras del sistema y área de gestos; presentar los filtros en una hoja desplazable en pantallas estrechas. Añadir semántica y tooltips a los iconos y verificar contraste y objetivos táctiles.

## Búsqueda y filtros

- Incluir búsqueda por coincidencia parcial de nombre mediante OpenBreweryDB Search, con debounce y resultados seleccionables. Elegir un resultado con coordenadas centra el mapa.
- La búsqueda en esta entrega es de cervecerías. OpenBreweryDB no geocodifica ciudades o direcciones; explorar el mapa sin permiso de ubicación no debe presentarse como una búsqueda de lugares.
- Abrir filtros desde el control visible del app bar. Mostrar selección múltiple de tipos: `micro`, `nano`, `regional`, `brewpub`, `large`, `planning`, `bar`, `contract` y `closed`.
- La hoja de filtros incluye contador de filtros activos y acciones claras para aplicar o limpiar. Tras aplicar, mostrar un resumen compacto de filtros seleccionados junto al buscador.
- Conservar consistencia entre consulta, filtros, lista/carrusel y marcadores; respuestas antiguas de búsqueda no deben reemplazar resultados recientes.

## Integración con el plan técnico

Este documento define la intención de presentación. Los contratos de datos, dominio, Bloc, inyección, API, ubicación, token de Mapbox e internacionalización se mantienen en [plan.md](plan.md). La implementación deberá reutilizar `NearbyBreweriesBloc` y sus eventos/estado, sin duplicar la lógica de búsqueda o filtros en widgets.

Los textos propios de la interfaz deben estar disponibles en español e inglés. Añadir las claves necesarias para etiquetas de búsqueda y filtros, contador activo, carga, lista vacía y ausencia de coincidencias; los datos recibidos de OpenBreweryDB conservan el idioma original.

## Plan de validación TDD

**RED:** pruebas de widget para buscador y acceso al panel de filtros; selección múltiple, contador, aplicar y limpiar; carga sin ocultar el mapa; estados vacío/error; selección sincronizada entre carrusel y marcador; distinción semántica entre marcador cervecero y posición de usuario; controles dentro de los insets seguros.

**GREEN:** aplicar la dirección visual a pantalla principal, app bar, iconos, marcadores, ubicación, carrusel, filtros y estados, conectando las interacciones a los contratos existentes en `plan.md`.

**REFACTOR y verificación:** probar traducciones en español/inglés, contraste, semántica, tamaños móviles relevantes, datos opcionales ausentes y que la carga no bloquee las interacciones. Ejecutar las pruebas de widgets y el análisis estático definidos en el plan técnico.

## Criterios de aceptación

- La pantalla inicial deja visibles el mapa, el acceso a búsqueda y el acceso a filtros.
- Se reconoce a simple vista qué marcador representa una cervecería y cuál representa la ubicación del usuario, incluso sin depender solo del color.
- La paleta eleva el contraste sin oscurecer ni ocultar el mapa; app bar, tarjetas y controles se mantienen legibles.
- La carga principal conserva mapa y controles utilizables; vacío, error y estados de ubicación tienen una salida clara.
- Buscar por nombre, combinar varios tipos y limpiar filtros son acciones descubribles; filtros activos permanecen indicados.
- Carrusel y mapa permanecen sincronizados, y los controles respetan áreas seguras en Android e iOS.
- La interfaz es usable con nombres largos, campos opcionales ausentes y ambos idiomas.

PLAN CREATED. Awaiting Human Approval before proceeding to TDD Phase.
