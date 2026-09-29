/// Supplies the current time so logic never calls `DateTime.now()` directly
/// and tests can pin time to fixed values.
typedef Clock = DateTime Function();

/// Normalizes [moment] to its calendar day as UTC midnight, so comparing and
/// subtracting days is never shifted by daylight saving time.
DateTime dayOf(DateTime moment) =>
    DateTime.utc(moment.year, moment.month, moment.day);
