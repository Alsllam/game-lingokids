import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

/// The app's sound effects. File names live in `assets/audio/`.
enum Sfx {
  tap('tap.wav'),
  flip('flip.wav'),
  correct('correct.wav'),
  wrong('wrong.wav'),
  star('star.wav'),
  win('win.wav');

  const Sfx(this.fileName);

  final String fileName;
}

/// Plays short sound effects. Screens depend on this interface so tests and
/// previews can use [SilentSoundPlayer].
abstract interface class SoundPlayer {
  bool get enabled;
  set enabled(bool value);

  void play(Sfx sfx);

  Future<void> dispose();
}

final class SilentSoundPlayer implements SoundPlayer {
  @override
  bool enabled = true;

  final List<Sfx> played = [];

  @override
  void play(Sfx sfx) {
    if (enabled) played.add(sfx);
  }

  @override
  Future<void> dispose() async {}
}

/// One reusable player per effect, so different effects can overlap (a star
/// chime over the win fanfare) while the same effect restarts cleanly.
final class AssetSoundPlayer implements SoundPlayer {
  @override
  bool enabled = true;

  final Map<Sfx, AudioPlayer> _players = {};

  @override
  void play(Sfx sfx) {
    if (!enabled) return;
    unawaited(_play(sfx));
  }

  Future<void> _play(Sfx sfx) async {
    try {
      var player = _players[sfx];
      if (player == null) {
        player = AudioPlayer();
        await player.setReleaseMode(ReleaseMode.stop);
        _players[sfx] = player;
      }
      await player.stop();
      await player.play(AssetSource('audio/${sfx.fileName}'));
    } on Object {
      // A missing audio device must never break a game.
    }
  }

  @override
  Future<void> dispose() async {
    for (final player in _players.values) {
      await player.dispose();
    }
    _players.clear();
  }
}
