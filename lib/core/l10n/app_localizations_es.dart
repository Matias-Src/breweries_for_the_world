// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Cervecerías del mundo';

  @override
  String get nearbyBreweries => 'Cervecerías cercanas';

  @override
  String get myLocation => 'Mi ubicación';

  @override
  String get updatingLocation => 'Actualizando ubicación';

  @override
  String get searchBreweriesHint => 'Buscar cervecerías';

  @override
  String get clearSearch => 'Borrar búsqueda';

  @override
  String get moreDetails => 'Ver más detalles';

  @override
  String get breweryDetails => 'Detalles de la cervecería';

  @override
  String get breweryDetailsLoadError =>
      'No se pudieron cargar los detalles de la cervecería.';

  @override
  String get walking => 'A pie';

  @override
  String get driving => 'En auto';

  @override
  String get locationUnavailable => 'Ubicación no disponible';

  @override
  String get locationUsingLastKnown =>
      'No se pudo actualizar la ubicación. Se muestra la última posición conocida.';

  @override
  String get calculatingRoute => 'Calculando ruta...';

  @override
  String get routeError => 'No se pudo calcular la ruta';

  @override
  String get retryRoute => 'Reintentar ruta';

  @override
  String get pageNotFound => 'Página no encontrada';

  @override
  String get backToNearby => 'Cervecerías cercanas';

  @override
  String get openMenu => 'Abrir menú';

  @override
  String get allBreweries => 'Todas las cervecerías';

  @override
  String get catalogTitle => 'Cervecerías del mundo';

  @override
  String get catalogLoadError => 'No se pudo cargar la lista de cervecerías.';

  @override
  String get loadingBreweries => 'Cargando cervecerías...';

  @override
  String get loadingMoreBreweries => 'Cargando más cervecerías...';

  @override
  String get noBreweries => 'No se encontraron cervecerías.';

  @override
  String get catalogNoMatches =>
      'Ninguna cervecería coincide con la búsqueda o los filtros.';

  @override
  String get catalogSearchHint => 'Buscar por nombre de cervecería';

  @override
  String get catalogSort => 'Ordenar';

  @override
  String get catalogSortDefault => 'Orden original';

  @override
  String get catalogSortNameAscending => 'Nombre (A-Z)';

  @override
  String get catalogSortNameDescending => 'Nombre (Z-A)';

  @override
  String get catalogSortCity => 'Ciudad (A-Z)';

  @override
  String get catalogSortType => 'Tipo (A-Z)';

  @override
  String get catalogFilters => 'Filtrar por tipo';

  @override
  String catalogFilterCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tipos seleccionados',
      one: '1 tipo seleccionado',
    );
    return '$_temp0';
  }

  @override
  String get catalogApplyFilters => 'Aplicar';

  @override
  String get catalogClearFilters => 'Limpiar filtros';

  @override
  String get catalogLoadMore => 'Cargar más';

  @override
  String get noNearbyBreweries => 'No se encontraron cervecerías cercanas.';

  @override
  String get mapLoadError => 'No se pudieron cargar las cervecerías cercanas.';

  @override
  String get searchError => 'No se pudieron buscar cervecerías.';

  @override
  String get locationPermissionDenied => 'Se denegó el permiso de ubicación.';

  @override
  String get locationServiceDisabled =>
      'Activa los servicios de ubicación para buscar cervecerías cercanas.';

  @override
  String get retry => 'Reintentar';

  @override
  String get theme => 'Apariencia';

  @override
  String get darkMode => 'Modo oscuro';

  @override
  String get language => 'Idioma';

  @override
  String get english => 'Inglés';

  @override
  String get spanish => 'Español';
}
