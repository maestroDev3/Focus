import '../domain/background_style.dart';
import '../l10n/app_localizations.dart';

/// The name of a background style, e.g. “Roots”.
String backgroundName(AppLocalizations l10n, BackgroundStyle style) =>
    switch (style) {
      BackgroundStyle.fiveStems => l10n.backgroundFiveStems,
      BackgroundStyle.dense => l10n.backgroundDense,
      BackgroundStyle.roots => l10n.backgroundRoots,
      BackgroundStyle.twoTrees => l10n.backgroundTwoTrees,
      BackgroundStyle.mesh => l10n.backgroundMesh,
      BackgroundStyle.none => l10n.backgroundNone,
    };
