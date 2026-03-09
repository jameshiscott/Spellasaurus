import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/profile.dart';
import '../../../shared/models/spelling_set.dart';
import '../../../shared/widgets/spellasaurus_button.dart';

final _childProfileProvider =
    FutureProvider.family<Profile?, String>((ref, childId) async {
  final data = await supabase
      .from('profiles')
      .select()
      .eq('id', childId)
      .maybeSingle();
  if (data == null) return null;
  return Profile.fromJson(data);
});

final _childClassSetsProvider =
    FutureProvider.family<List<SpellingSet>, String>((ref, childId) async {
  // Get class for child, then get sets
  final enrollment = await supabase
      .from('class_students')
      .select('class_id')
      .eq('child_id', childId)
      .maybeSingle();
  if (enrollment == null) return [];
  final classId = enrollment['class_id'] as String;
  final data = await supabase
      .from('spelling_sets')
      .select()
      .eq('class_id', classId)
      .order('week_start', ascending: false);
  return (data as List).map((e) => SpellingSet.fromJson(e)).toList();
});

final _childPersonalSetsProvider =
    FutureProvider.family<List<SpellingSet>, String>((ref, childId) async {
  final data = await supabase
      .from('child_personal_sets')
      .select('spelling_sets(*)')
      .eq('child_id', childId);
  return (data as List)
      .map((e) => SpellingSet.fromJson(e['spelling_sets'] as Map<String, dynamic>))
      .toList();
});

class ChildDetailScreen extends ConsumerWidget {
  const ChildDetailScreen({super.key, required this.childId});
  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(_childProfileProvider(childId));
    final classSets = ref.watch(_childClassSetsProvider(childId));
    final personalSets = ref.watch(_childPersonalSetsProvider(childId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: child.when(
          data: (c) => Text(c?.fullName ?? 'Child'),
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('Child'),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Practice Settings',
            onPressed: () =>
                context.push('/parent/child/$childId/settings'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Quick actions row
          Row(
            children: [
              Expanded(
                child: _ActionTile(
                  emoji: '⚙️',
                  label: 'Settings',
                  color: AppColors.textMedium,
                  onTap: () =>
                      context.push('/parent/child/$childId/settings'),
                ),
              ),
              const Gap(12),
              Expanded(
                child: _ActionTile(
                  emoji: '📝',
                  label: 'My Word Lists',
                  color: AppColors.accent,
                  onTap: () => context.push('/parent/lists'),
                ),
              ),
              const Gap(12),
              Expanded(
                child: _ActionTile(
                  emoji: '🔑',
                  label: 'Reset Password',
                  color: AppColors.textMedium,
                  onTap: () => _showResetPasswordSheet(context, ref),
                ),
              ),
            ],
          ),
          const Gap(28),
          Text('Class Spelling Sets', style: theme.textTheme.headlineSmall),
          const Gap(12),
          classSets.when(
            data: (list) => list.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text('Not enrolled in a class yet.',
                        style: theme.textTheme.bodyMedium),
                  )
                : Column(
                    children: list.asMap().entries.map((e) =>
                        _SetTile(set: e.value, index: e.key)).toList()),
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Error: $e'),
          ),
          const Gap(24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Assigned Lists', style: theme.textTheme.headlineSmall),
              TextButton.icon(
                icon: const Icon(Icons.list_outlined, size: 18),
                label: const Text('Manage'),
                onPressed: () => context.push('/parent/lists'),
              ),
            ],
          ),
          const Gap(12),
          personalSets.when(
            data: (list) => list.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text('No lists assigned yet. Tap Manage to assign one.',
                        style: theme.textTheme.bodyMedium),
                  )
                : Column(
                    children: list.asMap().entries.map((e) =>
                        _DetachableSetTile(
                          set: e.value,
                          index: e.key,
                          childId: childId,
                          onDetached: () => ref.invalidate(
                              _childPersonalSetsProvider(childId)),
                        )).toList()),
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }

  void _showResetPasswordSheet(BuildContext context, WidgetRef ref) {
    final passwordCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: StatefulBuilder(
          builder: (ctx, setModalState) {
            String? error;
            bool loading = false;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Reset Password',
                    style: Theme.of(ctx).textTheme.headlineSmall),
                const Gap(16),
                TextField(
                  controller: passwordCtrl,
                  obscureText: true,
                  decoration:
                      const InputDecoration(labelText: 'New Password'),
                ),
                const Gap(12),
                TextField(
                  controller: confirmCtrl,
                  obscureText: true,
                  decoration:
                      const InputDecoration(labelText: 'Confirm Password'),
                ),
                if (error != null) ...[
                  const Gap(12),
                  Text(error!, style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
                ],
                const Gap(20),
                SpellasaurusButton(
                  label: 'Update Password',
                  loading: loading,
                  onPressed: () async {
                    final password = passwordCtrl.text;
                    final confirm = confirmCtrl.text;
                    if (password.length < 8) {
                      setModalState(() =>
                          error = 'Password must be at least 8 characters.');
                      return;
                    }
                    if (password != confirm) {
                      setModalState(
                          () => error = 'Passwords do not match.');
                      return;
                    }
                    setModalState(() {
                      error = null;
                      loading = true;
                    });
                    final result = await supabase.functions.invoke(
                      'reset-child-password',
                      body: {
                        'child_id': childId,
                        'new_password': password,
                      },
                    );
                    final data = result.data as Map<String, dynamic>?;
                    if (data?['error'] != null) {
                      setModalState(() {
                        error = data!['error'] as String;
                        loading = false;
                      });
                      return;
                    }
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Password updated successfully!')),
                      );
                    }
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.emoji,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final String emoji;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const Gap(6),
              Text(label,
                  style: Theme.of(context).textTheme.titleSmall,
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _SetTile extends StatelessWidget {
  const _SetTile({required this.set, required this.index});
  final SpellingSet set;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(child: Text('📝', style: TextStyle(fontSize: 22))),
        ),
        title: Text(set.name,
            style: Theme.of(context).textTheme.titleMedium),
        trailing: const Icon(Icons.chevron_right_rounded,
            color: AppColors.textLight),
      ),
    ).animate().fadeIn(delay: (index * 50).ms);
  }
}

class _DetachableSetTile extends ConsumerWidget {
  const _DetachableSetTile({
    required this.set,
    required this.index,
    required this.childId,
    required this.onDetached,
  });
  final SpellingSet set;
  final int index;
  final String childId;
  final VoidCallback onDetached;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(child: Text('📋', style: TextStyle(fontSize: 22))),
        ),
        title: Text(set.name,
            style: Theme.of(context).textTheme.titleMedium),
        trailing: IconButton(
          icon: const Icon(Icons.link_off_rounded, color: AppColors.textLight),
          tooltip: 'Remove from child',
          onPressed: () async {
            await supabase
                .from('child_personal_sets')
                .delete()
                .eq('set_id', set.id)
                .eq('child_id', childId);
            onDetached();
          },
        ),
      ),
    ).animate().fadeIn(delay: (index * 50).ms);
  }
}
