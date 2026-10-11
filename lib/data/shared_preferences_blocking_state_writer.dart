import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/blocking.dart';

/// Writes the blocking state to shared preferences, where the Android
/// services read it from `FlutterSharedPreferences` (key
/// `flutter.blocking.state.v1`) without Flutter running.
class SharedPreferencesBlockingStateWriter implements BlockingStateWriter {
  SharedPreferencesBlockingStateWriter(this._preferences);

  static const key = 'blocking.state.v1';

  final SharedPreferences _preferences;

  @override
  Future<void> write(BlockingState state) async {
    await _preferences.setString(
      key,
      jsonEncode({
        'v': 1,
        'active': state.active,
        'packages': state.packageNames.toList()..sort(),
        'plannedEndMillis': state.plannedEnd?.millisecondsSinceEpoch,
        'focusTimes': [
          for (final time in state.focusTimes)
            {
              'weekdays': time.weekdays.toList()..sort(),
              'start': time.startMinute,
              'end': time.endMinute,
              if (state.focusTimePackages[time.id] case final packages?)
                'packages': packages.toList()..sort(),
            },
        ],
        // Optional since #119; read as false when missing.
        if (state.mindfulOpening) 'mindful': true,
      }),
    );
  }
}
