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

final _allChildSetsProvider =
    FutureProvider<List<SpellingSet>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

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
        .order('week_start', ascending: false);
    sets.addAll(
        (classData as List).map((e) => SpellingSet.fromJson(e)));
  }

  final personalData = await supabase
      .from('spelling_sets')
      .select()
      .eq('child_id', user.id)
      .order('created_at', ascending: false);
  sets.addAll(
      (personalData as List).map((e) => SpellingSet.fromJson(e)));

  return sets;
});

class SetListScreen extends ConsumerWidget {
  const SetListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sets = ref.watch(_allChildSetsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Spelling Sets'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: sets.when(
        data: (list) => list.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('📚', style: TextStyle(fontSize: 64))
                        .animate()
                        .scale(duration: 500.ms, curve: Curves.elasticOut),
                    const Gap(16),
                    Text('No spelling sets yet!',
                        style: theme.textTheme.bodyMedium),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: list.length,
                itemBuilder: (ctx, i) {
                  final set = list[i];
                  final weekLabel = set.weekStart != null
                      ? DateFormat('d MMM yyyy').format(set.weekStart!)
                      : null;
                  return Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () =>
                          context.push('/child/practice/${set.id}'),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color:
                                    AppColors.primaryLight.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Center(
                                child: Text('📝',
                                    style: TextStyle(fontSize: 26)),
                              ),
                            ),
                            const Gap(16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(set.name,
                                      style: theme.textTheme.titleMedium),
                                  if (weekLabel != null)
                                    Text('Week of $weekLabel',
                                        style: theme.textTheme.bodySmall),
                                ],
                              ),
                            ),
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.play_arrow_rounded,
                                  color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: (i * 60).ms).slideX(begin: 0.05);
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
