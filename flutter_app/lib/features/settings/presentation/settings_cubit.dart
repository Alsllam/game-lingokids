import 'package:bloc/bloc.dart';

import '../../../core/audio/sound_player.dart';
import '../../../core/audio/speaker.dart';
import '../domain/app_settings.dart';

/// App-wide settings: language and audio switches.
///
/// The audio services are switched here, in one place, so no game has to
/// check the settings before making a sound.
final class SettingsCubit extends Cubit<AppSettings> {
  SettingsCubit({
    required SettingsRepository repository,
    required SoundPlayer soundPlayer,
    required Speaker speaker,
  }) : _repository = repository,
       _soundPlayer = soundPlayer,
       _speaker = speaker,
       super(repository.load()) {
    _apply(state);
  }

  final SettingsRepository _repository;
  final SoundPlayer _soundPlayer;
  final Speaker _speaker;

  Future<void> setLanguage(String languageCode) =>
      _update(state.copyWith(languageCode: languageCode));

  Future<void> setSfx({required bool on}) => _update(state.copyWith(sfxOn: on));

  Future<void> setVoice({required bool on}) =>
      _update(state.copyWith(voiceOn: on));

  Future<void> _update(AppSettings next) async {
    if (next == state) return;
    _apply(next);
    emit(next);
    await _repository.save(next);
  }

  void _apply(AppSettings settings) {
    _soundPlayer.enabled = settings.sfxOn;
    _speaker.enabled = settings.voiceOn;
    if (!settings.voiceOn) _speaker.stop();
  }
}
