import 'package:injectable/injectable.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

import '../../domain/services/website_launcher.dart';

@LazySingleton(as: WebsiteLauncher)
class UrlLauncherWebsiteLauncher implements WebsiteLauncher {
  @override
  Future<void> launch(Uri uri) async {
    await url_launcher.launchUrl(
      uri,
      mode: url_launcher.LaunchMode.externalApplication,
    );
  }
}
