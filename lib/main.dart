import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/shared_preferences_label_repository.dart';
import 'data/shared_preferences_session_repository.dart';
import 'data/shared_preferences_settings_repository.dart';
import 'domain/focus_timer.dart';
import 'ui/focus_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final timer = FocusTimer(
    repository: SharedPreferencesSessionRepository(preferences),
    clock: DateTime.now,
  );
  runApp(
    FocusApp(
      timer: timer,
      settings: SharedPreferencesSettingsRepository(preferences),
      labels: SharedPreferencesLabelRepository(preferences),
    ),
  );
}
