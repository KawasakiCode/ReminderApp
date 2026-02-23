//The provider that loads and changes global settings like dark mode, language. 
//used only for settings within the settings page

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

enum RecommendationPreference {balanced, recentlyActive}

class SettingsProvider extends ChangeNotifier {
  final SharedPreferences _prefs;

  //The provider when initialized loads data from disk or if disk is empty loads the defaults
  SettingsProvider(this._prefs);
}