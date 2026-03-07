import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/class_model.dart';
import '../../../shared/models/profile.dart';

final _classDetailProvider =
    FutureProvider.family<ClassModel?, String>((ref, classId) async {
  final data = await supabase
      .from('classes')
      .select()
      .eq('id', classId)
      .maybeSingle();
  if (data == null) return null;
  return ClassModel.fromJson(data);
});

final _classStudentsProvider =
    FutureProvider.family<List<Profile>, String>((ref, classId) async {
  final data = await supabase
      .from('class_students')
      .select('profiles(*)')
      .eq('class_id', classId);
  return (data as List)
      .map((e) => Profile.fromJson(e['profiles'] as Map<String, dynamic>))
      .toList();
});

class ClassDetailScreen extends ConsumerWidget {
  const ClassDetailScreen({super.key, required this.classId});
  final String classId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cls = ref.watch(_classDetailProvider(classId));
    final students = ref.watch(_classStudentsProvider(classId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: cls.when(
          data: (c) => Text(c?.name ?? 'Class'),
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('Class'),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Quick action cards
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  emoji: '📝',
                  label: 'Spelling Sets',
                  color: AppColors.primary,
                  onTap: () =>
                      context.push('/teacher/class/$classId/sets'),
                ),
              ),
              const Gap(12),
              Expanded(
                child: _ActionCard(
                  emoji: '👥',
                  label: 'Students',
                  color: AppColors.accentGreen,
                  onTap: () {},
                ),
              ),
            ],
          ),
          const Gap(28),
          Text('Students (${students.valueOrNull?.length ?? 0})',
              style: theme.textTheme.headlineSmall),
          const Gap(12),
          students.when(
            data: (list) => list.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text('No students enrolled yet.',
                        style: theme.textTheme.bodyMedium),
                  )
                : Column(
                    children: list
                        .asMap()
                        .entries
                        .map((e) => Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      AppColors.primaryLight.withOpacity(0.2),
                                  child: Text(
                                    e.value.fullName
                                        .substring(0, 1)
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                title: Text(e.value.fullName,
                                    style: theme.textTheme.titleMedium),
                              ),
                            ).animate().fadeIn(delay: (e.key * 50).ms))
                        .toList(),
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
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
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 28)),
                ),
              ),
              const Gap(8),
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
