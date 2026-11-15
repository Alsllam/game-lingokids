import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/audio/sound_player.dart';
import '../../../../core/audio/speaker.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/mascot/mascot.dart';
import '../../../../core/widgets/kid_widgets.dart';
import '../../../catalog/domain/entities/catalog.dart';
import '../cubit/game_feedback.dart';
import '../cubit/game_session_cubit.dart';
import '../widgets/choice_game.dart';
import '../widgets/match_game.dart';
import '../widgets/memory_game.dart';
import '../widgets/result_overlay.dart';
import '../widgets/trace_game.dart';

/// Hosts any game template. It owns everything the templates share: the
/// mascot's reactions, sound effects, saving stars and the result screen.
/// A template only has to report "right", "wrong" and "finished".
class GamePage extends StatefulWidget {
  const GamePage({
    super.key,
    required this.activityId,
    required this.onCompleted,
  });

  final String activityId;

  /// Called with the earned stars (1-3) when the activity is finished. The
  /// app layer wires this to progress storage, so games stay independent of
  /// the progress feature.
  final ValueChanged<int> onCompleted;

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final MascotController _mascot = MascotController();

  /// Null while playing; the earned stars once the activity is finished.
  int? _result;

  /// Changing this rebuilds the template from scratch ("play again").
  int _run = 0;

  @override
  void dispose() {
    _mascot.dispose();
    super.dispose();
  }

  void _onFeedback(GameFeedback feedback) {
    final sound = context.read<SoundPlayer>();
    switch (feedback) {
      case GameFeedback.correct:
        sound.play(Sfx.correct);
        _mascot.play(MascotMood.cheer);
      case GameFeedback.wrong:
        sound.play(Sfx.wrong);
        _mascot.play(MascotMood.sad);
      case GameFeedback.finished:
        sound.play(Sfx.win);
        _mascot.play(MascotMood.cheer);
      case GameFeedback.prompt:
        _mascot.play(MascotMood.talk);
      case GameFeedback.none:
        break;
    }
  }

  void _onFinished(int stars) {
    context.read<Speaker>().stop();
    widget.onCompleted(stars);
    setState(() => _result = stars);
  }

  void _replay() {
    context.read<SoundPlayer>().play(Sfx.tap);
    setState(() {
      _result = null;
      _run++;
    });
  }

  void _leave() {
    context.read<SoundPlayer>().play(Sfx.tap);
    context.read<Speaker>().stop();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  Widget _buildTemplate(ActivityBundle bundle) {
    final key = ValueKey('${bundle.activity.id}#$_run');
    return switch (bundle.activity.type) {
      GameType.choice => ChoiceGame(
        key: key,
        bundle: bundle,
        onFeedback: _onFeedback,
        onFinished: _onFinished,
      ),
      GameType.memory => MemoryGame(
        key: key,
        bundle: bundle,
        onFeedback: _onFeedback,
        onFinished: _onFinished,
      ),
      GameType.match => MatchGame(
        key: key,
        bundle: bundle,
        onFeedback: _onFeedback,
        onFinished: _onFinished,
      ),
      GameType.trace => TraceGame(
        key: key,
        bundle: bundle,
        onFeedback: _onFeedback,
        onFinished: _onFinished,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final result = _result;
    return Scaffold(
      body: SceneBackground(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 120,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RoundIconButton(
                          icon: Icons.close_rounded,
                          label: l10n.close,
                          onTap: _leave,
                        ),
                        const Spacer(),
                        MascotView(controller: _mascot, size: 120),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: BlocBuilder<GameSessionCubit, GameSessionState>(
                      builder: (context, state) {
                        return switch (state) {
                          GameSessionLoading() => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          GameSessionFailed() => Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  l10n.activityNotFound,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 22),
                                ),
                                const SizedBox(height: AppSpacing.s16),
                                BigButton(label: l10n.back, onTap: _leave),
                              ],
                            ),
                          ),
                          GameSessionReady(:final bundle) => _buildTemplate(
                            bundle,
                          ),
                        };
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (result != null)
              ResultOverlay(
                key: ValueKey(_run),
                stars: result,
                onReplay: _replay,
                onDone: _leave,
              ),
          ],
        ),
      ),
    );
  }
}
