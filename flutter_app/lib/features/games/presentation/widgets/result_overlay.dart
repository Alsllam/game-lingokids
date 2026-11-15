import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/audio/sound_player.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/motion/confetti.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/widgets/kid_widgets.dart';

/// The celebration shown when an activity ends: confetti, stars that pop in
/// one by one (each with a chime), and the two choices a child needs.
class ResultOverlay extends StatefulWidget {
  const ResultOverlay({
    super.key,
    required this.stars,
    required this.onReplay,
    required this.onDone,
  });

  final int stars;
  final VoidCallback onReplay;
  final VoidCallback onDone;

  @override
  State<ResultOverlay> createState() => _ResultOverlayState();
}

class _ResultOverlayState extends State<ResultOverlay> {
  static const _firstStarAt = Duration(milliseconds: 500);
  static const _starGap = Duration(milliseconds: 380);

  @override
  void initState() {
    super.initState();
    final sound = context.read<SoundPlayer>();
    for (var i = 0; i < widget.stars; i++) {
      Future<void>.delayed(_firstStarAt + _starGap * i, () {
        if (mounted) sound.play(Sfx.star);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    final title = switch (widget.stars) {
      >= 3 => l10n.resultGreat,
      2 => l10n.resultGood,
      _ => l10n.resultTry,
    };

    return Stack(
      fit: StackFit.expand,
      children: [
        // Blocks taps on the finished game underneath.
        ModalBarrier(
          dismissible: false,
          color: tokens.ink.withValues(alpha: 0.45),
        ),
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: PopIn(
              child: KidCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s32,
                  vertical: AppSpacing.s16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: tokens.ink,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    Semantics(
                      label: '${widget.stars} / 3',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        textDirection: TextDirection.ltr,
                        children: [
                          for (var i = 0; i < 3; i++)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.s4,
                              ),
                              child: i < widget.stars
                                  ? PopIn(
                                      delay: _firstStarAt + _starGap * i,
                                      duration: const Duration(
                                        milliseconds: 600,
                                      ),
                                      child: const StarIcon(
                                        filled: true,
                                        size: 72,
                                      ),
                                    )
                                  : const StarIcon(filled: false, size: 72),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    Wrap(
                      spacing: AppSpacing.s16,
                      runSpacing: AppSpacing.s12,
                      alignment: WrapAlignment.center,
                      children: [
                        BigButton(
                          label: l10n.playAgain,
                          icon: Icons.replay_rounded,
                          onTap: widget.onReplay,
                        ),
                        BigButton(
                          label: l10n.done,
                          icon: Icons.check_rounded,
                          color: tokens.success,
                          onTap: widget.onDone,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const ConfettiBurst(),
      ],
    );
  }
}
