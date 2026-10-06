// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Breweries For The World';

  @override
  String get nearbyBreweries => 'Nearby breweries';

  @override
  String get myLocation => 'My location';

  @override
  String get updatingLocation => 'Updating location';

  @override
  String get searchBreweriesHint => 'Search breweries';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get moreDetails => 'More details';

  @override
  String get breweryDetails => 'Brewery details';

  @override
  String get breweryDetailsLoadError => 'Could not load brewery details.';

  @override
  String get breweryNotFound => 'This brewery could not be found.';

  @override
  String get walking => 'Walk';

  @override
  String get driving => 'Drive';

  @override
  String get locationUnavailable => 'Location unavailable';

  @override
  String get locationUsingLastKnown =>
      'Could not update location. Showing the last known position.';

  @override
  String get calculatingRoute => 'Calculating route...';

  @override
  String get routeError => 'Could not calculate route';

  @override
  String get retryRoute => 'Retry route';

  @override
  String get pageNotFound => 'Page not found';

  @override
  String get backToNearby => 'Nearby breweries';

  @override
  String get openMenu => 'Open menu';

  @override
  String get allBreweries => 'All breweries';

  @override
  String get catalogTitle => 'World breweries';

  @override
  String get catalogLoadError => 'We couldn\'t load the brewery list.';

  @override
  String get loadingBreweries => 'Loading breweries...';

  @override
  String get loadingMoreBreweries => 'Loading more breweries...';

  @override
  String get noBreweries => 'No breweries found.';

  @override
  String get catalogNoMatches =>
      'No breweries match these search or filter settings.';

  @override
  String get catalogSearchHint => 'Search by brewery name';

  @override
  String get catalogSort => 'Sort';

  @override
  String get catalogSortDefault => 'Default order';

  @override
  String get catalogSortNameAscending => 'Name (A-Z)';

  @override
  String get catalogSortNameDescending => 'Name (Z-A)';

  @override
  String get catalogSortCity => 'City (A-Z)';

  @override
  String get catalogSortType => 'Type (A-Z)';

  @override
  String get catalogFilters => 'Filter by type';

  @override
  String catalogFilterCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count types selected',
      one: '1 type selected',
    );
    return '$_temp0';
  }

  @override
  String get catalogApplyFilters => 'Apply';

  @override
  String get catalogClearFilters => 'Clear filters';

  @override
  String get catalogLoadMore => 'Load more';

  @override
  String get noNearbyBreweries => 'No nearby breweries found.';

  @override
  String get mapLoadError => 'Could not load nearby breweries.';

  @override
  String get searchError => 'Could not search breweries.';

  @override
  String get locationPermissionDenied => 'Location permission was denied.';

  @override
  String get locationServiceDisabled =>
      'Enable location services to find nearby breweries.';

  @override
  String get retry => 'Retry';

  @override
  String get theme => 'Appearance';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get spanish => 'Spanish';
}
