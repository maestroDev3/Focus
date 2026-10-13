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
        // One rule per range (#247): the native side needs no ranges.
        'focusTimes': [
          for (final time in state.focusTimes)
            for (final range in time.ranges)
              {
                'weekdays': range.weekdays.toList()..sort(),
                'start': range.startMinute,
                'end': range.endMinute,
                if (state.focusTimePackages[time.id] case final packages?)
                  'packages': packages.toList()..sort(),
              },
        ],
        // Optional since #119; read as false when missing.
        if (state.mindfulOpening) 'mindful': true,
        if (state.mindfulOpening)
          'mindfulPackages': state.mindfulPackages.toList()..sort(),
      }),
    );
  }
}
