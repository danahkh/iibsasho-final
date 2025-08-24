// Flutter web plugin registrant file.
// Manually added because automatic generation was missing, causing:
// "Bad state: Could not find summary for library 'org-dartlang-app:/web_plugin_registrant.dart'" during hot restart.
// If Flutter later auto-generates this file, you can remove this manual version.

import 'package:flutter_web_plugins/flutter_web_plugins.dart';


// Other plugins
import 'package:url_launcher_web/url_launcher_web.dart';
import 'package:shared_preferences_web/shared_preferences_web.dart';
import 'package:image_picker_for_web/image_picker_for_web.dart';
import 'package:app_links_web/app_links_web.dart';

// NOTE: Keep this list in sync with web-capable plugins in pubspec.yaml.
// If you add/remove plugins, update and hot-restart (or full restart) the app.

void registerPlugins([final Registrar? registrar]) {
  final Registrar r = registrar ?? webPluginRegistrar;
  UrlLauncherPlugin.registerWith(r);
  SharedPreferencesPlugin.registerWith(r);
  ImagePickerPlugin.registerWith(r);
  AppLinksPlugin.registerWith(r);
  r.registerMessageHandler();
}

// Backwards compatibility alias expected by some older tooling.
void register_web_plugin_registrant() => registerPlugins();
