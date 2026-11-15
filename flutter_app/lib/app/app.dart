import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/audio/sound_player.dart';
import '../core/audio/speaker.dart';
import '../core/l10n/l10n.dart';
import '../features/catalog/presentation/catalog_cubit.dart';
import '../features/progress/presentation/progress_cubit.dart';
import '../features/settings/domain/app_settings.dart';
import '../features/settings/presentation/settings_cubit.dart';
import 'di/injection.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final GoRouter _router = buildRouter();
  late final ThemeData _theme = AppTheme.build();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<SoundPlayer>.value(value: getIt<SoundPlayer>()),
        RepositoryProvider<Speaker>.value(value: getIt<Speaker>()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => getIt<SettingsCubit>()),
          BlocProvider(
            lazy: false,
            create: (_) => getIt<CatalogCubit>()..load(),
          ),
          BlocProvider(
            lazy: false,
            create: (_) => getIt<ProgressCubit>()..load(),
          ),
        ],
        child: BlocBuilder<SettingsCubit, AppSettings>(
          buildWhen: (previous, current) =>
              previous.languageCode != current.languageCode,
          builder: (context, settings) {
            return MaterialApp.router(
              debugShowCheckedModeBanner: false,
              onGenerateTitle: (context) => context.l10n.appTitle,
              theme: _theme,
              locale: Locale(settings.languageCode),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              routerConfig: _router,
            );
          },
        ),
      ),
    );
  }
}
