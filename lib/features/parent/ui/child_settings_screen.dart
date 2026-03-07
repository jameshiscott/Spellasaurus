import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/child_practice_settings.dart';
import '../../../shared/widgets/spellasaurus_button.dart';

final _practiceSettingsProvider =
    FutureProvider.family<ChildPracticeSettings, String>((ref, childId) async {
  final data = await supabase
      .from('child_practice_settings')
      .select()
      .eq('child_id', childId)
      .maybeSingle();
  if (data == null) return ChildPracticeSettings.defaultsFor(childId);
  return ChildPracticeSettings.fromJson(data);
});

class ChildSettingsScreen extends ConsumerStatefulWidget {
  const ChildSettingsScreen({super.key, required this.childId});
  final String childId;

  @override
  ConsumerState<ChildSettingsScreen> createState() =>
      _ChildSettingsScreenState();
}

class _ChildSettingsScreenState extends ConsumerState<ChildSettingsScreen> {
  ChildPracticeSettings? _settings;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final settingsAsync =
        ref.watch(_practiceSettingsProvider(widget.childId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Practice Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: settingsAsync.when(
        data: (settings) {
          _settings ??= settings;
          final s = _settings!;
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 24)),
                    const Gap(12),
                    Expanded(
                      child: Text(
                        'Choose what hints and aids your child gets during practice.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(),
              const Gap(28),
              Text('Learning Aids', style: theme.textTheme.headlineSmall),
              const Gap(16),
              _SettingTile(
                emoji: '🔊',
                title: 'Read word aloud',
                subtitle: 'Automatically play the spoken word',
                value: s.playTtsAudio,
                onChanged: (v) =>
                    setState(() => _settings = s.copyWith(playTtsAudio: v)),
              ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.05),
              const Gap(8),
              _SettingTile(
                emoji: '📖',
                title: 'Show description',
                subtitle: 'Display an age-appropriate definition',
                value: s.showDescription,
                onChanged: (v) =>
                    setState(() => _settings = s.copyWith(showDescription: v)),
              ).animate().fadeIn(delay: 160.ms).slideX(begin: 0.05),
              const Gap(8),
              _SettingTile(
                emoji: '💬',
                title: 'Show example sentence',
                subtitle: 'Show the word used in a sentence',
                value: s.showExampleSentence,
                onChanged: (v) => setState(
                    () => _settings = s.copyWith(showExampleSentence: v)),
              ).animate().fadeIn(delay: 220.ms).slideX(begin: 0.05),
              const Gap(40),
              SpellasaurusButton(
                label: 'Save Settings',
                loading: _saving,
                onPressed: _saving ? null : _save,
              ).animate().fadeIn(delay: 300.ms),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _save() async {
    if (_settings == null) return;
    setState(() => _saving = true);
    try {
      await supabase.from('child_practice_settings').upsert({
        'child_id': widget.childId,
        'show_description': _settings!.showDescription,
        'show_example_sentence': _settings!.showExampleSentence,
        'play_tts_audio': _settings!.playTtsAudio,
        'updated_at': DateTime.now().toIso8601String(),
      });
      ref.invalidate(_practiceSettingsProvider(widget.childId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved!')),
        );
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final String emoji;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: SwitchListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        secondary: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: value
                ? AppColors.primary.withOpacity(0.1)
                : AppColors.textLight.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
        ),
        title: Text(title, style: theme.textTheme.titleMedium),
        subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
        value: value,
        activeColor: AppColors.primary,
        onChanged: onChanged,
      ),
    );
  }
}
