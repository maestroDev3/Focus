import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/data/shared_preferences_session_repository.dart';
import 'package:focus_timer/domain/focus_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/sample_sessions.dart';

void main() {
  late SharedPreferences preferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
  });

  group('SharedPreferencesSessionRepository', () {
    test('saves, loads and clears the active session', () async {
      final repository = SharedPreferencesSessionRepository(preferences);

      expect(await repository.loadActive(), isNull);

      await repository.saveActive(pausedSample());
      expect(await repository.loadActive(), pausedSample());

      await repository.saveActive(null);
      expect(await repository.loadActive(), isNull);
    });

    test('emits the finished sessions and every addition', () async {
      final repository = SharedPreferencesSessionRepository(preferences);
      final emitted = <List<FocusSession>>[];
      final subscription = repository.watchFinished().listen(emitted.add);
      addTearDown(subscription.cancel);

      await Future<void>.delayed(Duration.zero);
      await repository.addFinished(completedSample());
      await Future<void>.delayed(Duration.zero);
      await repository.addFinished(cancelledSample());
      await Future<void>.delayed(Duration.zero);

      expect(emitted, [
        <FocusSession>[],
        [completedSample()],
        [completedSample(), cancelledSample()],
      ]);
    });

    test('persists data for a new repository instance', () async {
      await SharedPreferencesSessionRepository(preferences)
        ..saveActive(runningSample())
        ..addFinished(completedSample());
      await Future<void>.delayed(Duration.zero);

      final reopened = SharedPreferencesSessionRepository(preferences);

      expect(await reopened.loadActive(), runningSample());
      expect(await reopened.watchFinished().first, [completedSample()]);
    });

    test('rejects stored data with an unknown version', () async {
      SharedPreferences.setMockInitialValues({
        'sessions.active.v1': '{"v":99}',
      });
      final repository = SharedPreferencesSessionRepository(
        await SharedPreferences.getInstance(),
      );

      expect(repository.loadActive(), throwsFormatException);
    });
  });
}
