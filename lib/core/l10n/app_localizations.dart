import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Breweries For The World'**
  String get appTitle;

  /// No description provided for @nearbyBreweries.
  ///
  /// In en, this message translates to:
  /// **'Nearby breweries'**
  String get nearbyBreweries;

  /// No description provided for @myLocation.
  ///
  /// In en, this message translates to:
  /// **'My location'**
  String get myLocation;

  /// No description provided for @updatingLocation.
  ///
  /// In en, this message translates to:
  /// **'Updating location'**
  String get updatingLocation;

  /// No description provided for @searchBreweriesHint.
  ///
  /// In en, this message translates to:
  /// **'Search breweries'**
  String get searchBreweriesHint;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No description provided for @moreDetails.
  ///
  /// In en, this message translates to:
  /// **'More details'**
  String get moreDetails;

  /// No description provided for @breweryDetails.
  ///
  /// In en, this message translates to:
  /// **'Brewery details'**
  String get breweryDetails;

  /// No description provided for @breweryDetailsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load brewery details.'**
  String get breweryDetailsLoadError;

  /// No description provided for @walking.
  ///
  /// In en, this message translates to:
  /// **'Walk'**
  String get walking;

  /// No description provided for @driving.
  ///
  /// In en, this message translates to:
  /// **'Drive'**
  String get driving;

  /// No description provided for @locationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Location unavailable'**
  String get locationUnavailable;

  /// No description provided for @locationUsingLastKnown.
  ///
  /// In en, this message translates to:
  /// **'Could not update location. Showing the last known position.'**
  String get locationUsingLastKnown;

  /// No description provided for @calculatingRoute.
  ///
  /// In en, this message translates to:
  /// **'Calculating route...'**
  String get calculatingRoute;

  /// No description provided for @routeError.
  ///
  /// In en, this message translates to:
  /// **'Could not calculate route'**
  String get routeError;

  /// No description provided for @retryRoute.
  ///
  /// In en, this message translates to:
  /// **'Retry route'**
  String get retryRoute;

  /// No description provided for @pageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get pageNotFound;

  /// No description provided for @backToNearby.
  ///
  /// In en, this message translates to:
  /// **'Nearby breweries'**
  String get backToNearby;

  /// No description provided for @openMenu.
  ///
  /// In en, this message translates to:
  /// **'Open menu'**
  String get openMenu;

  /// No description provided for @allBreweries.
  ///
  /// In en, this message translates to:
  /// **'All breweries'**
  String get allBreweries;

  /// No description provided for @catalogTitle.
  ///
  /// In en, this message translates to:
  /// **'World breweries'**
  String get catalogTitle;

  /// No description provided for @catalogLoadError.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load the brewery list.'**
  String get catalogLoadError;

  /// No description provided for @loadingBreweries.
  ///
  /// In en, this message translates to:
  /// **'Loading breweries...'**
  String get loadingBreweries;

  /// No description provided for @loadingMoreBreweries.
  ///
  /// In en, this message translates to:
  /// **'Loading more breweries...'**
  String get loadingMoreBreweries;

  /// No description provided for @noBreweries.
  ///
  /// In en, this message translates to:
  /// **'No breweries found.'**
  String get noBreweries;

  /// No description provided for @catalogNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No breweries match these search or filter settings.'**
  String get catalogNoMatches;

  /// No description provided for @catalogSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by brewery name'**
  String get catalogSearchHint;

  /// No description provided for @catalogSort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get catalogSort;

  /// No description provided for @catalogSortDefault.
  ///
  /// In en, this message translates to:
  /// **'Default order'**
  String get catalogSortDefault;

  /// No description provided for @catalogSortNameAscending.
  ///
  /// In en, this message translates to:
  /// **'Name (A-Z)'**
  String get catalogSortNameAscending;

  /// No description provided for @catalogSortNameDescending.
  ///
  /// In en, this message translates to:
  /// **'Name (Z-A)'**
  String get catalogSortNameDescending;

  /// No description provided for @catalogSortCity.
  ///
  /// In en, this message translates to:
  /// **'City (A-Z)'**
  String get catalogSortCity;

  /// No description provided for @catalogSortType.
  ///
  /// In en, this message translates to:
  /// **'Type (A-Z)'**
  String get catalogSortType;

  /// No description provided for @catalogFilters.
  ///
  /// In en, this message translates to:
  /// **'Filter by type'**
  String get catalogFilters;

  /// No description provided for @catalogFilterCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 type selected} other{{count} types selected}}'**
  String catalogFilterCount(num count);

  /// No description provided for @catalogApplyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get catalogApplyFilters;

  /// No description provided for @catalogClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get catalogClearFilters;

  /// No description provided for @catalogLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get catalogLoadMore;

  /// No description provided for @noNearbyBreweries.
  ///
  /// In en, this message translates to:
  /// **'No nearby breweries found.'**
  String get noNearbyBreweries;

  /// No description provided for @mapLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load nearby breweries.'**
  String get mapLoadError;

  /// No description provided for @searchError.
  ///
  /// In en, this message translates to:
  /// **'Could not search breweries.'**
  String get searchError;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission was denied.'**
  String get locationPermissionDenied;

  /// No description provided for @locationServiceDisabled.
  ///
  /// In en, this message translates to:
  /// **'Enable location services to find nearby breweries.'**
  String get locationServiceDisabled;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get theme;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get darkMode;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @spanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get spanish;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
