import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/kid_widgets.dart';
import '../domain/app_settings.dart';
import 'settings_cubit.dart';

/// Settings for grown-ups, behind a small multiplication question that a
/// young child cannot answer by accident.
class ParentsPage extends StatefulWidget {
  const ParentsPage({super.key, required this.onResetProgress});

  /// Clears all stars; returns true on success. Provided by the app layer.
  final Future<bool> Function() onResetProgress;

  @override
  State<ParentsPage> createState() => _ParentsPageState();
}

class _ParentsPageState extends State<ParentsPage> {
  final Random _random = Random();
  bool _unlocked = false;
  bool _wrong = false;
  late int _a;
  late int _b;
  late List<int> _answers;

  @override
  void initState() {
    super.initState();
    _newQuestion();
  }

  void _newQuestion() {
    _a = 3 + _random.nextInt(6);
    _b = 3 + _random.nextInt(6);
    final correct = _a * _b;
    final answers = <int>{correct};
    while (answers.length < 4) {
      final candidate = correct + _random.nextInt(21) - 10;
      if (candidate > 0) answers.add(candidate);
    }
    _answers = answers.toList()..shuffle(_random);
  }

  void _answer(int value) {
    setState(() {
      if (value == _a * _b) {
        _unlocked = true;
      } else {
        _wrong = true;
        _newQuestion();
      }
    });
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  Future<void> _confirmReset() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.settingsReset),
        content: Text(l10n.settingsResetConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.no),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.yes),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final done = await widget.onResetProgress();
    if (done) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.settingsResetDone)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = context.tokens;
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
                    onTap: _close,
                  ),
                  const SizedBox(width: AppSpacing.s16),
                  Text(
                    l10n.parentsArea,
                    style: TextStyle(
                      fontSize: 30,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      color: tokens.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s8),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: _unlocked ? _buildSettings() : _buildGate(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGate() {
    final l10n = context.l10n;
    final tokens = context.tokens;
    return KidCard(
      padding: const EdgeInsets.all(AppSpacing.s24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.parentsGateTitle,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: tokens.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            l10n.parentsGateQuestion(_a, _b),
            style: TextStyle(fontSize: 22, color: tokens.inkSoft),
          ),
          const SizedBox(height: AppSpacing.s16),
          Wrap(
            spacing: AppSpacing.s12,
            runSpacing: AppSpacing.s12,
            alignment: WrapAlignment.center,
            children: [
              for (final answer in _answers)
                BigButton(label: '$answer', onTap: () => _answer(answer)),
            ],
          ),
          if (_wrong) ...[
            const SizedBox(height: AppSpacing.s12),
            Text(
              l10n.parentsGateWrong,
              style: TextStyle(fontSize: 16, color: tokens.danger),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSettings() {
    final l10n = context.l10n;
    final tokens = context.tokens;
    return BlocBuilder<SettingsCubit, AppSettings>(
      builder: (context, settings) {
        final cubit = context.read<SettingsCubit>();
        return KidCard(
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.settingsLanguage,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: tokens.ink,
                ),
              ),
              const SizedBox(height: AppSpacing.s8),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(value: 'ar', label: Text(l10n.languageArabic)),
                  ButtonSegment(value: 'en', label: Text(l10n.languageEnglish)),
                ],
                selected: {settings.languageCode},
                onSelectionChanged: (selection) =>
                    cubit.setLanguage(selection.first),
              ),
              const SizedBox(height: AppSpacing.s8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.settingsSfx),
                value: settings.sfxOn,
                onChanged: (value) => cubit.setSfx(on: value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.settingsVoice),
                value: settings.voiceOn,
                onChanged: (value) => cubit.setVoice(on: value),
              ),
              const SizedBox(height: AppSpacing.s8),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: OutlinedButton.icon(
                  onPressed: _confirmReset,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: Text(l10n.settingsReset),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: tokens.danger,
                    minimumSize: const Size(48, 48),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
