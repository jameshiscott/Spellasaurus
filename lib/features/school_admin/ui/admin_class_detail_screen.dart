import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/class_model.dart';
import '../../../shared/models/profile.dart';
import '../../../shared/widgets/spellasaurus_button.dart';

final _classDetailProvider =
    FutureProvider.family<ClassModel, String>((ref, classId) async {
  final data = await supabase
      .from('classes')
      .select()
      .eq('id', classId)
      .single();
  return ClassModel.fromJson(data);
});

final _assignedTeacherProvider =
    FutureProvider.family<Profile?, String>((ref, classId) async {
  final cls = await ref.watch(_classDetailProvider(classId).future);
  if (cls.teacherId == null) return null;
  final data = await supabase
      .from('profiles')
      .select()
      .eq('id', cls.teacherId!)
      .maybeSingle();
  if (data == null) return null;
  return Profile.fromJson(data);
});

final _allTeachersProvider = FutureProvider<List<Profile>>((ref) async {
  final data = await supabase
      .from('profiles')
      .select()
      .eq('role', 'teacher')
      .order('full_name');
  return (data as List).map((e) => Profile.fromJson(e)).toList();
});

class AdminClassDetailScreen extends ConsumerWidget {
  const AdminClassDetailScreen({super.key, required this.classId});
  final String classId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classAsync = ref.watch(_classDetailProvider(classId));
    final teacherAsync = ref.watch(_assignedTeacherProvider(classId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Class Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: classAsync.when(
        data: (cls) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Class info card ──────────────────────────────────────────
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                            child: Text('📚', style: TextStyle(fontSize: 28))),
                      ),
                      const Gap(16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(cls.name,
                                style: Theme.of(context).textTheme.headlineSmall),
                            Text('Year ${cls.schoolYear}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: AppColors.textLight)),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Edit class details',
                        icon: const Icon(Icons.edit_outlined,
                            color: AppColors.primary),
                        onPressed: () =>
                            _showEditClassDialog(context, ref, cls),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),

            const Gap(20),

            // ── Teacher section ──────────────────────────────────────────
            Text('Assigned Teacher',
                    style: Theme.of(context).textTheme.titleMedium)
                .animate()
                .fadeIn(delay: 100.ms),
            const Gap(12),
            teacherAsync.when(
              data: (teacher) => _TeacherCard(
                teacher: teacher,
                onAssign: () => _showAssignTeacherDialog(context, ref, cls),
                onRemove: teacher == null
                    ? null
                    : () => _removeTeacher(ref, cls),
              ).animate().fadeIn(delay: 150.ms),
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showEditClassDialog(
      BuildContext context, WidgetRef ref, ClassModel cls) {
    final nameCtrl = TextEditingController(text: cls.name);
    final yearCtrl =
        TextEditingController(text: cls.schoolYear.toString());

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
            Text('Edit Class',
                style: Theme.of(ctx).textTheme.headlineSmall),
            const Gap(20),
            TextField(
              controller: nameCtrl,
              decoration:
                  const InputDecoration(labelText: 'Class Name'),
              textCapitalization: TextCapitalization.words,
            ),
            const Gap(16),
            TextField(
              controller: yearCtrl,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'School Year (e.g. 2025)'),
            ),
            const Gap(24),
            SpellasaurusButton(
              label: 'Save Changes',
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                await supabase.from('classes').update({
                  'name': nameCtrl.text.trim(),
                  'school_year': int.tryParse(yearCtrl.text) ??
                      cls.schoolYear,
                }).eq('id', cls.id);
                ref.invalidate(_classDetailProvider(classId));
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignTeacherDialog(
      BuildContext context, WidgetRef ref, ClassModel cls) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final teachers = ref.watch(_allTeachersProvider);
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Assign Teacher',
                  style: Theme.of(ctx).textTheme.headlineSmall),
              const Gap(16),
              teachers.when(
                data: (list) {
                  if (list.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                          'No teachers found. Create a teacher account first.',
                          style: Theme.of(ctx).textTheme.bodyMedium),
                    );
                  }
                  return ConstrainedBox(
                    constraints: BoxConstraints(
                        maxHeight:
                            MediaQuery.of(ctx).size.height * 0.4),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final t = list[i];
                        final isCurrent = t.id == cls.teacherId;
                        return ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? AppColors.primary.withOpacity(0.15)
                                  : AppColors.bgDark.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(
                                child: Text('👩‍🏫',
                                    style: TextStyle(fontSize: 20))),
                          ),
                          title: Text(t.fullName),
                          trailing: isCurrent
                              ? const Icon(Icons.check_circle_rounded,
                                  color: AppColors.primary)
                              : null,
                          onTap: () async {
                            await supabase
                                .from('classes')
                                .update({'teacher_id': t.id})
                                .eq('id', cls.id);
                            ref.invalidate(_classDetailProvider(classId));
                            ref.invalidate(
                                _assignedTeacherProvider(classId));
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
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

  Future<void> _removeTeacher(WidgetRef ref, ClassModel cls) async {
    await supabase
        .from('classes')
        .update({'teacher_id': null})
        .eq('id', cls.id);
    ref.invalidate(_classDetailProvider(classId));
    ref.invalidate(_assignedTeacherProvider(classId));
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: child,
      ),
    );
  }
}

class _TeacherCard extends StatelessWidget {
  const _TeacherCard({
    required this.teacher,
    required this.onAssign,
    this.onRemove,
  });
  final Profile? teacher;
  final VoidCallback onAssign;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (teacher == null) {
      return Card(
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.textLight.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.textLight.withOpacity(0.3),
                  style: BorderStyle.solid),
            ),
            child: const Center(
                child: Icon(Icons.person_add_outlined,
                    color: AppColors.textLight)),
          ),
          title: Text('No teacher assigned',
              style:
                  theme.textTheme.bodyMedium?.copyWith(color: AppColors.textLight)),
          trailing: TextButton(
            onPressed: onAssign,
            child: const Text('Assign'),
          ),
        ),
      );
    }

    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
              child: Text('👩‍🏫', style: TextStyle(fontSize: 24))),
        ),
        title: Text(teacher!.fullName, style: theme.textTheme.titleMedium),
        subtitle: const Text('Teacher'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: onAssign,
              child: const Text('Change'),
            ),
            IconButton(
              icon: const Icon(Icons.link_off_rounded,
                  color: AppColors.textLight),
              tooltip: 'Remove teacher',
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}
