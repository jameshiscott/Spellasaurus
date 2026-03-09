import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/auth/providers/auth_provider.dart';
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

final _coinBalanceProvider = FutureProvider<int>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 0;
  final data = await supabase
      .from('profiles')
      .select('coin_balance')
      .eq('id', user.id)
      .single();
  return (data['coin_balance'] as int?) ?? 0;
});

class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key, required this.sessionId});
  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(_sessionProvider(sessionId));
    final answers = ref.watch(_sessionAnswersProvider(sessionId));
    final coinBalance = ref.watch(_coinBalanceProvider);
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
          final coinsEarned = s.score;

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
                  const Gap(24),
                  // ── Dino coin animation ──────────────────────────────────
                  coinBalance.when(
                    data: (total) => _DinoCoinWidget(
                      coinsEarned: coinsEarned,
                      totalCoins: total,
                    ).animate().fadeIn(delay: 300.ms),
                    loading: () => _DinoCoinWidget(
                      coinsEarned: coinsEarned,
                      totalCoins: 0,
                    ).animate().fadeIn(delay: 300.ms),
                    error: (_, __) => _DinoCoinWidget(
                      coinsEarned: coinsEarned,
                      totalCoins: 0,
                    ),
                  ),
                  const Gap(8),
                  if (coinsEarned > 0)
                    Text(
                      '+$coinsEarned coin${coinsEarned == 1 ? '' : 's'} earned!',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.secondaryDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.3),
                  const Gap(24),
                  StarRating(score: s.score, total: s.totalWords, size: 48)
                      .animate()
                      .scale(
                          duration: 500.ms,
                          curve: Curves.elasticOut,
                          delay: 400.ms),
                  const Gap(40),
                  // ── Word breakdown ───────────────────────────────────────
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
                                if (isCorrect)
                                  const Text('🪙',
                                      style: TextStyle(fontSize: 20)),
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

// ── Animated dinosaur with coins flying into it ──────────────────────────────

class _DinoCoinWidget extends StatefulWidget {
  const _DinoCoinWidget({required this.coinsEarned, required this.totalCoins});
  final int coinsEarned;
  final int totalCoins;

  @override
  State<_DinoCoinWidget> createState() => _DinoCoinWidgetState();
}

class _DinoCoinWidgetState extends State<_DinoCoinWidget>
    with TickerProviderStateMixin {
  late final List<AnimationController> _coinControllers;

  // Cap at 8 visible coin particles regardless of score
  static const int _maxParticles = 8;

  @override
  void initState() {
    super.initState();
    final count = widget.coinsEarned.clamp(0, _maxParticles);
    _coinControllers = List.generate(count, (i) {
      final ctrl = AnimationController(
        duration: const Duration(milliseconds: 700),
        vsync: this,
      );
      // Stagger each coin by 200 ms, starting after a 500 ms initial pause
      Future.delayed(Duration(milliseconds: 500 + i * 200), () {
        if (mounted) ctrl.forward();
      });
      return ctrl;
    });
  }

  @override
  void dispose() {
    for (final c in _coinControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = _coinControllers.length;

    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Flying coin particles
          ..._coinControllers.asMap().entries.map((entry) {
            final i = entry.key;
            final ctrl = entry.value;
            // Spread coins horizontally across the dino
            final xAlign = total > 1 ? (i / (total - 1) - 0.5) * 1.6 : 0.0;

            return AnimatedBuilder(
              animation: ctrl,
              builder: (context, _) {
                final t = ctrl.value;
                // y goes from -0.9 (above dino) to 0 (dino center)
                final yAlign = -0.9 + t * 0.9;
                // fade out in the last 30% of the animation
                final opacity = t < 0.7 ? 1.0 : (1.0 - (t - 0.7) / 0.3).clamp(0.0, 1.0);

                return Align(
                  alignment: Alignment(xAlign, yAlign),
                  child: Opacity(
                    opacity: opacity,
                    child: const Text('🪙', style: TextStyle(fontSize: 26)),
                  ),
                );
              },
            );
          }),

          // Dino with total coin badge
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  const Text('🦕', style: TextStyle(fontSize: 110)),
                  // Coin total badge positioned over the dino's body
                  Positioned(
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🪙', style: TextStyle(fontSize: 16)),
                          const Gap(4),
                          _AnimatedCoinCount(target: widget.totalCoins),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Counts up from (totalCoins - coinsEarned) to totalCoins with a rolling animation.
class _AnimatedCoinCount extends StatefulWidget {
  const _AnimatedCoinCount({required this.target});
  final int target;

  @override
  State<_AnimatedCoinCount> createState() => _AnimatedCoinCountState();
}

class _AnimatedCoinCountState extends State<_AnimatedCoinCount>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<int> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _anim = IntTween(begin: 0, end: widget.target).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    // Start counting after coins have begun flying in
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) => Text(
        '${_anim.value}',
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.textDark,
        ),
      ),
    );
  }
}
