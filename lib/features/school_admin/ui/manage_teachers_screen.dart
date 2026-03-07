import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/profile.dart';

final _teachersForSchoolProvider =
    FutureProvider.family<List<Profile>, String>((ref, schoolId) async {
  // Fetch profiles that are teachers linked to classes in this school
  final data = await supabase
      .from('profiles')
      .select()
      .eq('role', 'teacher');
  return (data as List).map((e) => Profile.fromJson(e)).toList();
});

class ManageTeachersScreen extends ConsumerWidget {
  const ManageTeachersScreen({super.key, required this.schoolId});
  final String schoolId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teachers = ref.watch(_teachersForSchoolProvider(schoolId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teachers'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: teachers.when(
        data: (list) => list.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('👩‍🏫', style: TextStyle(fontSize: 64))
                        .animate()
                        .scale(duration: 500.ms, curve: Curves.elasticOut),
                    const Gap(16),
                    Text('No teachers yet.',
                        style: theme.textTheme.bodyMedium),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: list.length,
                itemBuilder: (ctx, i) => Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor:
                          AppColors.primaryLight.withOpacity(0.3),
                      child: Text(
                        list[i].fullName.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    title: Text(list[i].fullName,
                        style: theme.textTheme.titleMedium),
                  ),
                ).animate().fadeIn(delay: (i * 60).ms),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
