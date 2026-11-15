import 'package:flutter/widgets.dart';

import '../../l10n/generated/app_localizations.dart';

export '../../l10n/generated/app_localizations.dart';

extension L10nContext on BuildContext {
  /// Shortcut for the generated strings: `context.l10n.appTitle`.
  AppLocalizations get l10n => AppLocalizations.of(this);
}
