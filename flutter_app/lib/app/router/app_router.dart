import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/catalog/presentation/pages/home_page.dart';
import '../../features/catalog/presentation/pages/topic_page.dart';
import '../../features/games/presentation/cubit/game_session_cubit.dart';
import '../../features/games/presentation/pages/game_page.dart';
import '../../features/progress/presentation/progress_cubit.dart';
import '../../features/settings/presentation/parents_page.dart';
import '../di/injection.dart';

abstract final class Routes {
  static const home = '/';
  static const topic = '/topic/:topicId';
  static const play = '/play/:activityId';
  static const parents = '/parents';
}

/// The router is also where features are connected to each other: pages get
/// stars and callbacks from here, so no feature imports another feature's
/// screens or cubits.
GoRouter buildRouter() {
  return GoRouter(
    initialLocation: Routes.home,
    routes: [
      GoRoute(
        path: Routes.home,
        builder: (context, state) => BlocBuilder<ProgressCubit, ProgressState>(
          builder: (context, progress) => HomePage(stars: progress.stars),
        ),
      ),
      GoRoute(
        path: Routes.topic,
        builder: (context, state) {
          final topicId = state.pathParameters['topicId'] ?? '';
          return BlocBuilder<ProgressCubit, ProgressState>(
            builder: (context, progress) =>
                TopicPage(topicId: topicId, stars: progress.stars),
          );
        },
      ),
      GoRoute(
        path: Routes.play,
        builder: (context, state) {
          final activityId = state.pathParameters['activityId'] ?? '';
          return BlocProvider(
            create: (_) => getIt<GameSessionCubit>()..load(activityId),
            child: GamePage(
              activityId: activityId,
              onCompleted: (stars) => context.read<ProgressCubit>().record(
                activityId: activityId,
                stars: stars,
              ),
            ),
          );
        },
      ),
      GoRoute(
        path: Routes.parents,
        builder: (context, state) => ParentsPage(
          onResetProgress: () => context.read<ProgressCubit>().reset(),
        ),
      ),
    ],
  );
}
