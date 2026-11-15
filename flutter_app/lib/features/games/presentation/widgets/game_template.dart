import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/widgets/kid_widgets.dart';
import '../cubit/game_feedback.dart';

/// What every game template reports back to the screen that hosts it.
///
/// To add a new template: build a widget that takes an `ActivityBundle` and
/// these two callbacks, then register it in `GamePage._buildTemplate`.
typedef GameFeedbackCallback = void Function(GameFeedback feedback);
typedef GameFinishedCallback = void Function(int stars);

/// The instruction strip shown at the top of each game.
class PromptBar extends StatelessWidget {
  const PromptBar({super.key, required this.text, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return KidCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s8,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: tokens.ink,
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.s12),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// Small dots showing which round the child is on.
class RoundDots extends StatelessWidget {
  const RoundDots({super.key, required this.total, required this.current});

  final int total;
  final int current;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Semantics(
      label: '${current + 1} / $total',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < total; i++)
            AnimatedContainer(
              duration: tokens.motionMedium,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == current ? 18 : 10,
              height: 10,
              decoration: BoxDecoration(
                color: i < current
                    ? tokens.success
                    : i == current
                    ? tokens.primary
                    : tokens.card.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
        ],
      ),
    );
  }
}
