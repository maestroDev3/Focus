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

  /// The current value of [field] in minutes (or sessions).
  int valueOf(PomodoroField field) => switch (field) {
    PomodoroField.focus => focus.inMinutes,
    PomodoroField.shortBreak => shortBreak.inMinutes,
    PomodoroField.longBreak => longBreak.inMinutes,
    PomodoroField.sessionsBeforeLongBreak => sessionsBeforeLongBreak,
  };

  /// Sets [field] to a typed [value], clamped to the field's limits.
  PomodoroSettings withValue(PomodoroField field, int value) {
    final clamped = value.clamp(field.min, field.max);
    return switch (field) {
      PomodoroField.focus => copyWith(focus: Duration(minutes: clamped)),
      PomodoroField.shortBreak => copyWith(
        shortBreak: Duration(minutes: clamped),
      ),
      PomodoroField.longBreak => copyWith(
        longBreak: Duration(minutes: clamped),
      ),
      PomodoroField.sessionsBeforeLongBreak => copyWith(
        sessionsBeforeLongBreak: clamped,
      ),
    };
  }

  /// Moves [field] one step up or down within its limits: focus in 5 min
  /// steps, breaks and sessions in steps of one.
  PomodoroSettings step(PomodoroField field, {required bool up}) =>
      withValue(field, valueOf(field) + (up ? field.step : -field.step));

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

/// A setting the user can change in steps or by typing a value.
enum PomodoroField {
  focus(min: 1, max: 180, step: 5),
  shortBreak(min: 1, max: 60, step: 1),
  longBreak(min: 1, max: 60, step: 1),
  sessionsBeforeLongBreak(min: 2, max: 8, step: 1);

  const PomodoroField({
    required this.min,
    required this.max,
    required this.step,
  });

  /// Limits in minutes (sessions for [sessionsBeforeLongBreak]).
  final int min;
  final int max;

  /// Change per tap on + or −.
  final int step;
}

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
