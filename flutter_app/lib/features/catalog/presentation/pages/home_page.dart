import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/audio/sound_player.dart';
import '../../../../core/audio/speaker.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/mascot/mascot.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/widgets/item_visual_view.dart';
import '../../../../core/widgets/kid_widgets.dart';
import '../../domain/entities/catalog.dart';
import '../catalog_cubit.dart';

/// The first screen: the mascot says hello and the child picks a world.
class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.stars});

  /// Stars earned per activity id, provided by the app layer.
  final Map<String, int> stars;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MascotController _mascot = MascotController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _greet();
    });
  }

  @override
  void dispose() {
    _mascot.dispose();
    super.dispose();
  }

  void _greet() {
    _mascot.play(MascotMood.wave);
    context.read<Speaker>().speak(
      context.l10n.greeting,
      languageCode: context.languageCode,
    );
  }

  void _open(String location) {
    context.read<SoundPlayer>().play(Sfx.tap);
    context.read<Speaker>().stop();
    context.push(location);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = context.tokens;
    final totalStars = widget.stars.values.fold(0, (sum, value) => sum + value);

    return Scaffold(
      body: SceneBackground(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    l10n.appTitle,
                    style: TextStyle(
                      fontSize: 34,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      color: tokens.ink,
                    ),
                  ),
                  const Spacer(),
                  _StarsChip(text: l10n.totalStars(totalStars)),
                  const SizedBox(width: AppSpacing.s12),
                  RoundIconButton(
                    icon: Icons.lock_rounded,
                    label: l10n.parentsArea,
                    size: 48,
                    onTap: () => _open('/parents'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s8),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 170,
                      // Scales the whole group down on very short screens
                      // instead of overflowing.
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.bottomCenter,
                        child: SizedBox(
                          width: 170,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _SpeechBubble(text: l10n.greeting),
                              const SizedBox(height: AppSpacing.s4),
                              Pressable(
                                onTap: () {
                                  _mascot.play(MascotMood.cheer);
                                  context.read<SoundPlayer>().play(Sfx.star);
                                },
                                semanticLabel: l10n.greeting,
                                child: MascotView(
                                  controller: _mascot,
                                  size: 150,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    Expanded(
                      child: BlocBuilder<CatalogCubit, CatalogState>(
                        builder: (context, state) {
                          final catalog = state.catalog;
                          if (state.status == CatalogStatus.loading) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (catalog == null) {
                            return _LoadError(
                              onRetry: () =>
                                  context.read<CatalogCubit>().load(),
                            );
                          }
                          return _TopicList(
                            topics: catalog.topics,
                            stars: widget.stars,
                            onOpen: (topic) => _open('/topic/${topic.id}'),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopicList extends StatelessWidget {
  const _TopicList({
    required this.topics,
    required this.stars,
    required this.onOpen,
  });

  final List<Topic> topics;
  final Map<String, int> stars;
  final ValueChanged<Topic> onOpen;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardHeight = (constraints.maxHeight - 28).clamp(120.0, 300.0);
        final cardWidth = cardHeight * 0.82;
        return Center(
          child: SizedBox(
            height: cardHeight + 28,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s8,
                vertical: AppSpacing.s8,
              ),
              itemCount: topics.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s16),
              itemBuilder: (context, index) {
                final topic = topics[index];
                final earned = topic.activities.fold(
                  0,
                  (sum, activity) => sum + (stars[activity.id] ?? 0),
                );
                return SizedBox(
                  width: cardWidth,
                  child: PopIn(
                    delay: Duration(milliseconds: 80 * index.clamp(0, 8)),
                    child: _TopicCard(
                      topic: topic,
                      earned: earned,
                      possible: topic.activities.length * 3,
                      onTap: () => onOpen(topic),
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

class _TopicCard extends StatelessWidget {
  const _TopicCard({
    required this.topic,
    required this.earned,
    required this.possible,
    required this.onTap,
  });

  final Topic topic;
  final int earned;
  final int possible;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = topic.title.of(context.languageCode);
    return Pressable(
      onTap: onTap,
      semanticLabel: title,
      child: KidCard(
        color: Color(topic.color),
        child: Column(
          children: [
            Expanded(child: ItemVisualView(visual: topic.icon)),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 24,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s8,
                  vertical: 2,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  textDirection: TextDirection.ltr,
                  children: [
                    const StarIcon(filled: true, size: 18),
                    const SizedBox(width: AppSpacing.s4),
                    Text(
                      '$earned / $possible',
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: context.tokens.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StarsChip extends StatelessWidget {
  const _StarsChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s12,
          vertical: AppSpacing.s4,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const StarIcon(filled: true, size: 24),
            const SizedBox(width: AppSpacing.s8),
            Text(
              text,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: tokens.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return PopIn(
      delay: const Duration(milliseconds: 400),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.card,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s12,
            vertical: AppSpacing.s8,
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              height: 1.25,
              fontWeight: FontWeight.w600,
              color: tokens.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.loadError,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(height: AppSpacing.s16),
          BigButton(
            label: l10n.retry,
            icon: Icons.refresh_rounded,
            onTap: onRetry,
          ),
        ],
      ),
    );
  }
}
