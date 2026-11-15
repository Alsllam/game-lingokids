import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';

/// Speaks words aloud so children who cannot read yet can play.
abstract interface class Speaker {
  bool get enabled;
  set enabled(bool value);

  /// Speaks [text] in the given language ('ar' or 'en'), interrupting
  /// whatever is being said.
  void speak(String text, {required String languageCode});

  void stop();
}

final class SilentSpeaker implements Speaker {
  @override
  bool enabled = true;

  final List<String> spoken = [];

  @override
  void speak(String text, {required String languageCode}) {
    if (enabled) spoken.add(text);
  }

  @override
  void stop() {}
}

/// Uses the phone's built-in text-to-speech engine, so no recordings are
/// needed. Swap for a recorded-audio implementation when voice-overs exist.
final class TtsSpeaker implements Speaker {
  TtsSpeaker({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;
  bool _configured = false;
  String? _language;

  @override
  bool enabled = true;

  @override
  void speak(String text, {required String languageCode}) {
    if (!enabled || text.trim().isEmpty) return;
    unawaited(_speak(text, languageCode));
  }

  Future<void> _speak(String text, String languageCode) async {
    try {
      if (!_configured) {
        await _tts.setSpeechRate(0.42);
        await _tts.setPitch(1.15);
        _configured = true;
      }
      if (_language != languageCode) {
        await _tts.setLanguage(languageCode == 'ar' ? 'ar' : 'en-US');
        _language = languageCode;
      }
      await _tts.stop();
      await _tts.speak(text);
    } on Object {
      // No TTS engine or voice installed: stay silent, keep playing.
    }
  }

  @override
  void stop() {
    unawaited(_stop());
  }

  Future<void> _stop() async {
    try {
      await _tts.stop();
    } on Object {
      // Ignored for the same reason as above.
    }
  }
}
