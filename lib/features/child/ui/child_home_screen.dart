import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/models/spelling_set.dart';

final _childSetsThisWeekProvider =
    FutureProvider<List<SpellingSet>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final now = DateTime.now();
  final monday =
      now.subtract(Duration(days: now.weekday - 1));
  final mondayStr = monday.toIso8601String().substring(0, 10);

  // Get class sets for this week
  final enrollment = await supabase
      .from('class_students')
      .select('class_id')
      .eq('child_id', user.id)
      .maybeSingle();

  final List<SpellingSet> sets = [];

  if (enrollment != null) {
    final classId = enrollment['class_id'] as String;
    final classData = await supabase
        .from('spelling_sets')
        .select()
        .eq('class_id', classId)
        .eq('week_start', mondayStr);
    sets.addAll(
        (classData as List).map((e) => SpellingSet.fromJson(e)));
  }

  // Personal sets
  final personalData = await supabase
      .from('spelling_sets')
      .select()
      .eq('child_id', user.id)
      .order('created_at', ascending: false)
      .limit(5);
  sets.addAll(
      (personalData as List).map((e) => SpellingSet.fromJson(e)));

  return sets;
});

class ChildHomeScreen extends ConsumerWidget {
  const ChildHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    final setsThisWeek = ref.watch(_childSetsThisWeekProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(_childSetsThisWeekProvider);
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              const Gap(20),
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  profile.when(
                    data: (p) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hi ${p?.fullName.split(' ').first ?? 'there'} 👋',
                          style: theme.textTheme.headlineMedium,
                        ),
                        Text(
                          "Let's practice spelling!",
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded,
                        color: AppColors.textLight),
                    onPressed: () async {
                      await ref.read(authRepositoryProvider).signOut();
                      if (context.mounted) context.go('/login');
                    },
                  ),
                ],
              ).animate().fadeIn(),
              const Gap(24),
              // Mascot hero banner
              _MascotBanner().animate().scale(
                  duration: 600.ms, curve: Curves.elasticOut, delay: 100.ms),
              const Gap(28),
              // This week's sets
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("This Week's Sets",
                      style: theme.textTheme.headlineSmall),
                  TextButton(
                    onPressed: () => context.push('/child/sets'),
                    child: const Text('See All'),
                  ),
                ],
              ).animate().fadeIn(delay: 200.ms),
              const Gap(12),
              setsThisWeek.when(
                data: (sets) => sets.isEmpty
                    ? _EmptyWeekCard()
                    : Column(
                        children: sets
                            .asMap()
                            .entries
                            .map((e) => _PracticeSetCard(
                                  set: e.value,
                                  index: e.key,
                                ))
                            .toList(),
                      ),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => Text('Error: $e'),
              ),
              const Gap(20),
            ],
          ),
        ),
      ),
    );
  }
}

class _MascotBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ready to\nSpell? 🌟',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const Gap(8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Practice makes perfect!',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const Text('🦕', style: TextStyle(fontSize: 80)),
        ],
      ),
    );
  }
}

class _EmptyWeekCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('😴', style: TextStyle(fontSize: 48)),
            const Gap(12),
            Text(
              'No sets for this week yet!\nCheck back soon.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _PracticeSetCard extends StatelessWidget {
  const _PracticeSetCard({required this.set, required this.index});
  final SpellingSet set;
  final int index;

  static const _gradients = [
    [Color(0xFF6C3CE1), Color(0xFF9B6FF5)],
    [Color(0xFF4CAF82), Color(0xFF2E7D5A)],
    [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
    [Color(0xFFFFC832), Color(0xFFFF8E53)],
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final grad = _gradients[index % _gradients.length];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => context.push('/child/practice/${set.id}'),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: grad,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: grad[0].withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text('📝', style: TextStyle(fontSize: 28)),
                ),
              ),
              const Gap(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      set.name,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(color: Colors.white),
                    ),
                    if (set.weekStart != null)
                      Text(
                        'Week of ${DateFormat('d MMM').format(set.weekStart!)}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.white70),
                      ),
                  ],
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 28),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (200 + index * 100).ms).slideY(begin: 0.1);
  }
}
