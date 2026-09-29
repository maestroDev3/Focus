/// The part of the day, used to greet the user fittingly.
enum DayPart { morning, afternoon, evening }

/// Returns the [DayPart] of [moment]: morning 05–12, afternoon 12–18,
/// evening 18–05.
DayPart dayPartOf(DateTime moment) => switch (moment.hour) {
  >= 5 && < 12 => DayPart.morning,
  >= 12 && < 18 => DayPart.afternoon,
  _ => DayPart.evening,
};
