import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/practice_session.dart';
import '../../../shared/models/spelling_word.dart';
import '../../../shared/widgets/star_rating.dart';

final _sessionProvider =
    FutureProvider.family<PracticeSession?, String>((ref, sessionId) async {
  final data = await supabase
      .from('practice_sessions')
      .select()
      .eq('id', sessionId)
      .maybeSingle();
  if (data == null) return null;
  return PracticeSession.fromJson(data);
});

final _sessionAnswersProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, sessionId) async {
  final data = await supabase
      .from('practice_answers')
      .select('*, spelling_words(*)')
      .eq('session_id', sessionId);
  return (data as List).cast<Map<String, dynamic>>();
});

class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key, required this.sessionId});
  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(_sessionProvider(sessionId));
    final answers = ref.watch(_sessionAnswersProvider(sessionId));
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: session.when(
        data: (s) {
          if (s == null) return const Center(child: Text('Session not found'));
          final pct = s.totalWords > 0 ? s.score / s.totalWords : 0.0;
          final message = pct >= 0.9
              ? '🌟 Amazing!'
              : pct >= 0.6
                  ? '👍 Great effort!'
                  : pct > 0
                      ? '💪 Keep practising!'
                      : '😊 You\'ll get there!';

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Gap(16),
                  Text('Practice Complete!',
                      style: theme.textTheme.headlineMedium)
                      .animate()
                      .fadeIn(),
                  const Gap(8),
                  Text(message,
                      style: theme.textTheme.headlineSmall?.copyWith(
                          color: AppColors.primary))
                      .animate()
                      .fadeIn(delay: 100.ms),
                  const Gap(32),
                  // Score circle
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.4),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${s.score}',
                            style: theme.textTheme.displayMedium
                                ?.copyWith(color: Colors.white),
                          ),
                          Text(
                            'of ${s.totalWords}',
                            style: theme.textTheme.bodyLarge
                                ?.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  )
                      .animate()
                      .scale(duration: 600.ms, curve: Curves.elasticOut,
                          delay: 200.ms),
                  const Gap(24),
                  StarRating(score: s.score, total: s.totalWords, size: 48)
                      .animate()
                      .scale(
                          duration: 500.ms,
                          curve: Curves.elasticOut,
                          delay: 400.ms),
                  const Gap(40),
                  // Word breakdown
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Word Breakdown',
                        style: theme.textTheme.headlineSmall),
                  ),
                  const Gap(12),
                  answers.when(
                    data: (list) => Column(
                      children: list.asMap().entries.map((e) {
                        final answer = e.value;
                        final wordData = answer['spelling_words']
                            as Map<String, dynamic>;
                        final word = SpellingWord.fromJson(wordData);
                        final isCorrect = answer['is_correct'] as bool;
                        final typed = answer['typed_answer'] as String;

                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                            child: Row(
                              children: [
                                Icon(
                                  isCorrect
                                      ? Icons.check_circle_rounded
                                      : Icons.cancel_rounded,
                                  color: isCorrect
                                      ? AppColors.accentGreen
                                      : AppColors.error,
                                  size: 28,
                                ),
                                const Gap(12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(word.word,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            color: isCorrect
                                                ? AppColors.accentGreen
                                                : AppColors.error,
                                            letterSpacing: 1,
                                          )),
                                      if (!isCorrect)
                                        Text('You wrote: "$typed"',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                    color:
                                                        AppColors.textMedium)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(delay: (e.key * 60).ms);
                      }).toList(),
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error: $e'),
                  ),
                  const Gap(32),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () => context.go('/child'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text('Back to Home 🏠',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(color: Colors.white)),
                    ),
                  ).animate().fadeIn(delay: 600.ms),
                  const Gap(16),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: OutlinedButton(
                      onPressed: () =>
                          context.pushReplacement('/child/practice/${s.setId}'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: AppColors.primary, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text('Try Again 🔄',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(color: AppColors.primary)),
                    ),
                  ).animate().fadeIn(delay: 700.ms),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
