/// The next free number for ids like `prefix-7`, above [counter] and every
/// number already used in [ids], so restored ids are never handed out again.
int nextFreeIdNumber(int counter, Iterable<String> ids) => [
  counter,
  for (final id in ids) (int.tryParse(id.split('-').last) ?? 0) + 1,
].reduce((a, b) => a > b ? a : b);

/// Throws [ArgumentError] if [time] overlaps any other focus time in [times]
/// (the one with the same id is ignored).
void checkNoOverlap(List<FocusTime> times, FocusTime time) {
  for (final other in times) {
    if (other.id != time.id && overlaps(other, time)) {
      throw ArgumentError('The focus time overlaps another one.');
    }
  }
}
