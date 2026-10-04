/// The next free number for ids like `prefix-7`, above [counter] and every
/// number already used in [ids], so restored ids are never handed out again.
int nextFreeIdNumber(int counter, Iterable<String> ids) => [
  counter,
  for (final id in ids) (int.tryParse(id.split('-').last) ?? 0) + 1,
].reduce((a, b) => a > b ? a : b);
