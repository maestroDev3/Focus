import 'package:flutter/material.dart';

import '../domain/ambient.dart';
import '../l10n/app_localizations.dart';

/// The calm name of an ambient sound.
String ambientSoundName(AppLocalizations l10n, AmbientSound sound) =>
    switch (sound) {
      AmbientSound.off => l10n.ambientOff,
      AmbientSound.rain => l10n.ambientRain,
      AmbientSound.softNoise => l10n.ambientSoftNoise,
      AmbientSound.deepNoise => l10n.ambientDeepNoise,
      AmbientSound.fireplace => l10n.ambientFireplace,
    };

/// Bottom sheet to choose the ambient sound and its volume; every change is
/// reported at once, so it can be saved and previewed.
class AmbientSheet extends StatefulWidget {
  const AmbientSheet({
    super.key,
    required this.initial,
    required this.onChanged,
  });

  final AmbientChoice initial;
  final ValueChanged<AmbientChoice> onChanged;

  @override
  State<AmbientSheet> createState() => _AmbientSheetState();
}

class _AmbientSheetState extends State<AmbientSheet> {
  late var _choice = widget.initial;

  void _change(AmbientChoice choice) {
    setState(() => _choice = choice);
    widget.onChanged(choice);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final sound in AmbientSound.values)
              ListTile(
                title: Text(ambientSoundName(l10n, sound)),
                trailing: sound == _choice.sound
                    ? Icon(Icons.check, color: theme.colorScheme.primary)
                    : null,
                onTap: () => _change(
                  AmbientChoice(sound: sound, volume: _choice.volume),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                l10n.ambientVolume,
                style: theme.textTheme.titleSmall,
              ),
            ),
            Slider(
              value: _choice.volume,
              onChanged: (volume) => setState(
                () => _choice = AmbientChoice(
                  sound: _choice.sound,
                  volume: volume,
                ),
              ),
              onChangeEnd: (volume) => _change(
                AmbientChoice(sound: _choice.sound, volume: volume),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
