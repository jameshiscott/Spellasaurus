import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/class_model.dart';
import '../../../shared/widgets/spellasaurus_button.dart';

final _classesForSchoolProvider =
    FutureProvider.family<List<ClassModel>, String>((ref, schoolId) async {
  final data = await supabase
      .from('classes')
      .select()
      .eq('school_id', schoolId)
      .order('name');
  return (data as List).map((e) => ClassModel.fromJson(e)).toList();
});

class ManageClassesScreen extends ConsumerWidget {
  const ManageClassesScreen({super.key, required this.schoolId});
  final String schoolId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classes = ref.watch(_classesForSchoolProvider(schoolId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Classes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddClassDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Class'),
      ),
      body: classes.when(
        data: (list) => list.isEmpty
            ? const _EmptyClasses()
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: list.length,
                itemBuilder: (ctx, i) =>
                    _ClassTile(cls: list[i], index: i),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showAddClassDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final yearCtrl = TextEditingController(
        text: DateTime.now().year.toString());
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
            Text('Add Class',
                style: Theme.of(ctx).textTheme.headlineSmall),
            const Gap(20),
            TextField(
              controller: nameCtrl,
              decoration:
                  const InputDecoration(labelText: 'Class Name (e.g. Year 3 Blue)'),
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
              label: 'Save Class',
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                await supabase.from('classes').insert({
                  'school_id': schoolId,
                  'name': nameCtrl.text.trim(),
                  'school_year': int.tryParse(yearCtrl.text) ??
                      DateTime.now().year,
                });
                ref.invalidate(_classesForSchoolProvider(schoolId));
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ClassTile extends StatelessWidget {
  const _ClassTile({required this.cls, required this.index});
  final ClassModel cls;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.secondary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(child: Text('📚', style: TextStyle(fontSize: 24))),
        ),
        title: Text(cls.name, style: theme.textTheme.titleMedium),
        subtitle: Text('Year ${cls.schoolYear}',
            style: theme.textTheme.bodySmall),
        trailing: const Icon(Icons.chevron_right_rounded,
            color: AppColors.textLight),
        onTap: () {},
      ),
    ).animate().fadeIn(delay: (index * 60).ms).slideX(begin: 0.05);
  }
}

class _EmptyClasses extends StatelessWidget {
  const _EmptyClasses();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📚', style: TextStyle(fontSize: 64))
              .animate()
              .scale(duration: 500.ms, curve: Curves.elasticOut),
          const Gap(16),
          Text('No classes yet.\nTap + to add one.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
