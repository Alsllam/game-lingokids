import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/audio/sound_player.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/widgets/item_visual_view.dart';
import '../../../../core/widgets/kid_widgets.dart';
import '../../domain/entities/catalog.dart';
import '../catalog_cubit.dart';

/// Lists the games of one world.
class TopicPage extends StatelessWidget {
  const TopicPage({super.key, required this.topicId, required this.stars});

  final String topicId;
  final Map<String, int> stars;

  void _back(BuildContext context) {
    context.read<SoundPlayer>().play(Sfx.tap);
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = context.tokens;
    final topic = context.select<CatalogCubit, Topic?>(
      (cubit) => cubit.state.catalog?.topicById(topicId),
    );

    return Scaffold(
      body: SceneBackground(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  RoundIconButton(
                    icon: Icons.arrow_back_rounded,
                    label: l10n.back,
                    onTap: () => _back(context),
                  ),
                  const SizedBox(width: AppSpacing.s16),
                  if (topic != null) ...[
                    SizedBox.square(
                      dimension: 52,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(topic.color),
                          shape: BoxShape.circle,
                        ),
                        child: ItemVisualView(visual: topic.icon),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s12),
                    Expanded(
                      child: Text(
                        topic.title.of(context.languageCode),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 32,
                          height: 1.1,
                          fontWeight: FontWeight.w800,
                          color: tokens.ink,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.s8),
              Expanded(
                child: topic == null
                    ? Center(
                        child: Text(
                          l10n.activityNotFound,
                          style: const TextStyle(fontSize: 22),
                        ),
                      )
                    : _ActivityList(topic: topic, stars: stars),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityList extends StatelessWidget {
  const _ActivityList({required this.topic, required this.stars});

  final Topic topic;
  final Map<String, int> stars;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardHeight = (constraints.maxHeight - 28).clamp(120.0, 280.0);
        return Center(
          child: SizedBox(
            height: cardHeight + 28,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              clipBehavior: Clip.none,
              padding: const EdgeInsets.all(AppSpacing.s8),
              itemCount: topic.activities.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s16),
              itemBuilder: (context, index) {
                final activity = topic.activities[index];
                return SizedBox(
                  width: cardHeight * 0.9,
                  child: PopIn(
                    delay: Duration(milliseconds: 80 * index.clamp(0, 8)),
                    child: _ActivityCard(
                      activity: activity,
                      accent: Color(topic.color),
                      stars: stars[activity.id] ?? 0,
                      onTap: () {
                        context.read<SoundPlayer>().play(Sfx.tap);
                        context.push('/play/${activity.id}');
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.activity,
    required this.accent,
    required this.stars,
    required this.onTap,
  });

  final Activity activity;
  final Color accent;
  final int stars;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = context.tokens;
    final (icon, fallbackTitle) = switch (activity.type) {
      GameType.choice => (Icons.touch_app_rounded, l10n.gameChoice),
      GameType.memory => (Icons.grid_view_rounded, l10n.gameMemory),
      GameType.match => (Icons.swipe_rounded, l10n.gameMatch),
    };
    final title = activity.title?.of(context.languageCode) ?? fallbackTitle;

    return Pressable(
      onTap: onTap,
      semanticLabel: title,
      child: KidCard(
        edgeColor: accent,
        child: Column(
          children: [
            Expanded(
              child: FittedBox(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.s8),
                  child: Icon(icon, color: accent),
                ),
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 24,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  color: tokens.ink,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
            StarRow(stars: stars, size: 28),
          ],
        ),
      ),
    );
  }
}
