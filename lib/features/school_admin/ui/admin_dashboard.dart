import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/models/school.dart';
import '../../../shared/widgets/spellasaurus_button.dart';

final _adminSchoolsProvider = FutureProvider<List<School>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  final data = await supabase
      .from('schools')
      .select()
      .eq('admin_id', user.id)
      .order('name');
  return (data as List).map((e) => School.fromJson(e)).toList();
});

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schools = ref.watch(_adminSchoolsProvider);
    final profile = ref.watch(currentProfileProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('School Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) context.go(AppRoutes.login);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSchoolDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add School'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(_adminSchoolsProvider.future),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Welcome banner
            profile.when(
              data: (p) => Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Text('🏢', style: TextStyle(fontSize: 40)),
                    const Gap(16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back,',
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: Colors.white70),
                          ),
                          Text(
                            p?.fullName ?? '',
                            style: theme.textTheme.titleLarge
                                ?.copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: -0.05),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const Gap(24),
            Text('Your Schools', style: theme.textTheme.headlineSmall),
            const Gap(12),
            schools.when(
              data: (list) => list.isEmpty
                  ? _EmptyState(
                      emoji: '🏫',
                      message:
                          'No schools yet.\nTap + to add your first school.',
                    )
                  : Column(
                      children: list
                          .asMap()
                          .entries
                          .map((e) => _SchoolCard(
                                school: e.value,
                                index: e.key,
                              ))
                          .toList(),
                    ),
              loading: () => const Center(
                  child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              )),
              error: (e, _) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSchoolDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
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
            Text('Add School',
                style: Theme.of(ctx).textTheme.headlineSmall),
            const Gap(20),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'School Name'),
              textCapitalization: TextCapitalization.words,
            ),
            const Gap(16),
            TextField(
              controller: addressCtrl,
              decoration:
                  const InputDecoration(labelText: 'Address (optional)'),
            ),
            const Gap(24),
            SpellasaurusButton(
              label: 'Save School',
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                final user = ref.read(currentUserProvider);
                await supabase.from('schools').insert({
                  'name': nameCtrl.text.trim(),
                  'address': addressCtrl.text.trim().isEmpty
                      ? null
                      : addressCtrl.text.trim(),
                  'admin_id': user?.id,
                });
                ref.invalidate(_adminSchoolsProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SchoolCard extends StatelessWidget {
  const _SchoolCard({required this.school, required this.index});
  final School school;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text('🏫', style: TextStyle(fontSize: 28)),
                ),
              ),
              const Gap(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(school.name, style: theme.textTheme.titleMedium),
                    if (school.address != null)
                      Text(school.address!,
                          style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              PopupMenuButton(
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    onTap: () => context.push(
                        '/admin/classes/${school.id}'),
                    child: const Row(children: [
                      Icon(Icons.class_outlined),
                      Gap(8),
                      Text('Manage Classes'),
                    ]),
                  ),
                  PopupMenuItem(
                    onTap: () => context.push(
                        '/admin/teachers/${school.id}'),
                    child: const Row(children: [
                      Icon(Icons.people_outlined),
                      Gap(8),
                      Text('Manage Teachers'),
                    ]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 80).ms).slideX(begin: 0.05);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.emoji, required this.message});
  final String emoji;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 64))
                .animate()
                .scale(duration: 500.ms, curve: Curves.elasticOut),
            const Gap(16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
