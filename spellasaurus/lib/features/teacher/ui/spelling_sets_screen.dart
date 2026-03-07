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
import '../../../shared/widgets/spellasaurus_button.dart';

final _classSpellingSetsProvider =
    FutureProvider.family<List<SpellingSet>, String>((ref, classId) async {
  final data = await supabase
      .from('spelling_sets')
      .select()
      .eq('class_id', classId)
      .order('week_start', ascending: false);
  return (data as List).map((e) => SpellingSet.fromJson(e)).toList();
});

class SpellingSetsScreen extends ConsumerWidget {
  const SpellingSetsScreen({super.key, required this.classId});
  final String classId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sets = ref.watch(_classSpellingSetsProvider(classId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spelling Sets'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSetDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New Set'),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.refresh(_classSpellingSetsProvider(classId).future),
        child: sets.when(
          data: (list) => list.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('📝', style: TextStyle(fontSize: 64))
                          .animate()
                          .scale(duration: 500.ms, curve: Curves.elasticOut),
                      const Gap(16),
                      Text('No spelling sets yet.\nTap + to create one.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: list.length,
                  itemBuilder: (ctx, i) =>
                      _SetCard(set: list[i], index: i),
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  void _showAddSetDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    DateTime weekStart = _currentWeekMonday();

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
              Text('New Spelling Set',
                  style: Theme.of(ctx).textTheme.headlineSmall),
              const Gap(20),
              TextField(
                controller: nameCtrl,
                decoration:
                    const InputDecoration(labelText: 'Set Name (e.g. Set 1)'),
              ),
              const Gap(16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Week of',
                            style: Theme.of(ctx).textTheme.titleSmall),
                        const Gap(4),
                        Text(
                          DateFormat('d MMM yyyy').format(weekStart),
                          style: Theme.of(ctx).textTheme.bodyLarge?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today_outlined, size: 16),
                    label: const Text('Change'),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: weekStart,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setModalState(() {
                          weekStart = _mondayOf(picked);
                        });
                      }
                    },
                  ),
                ],
              ),
              const Gap(24),
              SpellasaurusButton(
                label: 'Create Set',
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) return;
                  final user = ref.read(currentUserProvider);
                  final result = await supabase
                      .from('spelling_sets')
                      .insert({
                        'class_id': classId,
                        'created_by': user?.id,
                        'name': nameCtrl.text.trim(),
                        'week_start': weekStart.toIso8601String().substring(0, 10),
                        'week_number': _weekNumber(weekStart),
                      })
                      .select()
                      .single();
                  ref.invalidate(_classSpellingSetsProvider(classId));
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    context.push('/teacher/set/${result['id']}/edit');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  static DateTime _currentWeekMonday() => _mondayOf(DateTime.now());

  static DateTime _mondayOf(DateTime d) {
    return d.subtract(Duration(days: d.weekday - 1));
  }

  static int _weekNumber(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    final diff = date.difference(startOfYear).inDays;
    return ((diff + startOfYear.weekday - 1) / 7).floor() + 1;
  }
}

class _SetCard extends StatelessWidget {
  const _SetCard({required this.set, required this.index});
  final SpellingSet set;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weekLabel = set.weekStart != null
        ? 'Week of ${DateFormat('d MMM').format(set.weekStart!)}'
        : '';

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push('/teacher/set/${set.id}/edit'),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text('📝', style: TextStyle(fontSize: 26)),
                ),
              ),
              const Gap(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(set.name, style: theme.textTheme.titleMedium),
                    if (weekLabel.isNotEmpty)
                      Text(weekLabel, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textLight),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 70).ms).slideX(begin: 0.05);
  }
}
