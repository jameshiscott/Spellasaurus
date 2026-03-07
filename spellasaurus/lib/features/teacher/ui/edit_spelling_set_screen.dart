import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/spelling_set.dart';
import '../../../shared/models/spelling_word.dart';
import '../../../shared/widgets/audio_player_button.dart';
import '../../../shared/widgets/spellasaurus_button.dart';

final _setDetailProvider =
    FutureProvider.family<SpellingSet?, String>((ref, setId) async {
  final data = await supabase
      .from('spelling_sets')
      .select()
      .eq('id', setId)
      .maybeSingle();
  if (data == null) return null;
  return SpellingSet.fromJson(data);
});

final _setWordsProvider =
    FutureProvider.family<List<SpellingWord>, String>((ref, setId) async {
  final data = await supabase
      .from('spelling_words')
      .select()
      .eq('set_id', setId)
      .order('sort_order');
  return (data as List).map((e) => SpellingWord.fromJson(e)).toList();
});

class EditSpellingSetScreen extends ConsumerWidget {
  const EditSpellingSetScreen({super.key, required this.setId});
  final String setId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setDetail = ref.watch(_setDetailProvider(setId));
    final words = ref.watch(_setWordsProvider(setId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: setDetail.when(
          data: (s) => Text(s?.name ?? 'Edit Set'),
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('Edit Set'),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddWordDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Word'),
      ),
      body: words.when(
        data: (list) => list.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('✏️', style: TextStyle(fontSize: 64))
                        .animate()
                        .scale(duration: 500.ms, curve: Curves.elasticOut),
                    const Gap(16),
                    Text('No words yet.\nTap + to add the first word.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                itemCount: list.length,
                itemBuilder: (ctx, i) => _WordEditorCard(
                  word: list[i],
                  index: i,
                  setId: setId,
                  onChanged: () => ref.invalidate(_setWordsProvider(setId)),
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showAddWordDialog(BuildContext context, WidgetRef ref) {
    final wordCtrl = TextEditingController();
    final hintCtrl = TextEditingController();
    bool generating = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add Word',
                  style: Theme.of(ctx).textTheme.headlineSmall),
              const Gap(20),
              TextField(
                controller: wordCtrl,
                textCapitalization: TextCapitalization.none,
                decoration: const InputDecoration(
                  labelText: 'Spelling Word',
                  prefixIcon: Icon(Icons.abc_rounded),
                ),
              ),
              const Gap(16),
              TextField(
                controller: hintCtrl,
                decoration: const InputDecoration(
                  labelText: 'Clue / Hint (optional)',
                  prefixIcon: Icon(Icons.lightbulb_outline),
                ),
              ),
              const Gap(8),
              Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded,
                      size: 16, color: AppColors.primaryLight),
                  const Gap(6),
                  Text(
                    'AI description, sentence & audio will be generated automatically.',
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMedium,
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ],
              ),
              const Gap(24),
              SpellasaurusButton(
                label: generating ? 'Saving & Generating AI...' : 'Save Word',
                loading: generating,
                onPressed: generating
                    ? null
                    : () async {
                        if (wordCtrl.text.trim().isEmpty) return;
                        setModalState(() => generating = true);
                        try {
                          final existingCount = ref
                                  .read(_setWordsProvider(setId))
                                  .valueOrNull
                                  ?.length ??
                              0;
                          final result = await supabase
                              .from('spelling_words')
                              .insert({
                                'set_id': setId,
                                'word': wordCtrl.text.trim().toLowerCase(),
                                'hint': hintCtrl.text.trim().isEmpty
                                    ? null
                                    : hintCtrl.text.trim(),
                                'sort_order': existingCount,
                              })
                              .select()
                              .single();

                          // Trigger AI generation via Edge Function
                          await supabase.functions.invoke(
                            'generate-word-content',
                            body: {'word_id': result['id']},
                          );

                          ref.invalidate(_setWordsProvider(setId));
                          if (ctx.mounted) Navigator.pop(ctx);
                        } finally {
                          if (ctx.mounted) {
                            setModalState(() => generating = false);
                          }
                        }
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WordEditorCard extends ConsumerWidget {
  const _WordEditorCard({
    required this.word,
    required this.index,
    required this.setId,
    required this.onChanged,
  });

  final SpellingWord word;
  final int index;
  final String setId;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hasAi = word.aiDescription != null || word.aiExampleSentence != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text('${index + 1}',
                        style: theme.textTheme.labelLarge
                            ?.copyWith(color: AppColors.primary)),
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: Text(
                    word.word,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(color: AppColors.primary, letterSpacing: 1),
                  ),
                ),
                if (word.audioUrl != null)
                  AudioPlayerButton(audioUrl: word.audioUrl!, size: 40),
                PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'delete') {
                      await supabase
                          .from('spelling_words')
                          .delete()
                          .eq('id', word.id);
                      onChanged();
                    } else if (v == 'regen') {
                      await supabase.functions.invoke(
                        'generate-word-content',
                        body: {'word_id': word.id},
                      );
                      onChanged();
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'regen',
                      child: Row(children: [
                        Icon(Icons.auto_awesome_rounded,
                            size: 18, color: AppColors.primary),
                        Gap(8),
                        Text('Regenerate AI'),
                      ]),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete_outline,
                            size: 18, color: AppColors.error),
                        Gap(8),
                        Text('Delete',
                            style: TextStyle(color: AppColors.error)),
                      ]),
                    ),
                  ],
                ),
              ],
            ),
            if (word.hint != null) ...[
              const Gap(8),
              _InfoChip(
                  icon: '💡', text: word.hint!, color: AppColors.accentGreen),
            ],
            if (word.aiDescription != null) ...[
              const Gap(8),
              _InfoChip(
                icon: '📖',
                text: word.aiDescription!,
                color: AppColors.primary,
              ),
            ],
            if (word.aiExampleSentence != null) ...[
              const Gap(8),
              _InfoChip(
                icon: '💬',
                text: word.aiExampleSentence!,
                color: AppColors.secondary,
                italic: true,
              ),
            ],
            if (!hasAi && word.audioUrl == null) ...[
              const Gap(8),
              Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const Gap(8),
                  Text('Generating AI content...',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textLight,
                          fontStyle: FontStyle.italic)),
                ],
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 60).ms).slideY(begin: 0.05);
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.text,
    required this.color,
    this.italic = false,
  });
  final String icon;
  final String text;
  final Color color;
  final bool italic;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const Gap(8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle:
                        italic ? FontStyle.italic : FontStyle.normal,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
