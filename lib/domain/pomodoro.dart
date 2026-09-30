/// The Pomodoro rhythm the user configured.
class PomodoroSettings {
  const PomodoroSettings({
    this.focus = const Duration(minutes: 25),
    this.shortBreak = const Duration(minutes: 5),
    this.longBreak = const Duration(minutes: 15),
    this.sessionsBeforeLongBreak = 4,
  });

  final Duration focus;
  final Duration shortBreak;
  final Duration longBreak;
  final int sessionsBeforeLongBreak;

  /// Throws [ArgumentError] unless every duration is at least one minute and
  /// at least one session comes before a long break.
  PomodoroSettings validate() {
    for (final (name, value) in [
      ('focus', focus),
      ('shortBreak', shortBreak),
      ('longBreak', longBreak),
    ]) {
      if (value < const Duration(minutes: 1)) {
        throw ArgumentError.value(value, name, 'must be at least 1 minute');
      }
    }
    if (sessionsBeforeLongBreak < 1) {
      throw ArgumentError.value(
        sessionsBeforeLongBreak,
        'sessionsBeforeLongBreak',
        'must be at least 1',
      );
    }
    return this;
  }

  /// Returns validated settings with the given values changed.
  PomodoroSettings copyWith({
    Duration? focus,
    Duration? shortBreak,
    Duration? longBreak,
    int? sessionsBeforeLongBreak,
  }) {
    return PomodoroSettings(
      focus: focus ?? this.focus,
      shortBreak: shortBreak ?? this.shortBreak,
      longBreak: longBreak ?? this.longBreak,
      sessionsBeforeLongBreak:
          sessionsBeforeLongBreak ?? this.sessionsBeforeLongBreak,
    ).validate();
  }

  /// Moves [field] one step up or down within its limits: focus 5–180 min
  /// in 5 min steps, breaks 1–60 min, 2–8 sessions before a long break.
  PomodoroSettings step(PomodoroField field, {required bool up}) {
    int next(int value, int step, int min, int max) =>
        (value + (up ? step : -step)).clamp(min, max);
    Duration minutes(Duration value, int step, int min, int max) =>
        Duration(minutes: next(value.inMinutes, step, min, max));

    return switch (field) {
      PomodoroField.focus => copyWith(focus: minutes(focus, 5, 5, 180)),
      PomodoroField.shortBreak => copyWith(
        shortBreak: minutes(shortBreak, 1, 1, 60),
      ),
      PomodoroField.longBreak => copyWith(
        longBreak: minutes(longBreak, 1, 1, 60),
      ),
      PomodoroField.sessionsBeforeLongBreak => copyWith(
        sessionsBeforeLongBreak: next(sessionsBeforeLongBreak, 1, 2, 8),
      ),
    };
  }

  @override
  bool operator ==(Object other) =>
      other is PomodoroSettings &&
      other.focus == focus &&
      other.shortBreak == shortBreak &&
      other.longBreak == longBreak &&
      other.sessionsBeforeLongBreak == sessionsBeforeLongBreak;

  @override
  int get hashCode =>
      Object.hash(focus, shortBreak, longBreak, sessionsBeforeLongBreak);
}

/// A setting the user can change in steps.
enum PomodoroField { focus, shortBreak, longBreak, sessionsBeforeLongBreak }

/// Kind of break following a completed focus session.
enum BreakKind { short, long }

/// Every [PomodoroSettings.sessionsBeforeLongBreak]-th completed session of
/// the day is followed by a long break, all others by a short one.
BreakKind breakAfter({
  required int completedToday,
  required PomodoroSettings settings,
}) {
  return completedToday > 0 &&
          completedToday % settings.sessionsBeforeLongBreak == 0
      ? BreakKind.long
      : BreakKind.short;
}

/// Planned length of a break of [kind].
Duration breakDuration(BreakKind kind, PomodoroSettings settings) =>
    switch (kind) {
      BreakKind.short => settings.shortBreak,
      BreakKind.long => settings.longBreak,
    };
