import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/models/child_practice_settings.dart';
import '../../../shared/models/spelling_set.dart';
import '../../../shared/models/spelling_word.dart';
import '../../../shared/widgets/audio_player_button.dart';

final _practiceSetProvider =
    FutureProvider.family<SpellingSet?, String>((ref, setId) async {
  final data = await supabase
      .from('spelling_sets')
      .select()
      .eq('id', setId)
      .maybeSingle();
  if (data == null) return null;
  return SpellingSet.fromJson(data);
});

final _practiceWordsProvider =
    FutureProvider.family<List<SpellingWord>, String>((ref, setId) async {
  final data = await supabase
      .from('spelling_words')
      .select()
      .eq('set_id', setId)
      .order('sort_order');
  return (data as List).map((e) => SpellingWord.fromJson(e)).toList();
});

final _practiceSettingsForChildProvider =
    FutureProvider<ChildPracticeSettings?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final data = await supabase
      .from('child_practice_settings')
      .select()
      .eq('child_id', user.id)
      .maybeSingle();
  if (data == null) return ChildPracticeSettings.defaultsFor(user.id);
  return ChildPracticeSettings.fromJson(data);
});

class PracticeScreen extends ConsumerStatefulWidget {
  const PracticeScreen({super.key, required this.setId});
  final String setId;

  @override
  ConsumerState<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends ConsumerState<PracticeScreen> {
  int _currentIndex = 0;
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _answered = false;
  bool _correct = false;
  final List<({String wordId, String typed, bool correct})> _answers = [];

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _checkAnswer(SpellingWord word) {
    final typed = _controller.text.trim().toLowerCase();
    final isCorrect = typed == word.word.toLowerCase();
    setState(() {
      _answered = true;
      _correct = isCorrect;
    });
    _answers.add((wordId: word.id, typed: typed, correct: isCorrect));
    HapticFeedback.lightImpact();
  }

  Future<void> _next(List<SpellingWord> words) async {
    if (_currentIndex >= words.length - 1) {
      await _finish(words);
    } else {
      setState(() {
        _currentIndex++;
        _answered = false;
        _correct = false;
        _controller.clear();
      });
      _focusNode.requestFocus();
    }
  }

  Future<void> _finish(List<SpellingWord> words) async {
    final user = ref.read(currentUserProvider);
    final score = _answers.where((a) => a.correct).length;

    final sessionResult = await supabase
        .from('practice_sessions')
        .insert({
          'child_id': user?.id,
          'set_id': widget.setId,
          'score': score,
          'total_words': words.length,
        })
        .select()
        .single();

    // Award 1 coin per correct word
    if (score > 0 && user != null) {
      await supabase.rpc('add_coins', params: {
        'p_child_id': user.id,
        'p_amount': score,
      });
    }

    // Save individual answers
    await supabase.from('practice_answers').insert(
      _answers
          .map((a) => {
                'session_id': sessionResult['id'],
                'word_id': a.wordId,
                'typed_answer': a.typed,
                'is_correct': a.correct,
              })
          .toList(),
    );

    if (mounted) {
      context.pushReplacement('/child/results/${sessionResult['id']}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final words = ref.watch(_practiceWordsProvider(widget.setId));
    final setDetail = ref.watch(_practiceSetProvider(widget.setId));
    final settings = ref.watch(_practiceSettingsForChildProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: setDetail.when(
          data: (s) => Text(s?.name ?? 'Practice'),
          loading: () => const Text('Practice'),
          error: (_, __) => const Text('Practice'),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: words.when(
        data: (wordList) {
          if (wordList.isEmpty) {
            return const Center(child: Text('No words in this set yet!'));
          }
          final word = wordList[_currentIndex];
          final prefs = settings.valueOrNull;
          final autoPlay = prefs?.playTtsAudio ?? true;
          final showDesc = prefs?.showDescription ?? true;
          final showSentence = prefs?.showExampleSentence ?? true;

          return Column(
            children: [
              // Progress bar
              LinearProgressIndicator(
                value: (_currentIndex + 1) / wordList.length,
                backgroundColor: const Color(0xFFE0D9F0),
                color: AppColors.primary,
                minHeight: 6,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Word counter
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Word ${_currentIndex + 1} of ${wordList.length}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.textMedium,
                            ),
                          ),
                        ],
                      ),
                      const Gap(32),
                      // Audio button — big and central
                      if (word.audioUrl != null)
                        AudioPlayerButton(
                          audioUrl: word.audioUrl!,
                          size: 80,
                          autoPlay: autoPlay && !_answered,
                        ).animate().scale(
                            duration: 400.ms, curve: Curves.elasticOut),
                      if (word.audioUrl == null)
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.volume_off_outlined,
                              color: AppColors.textLight, size: 36),
                        ),
                      const Gap(16),
                      Text(
                        'Listen and type the word',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMedium,
                        ),
                      ),
                      const Gap(32),
                      // Description hint (if enabled & answered)
                      if (showDesc &&
                          word.aiDescription != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('📖',
                                  style: TextStyle(fontSize: 18)),
                              const Gap(10),
                              Expanded(
                                child: Text(word.aiDescription!,
                                    style: theme.textTheme.bodyMedium),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 100.ms),
                        const Gap(12),
                      ],
                      if (showSentence &&
                          word.aiExampleSentence != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('💬',
                                  style: TextStyle(fontSize: 18)),
                              const Gap(10),
                              Expanded(
                                child: Text(
                                  word.aiExampleSentence!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                      fontStyle: FontStyle.italic),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 200.ms),
                        const Gap(12),
                      ],
                      const Gap(8),
                      // Answer input
                      if (!_answered) ...[
                        TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            letterSpacing: 4,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Type the word...',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                  color: Color(0xFFE0D9F0), width: 2),
                            ),
                          ),
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _checkAnswer(word),
                          autofocus: true,
                        ),
                        const Gap(20),
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: () => _checkAnswer(word),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Text('Check',
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(color: Colors.white)),
                          ),
                        ),
                      ] else ...[
                        // Result feedback
                        _FeedbackBanner(
                          correct: _correct,
                          word: word.word,
                          typed: _answers.last.typed,
                        ).animate().scale(
                            duration: 400.ms, curve: Curves.elasticOut),
                        const Gap(20),
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: () => _next(wordList),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _correct
                                  ? AppColors.accentGreen
                                  : AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Text(
                              _currentIndex >= wordList.length - 1
                                  ? 'See Results 🏆'
                                  : 'Next Word →',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({
    required this.correct,
    required this.word,
    required this.typed,
  });
  final bool correct;
  final String word;
  final String typed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: correct
            ? AppColors.accentGreen.withOpacity(0.1)
            : AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: correct ? AppColors.accentGreen : AppColors.error,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            correct ? '🎉 Correct!' : '😔 Not quite...',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: correct ? AppColors.accentGreen : AppColors.error,
            ),
          ),
          if (!correct) ...[
            const Gap(8),
            Text('You typed: "$typed"',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.textMedium)),
            const Gap(4),
            Text('Correct: "$word"',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.primary,
                  letterSpacing: 2,
                )),
          ],
        ],
      ),
    );
  }
}
