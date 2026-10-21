/// The living background behind Focus' main screens (#316): five calm
/// branching styles, or none (only the soft glow).
enum BackgroundStyle {
  fiveStems,
  dense,
  roots,
  twoTrees,
  mesh,
  none;

  /// Shown until the user picks another style.
  static const initial = BackgroundStyle.roots;
}
