import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/models/profile.dart';
import '../../../shared/models/spelling_set.dart';
import '../../../shared/widgets/spellasaurus_button.dart';

// All personal lists owned by the current parent
final _myPersonalSetsProvider = FutureProvider<List<SpellingSet>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  final data = await supabase
      .from('spelling_sets')
      .select()
      .eq('created_by', user.id)
      .isFilter('class_id', null)
      .order('created_at', ascending: false);
  return (data as List).map((e) => SpellingSet.fromJson(e)).toList();
});

// Children assigned to a specific personal set
final _setAssignedChildrenProvider =
    FutureProvider.family<List<Profile>, String>((ref, setId) async {
  final data = await supabase
      .from('child_personal_sets')
      .select('profiles!child_personal_sets_child_id_fkey(*)')
      .eq('set_id', setId);
  return (data as List).map((e) {
    final p = (e['profiles!child_personal_sets_child_id_fkey'] ?? e['profiles'])
        as Map<String, dynamic>;
    return Profile.fromJson(p);
  }).toList();
});

// Parent's own children (for the assign dialog)
final _parentChildrenProvider = FutureProvider<List<Profile>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  final data = await supabase
      .from('parent_children')
      .select('profiles!parent_children_child_id_fkey(*)')
      .eq('parent_id', user.id);
  return (data as List).map((e) {
    final p = (e['profiles!parent_children_child_id_fkey'] ?? e['profiles'])
        as Map<String, dynamic>;
    return Profile.fromJson(p);
  }).toList();
});

class PersonalListsScreen extends ConsumerWidget {
  const PersonalListsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sets = ref.watch(_myPersonalSetsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Word Lists'),
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
                    Text(
                      'No word lists yet.\nTap + to create one.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                itemCount: list.length,
                itemBuilder: (ctx, i) => _PersonalSetTile(set: list[i])
                    .animate()
                    .fadeIn(delay: (i * 60).ms),
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
            Text('New Word List',
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
                      'created_by': user?.id,
                      'name': nameCtrl.text.trim(),
                    })
                    .select()
                    .single();
                ref.invalidate(_myPersonalSetsProvider);
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

class _PersonalSetTile extends ConsumerWidget {
  const _PersonalSetTile({required this.set});
  final SpellingSet set;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assigned = ref.watch(_setAssignedChildrenProvider(set.id));
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                      child: Text('📋', style: TextStyle(fontSize: 22))),
                ),
                const Gap(12),
                Expanded(
                  child: Text(set.name, style: theme.textTheme.titleMedium),
                ),
                IconButton(
                  tooltip: 'Edit words',
                  icon: const Icon(Icons.edit_outlined,
                      color: AppColors.textLight),
                  onPressed: () =>
                      context.push('/teacher/set/${set.id}/edit'),
                ),
              ],
            ),
            const Gap(8),
            // Assigned children chips
            assigned.when(
              data: (children) => Row(
                children: [
                  Expanded(
                    child: children.isEmpty
                        ? Text('Not assigned to any child',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textLight))
                        : Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: children
                                .map((c) => Chip(
                                      label: Text(
                                          c.fullName.split(' ').first,
                                          style: const TextStyle(fontSize: 12)),
                                      avatar: const Text('👦',
                                          style: TextStyle(fontSize: 12)),
                                      onDeleted: () =>
                                          _unassign(ref, set.id, c.id),
                                      deleteIconColor: AppColors.textMedium,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ))
                                .toList(),
                          ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.person_add_outlined, size: 16),
                    label: const Text('Assign'),
                    onPressed: () =>
                        _showAssignDialog(context, ref, children),
                  ),
                ],
              ),
              loading: () =>
                  const SizedBox(height: 20, child: LinearProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _unassign(WidgetRef ref, String setId, String childId) async {
    await supabase
        .from('child_personal_sets')
        .delete()
        .eq('set_id', setId)
        .eq('child_id', childId);
    ref.invalidate(_setAssignedChildrenProvider(setId));
  }

  void _showAssignDialog(
      BuildContext context, WidgetRef ref, List<Profile> alreadyAssigned) {
    final alreadyIds = alreadyAssigned.map((c) => c.id).toSet();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final children = ref.watch(_parentChildrenProvider);
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Assign to Child',
                  style: Theme.of(ctx).textTheme.headlineSmall),
              const Gap(16),
              children.when(
                data: (list) {
                  final unassigned =
                      list.where((c) => !alreadyIds.contains(c.id)).toList();
                  if (unassigned.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text('All your children already have this list.',
                          style: Theme.of(ctx).textTheme.bodyMedium),
                    );
                  }
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: unassigned
                        .map((child) => ListTile(
                              leading: const Text('👦',
                                  style: TextStyle(fontSize: 24)),
                              title: Text(child.fullName),
                              onTap: () async {
                                await supabase
                                    .from('child_personal_sets')
                                    .insert({
                                  'set_id': set.id,
                                  'child_id': child.id,
                                });
                                ref.invalidate(
                                    _setAssignedChildrenProvider(set.id));
                                if (ctx.mounted) Navigator.pop(ctx);
                              },
                            ))
                        .toList(),
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
              ),
            ],
          ),
        );
      },
    );
  }
}
