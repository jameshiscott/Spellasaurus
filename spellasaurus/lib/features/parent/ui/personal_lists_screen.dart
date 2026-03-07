import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/models/spelling_set.dart';
import '../../../shared/widgets/spellasaurus_button.dart';

final _personalSetsProvider =
    FutureProvider.family<List<SpellingSet>, String>((ref, childId) async {
  final data = await supabase
      .from('spelling_sets')
      .select()
      .eq('child_id', childId)
      .order('created_at', ascending: false);
  return (data as List).map((e) => SpellingSet.fromJson(e)).toList();
});

class PersonalListsScreen extends ConsumerWidget {
  const PersonalListsScreen({super.key, required this.childId});
  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sets = ref.watch(_personalSetsProvider(childId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Lists'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSetDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New List'),
      ),
      body: sets.when(
        data: (list) => list.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('📋', style: TextStyle(fontSize: 64))
                        .animate()
                        .scale(duration: 500.ms, curve: Curves.elasticOut),
                    const Gap(16),
                    Text('No personal lists yet.\nTap + to create one.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                itemCount: list.length,
                itemBuilder: (ctx, i) => Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                          child: Text('📋', style: TextStyle(fontSize: 22))),
                    ),
                    title: Text(list[i].name,
                        style: theme.textTheme.titleMedium),
                    trailing: const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textLight),
                    onTap: () =>
                        context.push('/teacher/set/${list[i].id}/edit'),
                  ),
                ).animate().fadeIn(delay: (i * 60).ms),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showAddSetDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
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
            Text('New Personal List',
                style: Theme.of(ctx).textTheme.headlineSmall),
            const Gap(20),
            TextField(
              controller: nameCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                  labelText: 'List Name (e.g. Rainbow Words)'),
            ),
            const Gap(24),
            SpellasaurusButton(
              label: 'Create List',
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                final user = ref.read(currentUserProvider);
                final result = await supabase
                    .from('spelling_sets')
                    .insert({
                      'child_id': childId,
                      'created_by': user?.id,
                      'name': nameCtrl.text.trim(),
                    })
                    .select()
                    .single();
                ref.invalidate(_personalSetsProvider(childId));
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  context.push('/teacher/set/${result['id']}/edit');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
