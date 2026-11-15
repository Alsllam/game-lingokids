import 'package:get_it/get_it.dart';

import 'presentation/cubit/game_session_cubit.dart';

void registerGames(GetIt getIt) {
  getIt.registerFactory(() => GameSessionCubit(getIt()));
}
