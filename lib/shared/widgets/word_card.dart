import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import '../../../core/theme/app_colors.dart';
import '../models/spelling_word.dart';
import 'audio_player_button.dart';

class WordCard extends StatelessWidget {
  const WordCard({
    super.key,
    required this.word,
    this.showDescription = true,
    this.showSentence = true,
    this.showAudio = true,
    this.revealed = true,
    this.index = 0,
  });

  final SpellingWord word;
  final bool showDescription;
  final bool showSentence;
  final bool showAudio;
  final bool revealed;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                    child: Text(
                      '${index + 1}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: Text(
                    revealed ? word.word : '_ ' * word.word.length,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: AppColors.primary,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                if (showAudio && word.audioUrl != null)
                  AudioPlayerButton(audioUrl: word.audioUrl!),
              ],
            ),
            if (showDescription &&
                word.aiDescription != null &&
                revealed) ...[
              const Gap(12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('📖', style: TextStyle(fontSize: 16)),
                    const Gap(8),
                    Expanded(
                      child: Text(
                        word.aiDescription!,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (showSentence &&
                word.aiExampleSentence != null &&
                revealed) ...[
              const Gap(8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💬', style: TextStyle(fontSize: 16)),
                    const Gap(8),
                    Expanded(
                      child: Text(
                        word.aiExampleSentence!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (word.hint != null && word.hint!.isNotEmpty && revealed) ...[
              const Gap(8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accentGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 16)),
                    const Gap(8),
                    Expanded(
                      child: Text(
                        word.hint!,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 60).ms).slideY(begin: 0.05);
  }
}
