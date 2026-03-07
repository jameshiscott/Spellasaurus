import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/models/profile.dart';
import '../../../shared/widgets/spellasaurus_button.dart';

final _myChildrenProvider = FutureProvider<List<Profile>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  final data = await supabase
      .from('parent_children')
      .select('profiles!parent_children_child_id_fkey(*)')
      .eq('parent_id', user.id);
  return (data as List)
      .map((e) => Profile.fromJson(e['profiles!parent_children_child_id_fkey'] as Map<String, dynamic>))
      .toList();
});

class ParentDashboard extends ConsumerWidget {
  const ParentDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final children = ref.watch(_myChildrenProvider);
    final profile = ref.watch(currentProfileProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Children'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddChildDialog(context, ref),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Add Child'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(_myChildrenProvider.future),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            profile.when(
              data: (p) => Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Text('👨‍👧', style: TextStyle(fontSize: 40)),
                    const Gap(16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Welcome back,',
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: Colors.white70)),
                          Text(p?.fullName ?? '',
                              style: theme.textTheme.titleLarge
                                  ?.copyWith(color: Colors.white)),
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
            Text("Children", style: theme.textTheme.headlineSmall),
            const Gap(12),
            children.when(
              data: (list) => list.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 60),
                        child: Column(
                          children: [
                            const Text('👦', style: TextStyle(fontSize: 64))
                                .animate()
                                .scale(
                                    duration: 500.ms,
                                    curve: Curves.elasticOut),
                            const Gap(16),
                            Text(
                              "No children yet.\nTap + to add your child.",
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      children: list
                          .asMap()
                          .entries
                          .map((e) =>
                              _ChildCard(child: e.value, index: e.key))
                          .toList(),
                    ),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddChildDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final usernameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    DateTime? dob;
    bool obscure = true;
    String? error;

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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add Child',
                    style: Theme.of(ctx).textTheme.headlineSmall),
                const Gap(4),
                Text(
                  "Create a login your child will use to practice.",
                  style: Theme.of(ctx)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textMedium),
                ),
                const Gap(20),
                TextField(
                  controller: nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration:
                      const InputDecoration(labelText: "Child's Full Name"),
                ),
                const Gap(16),
                // Date of birth picker
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate:
                          DateTime.now().subtract(const Duration(days: 365 * 8)),
                      firstDate: DateTime(2005),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setModalState(() => dob = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: dob != null
                            ? AppColors.primary
                            : const Color(0xFFE0D9F0),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cake_outlined,
                            color: AppColors.textMedium),
                        const Gap(12),
                        Text(
                          dob != null
                              ? DateFormat('d MMMM yyyy').format(dob!)
                              : 'Date of Birth',
                          style:
                              Theme.of(ctx).textTheme.bodyLarge?.copyWith(
                                    color: dob != null
                                        ? AppColors.textDark
                                        : AppColors.textLight,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Gap(16),
                // Username field with @spellasaurus.com suffix
                Text('Child\'s Login Username',
                    style: Theme.of(ctx).textTheme.labelMedium?.copyWith(
                        color: AppColors.textMedium)),
                const Gap(6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: usernameCtrl,
                        keyboardType: TextInputType.text,
                        autocorrect: false,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          hintText: 'e.g. emma2015',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        onChanged: (_) => setModalState(() => error = null),
                      ),
                    ),
                    Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: 0.15),
                        borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(16)),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      alignment: Alignment.center,
                      child: Text('@spellasaurus.com',
                          style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const Gap(8),
                Text('Letters, numbers, dots and hyphens only',
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                        color: AppColors.textLight)),
                const Gap(16),
                TextField(
                  controller: passwordCtrl,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    labelText: "Password",
                    helperText: 'At least 8 characters',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setModalState(() => obscure = !obscure),
                    ),
                  ),
                ),
                if (error != null) ...[
                  const Gap(12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.error, size: 18),
                        const Gap(8),
                        Expanded(
                          child: Text(error!,
                              style: Theme.of(ctx).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.error)),
                        ),
                      ],
                    ),
                  ),
                ],
                const Gap(24),
                SpellasaurusButton(
                  label: 'Create Child Account',
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    final username = usernameCtrl.text.trim().toLowerCase();
                    final password = passwordCtrl.text;

                    if (name.isEmpty) {
                      setModalState(() => error = "Please enter the child's name.");
                      return;
                    }
                    if (username.isEmpty ||
                        !RegExp(r'^[a-z0-9._-]+$').hasMatch(username)) {
                      setModalState(() => error =
                          "Username can only contain letters, numbers, dots, hyphens and underscores.");
                      return;
                    }
                    if (password.length < 8) {
                      setModalState(
                          () => error = "Password must be at least 8 characters.");
                      return;
                    }
                    if (dob == null) {
                      setModalState(() => error = "Please select a date of birth.");
                      return;
                    }

                    setModalState(() => error = null);
                    final user = ref.read(currentUserProvider);
                    final result = await supabase.functions.invoke(
                      'create-child-account',
                      body: {
                        'full_name': name,
                        'username': username,
                        'password': password,
                        'date_of_birth':
                            dob!.toIso8601String().substring(0, 10),
                        'parent_id': user?.id,
                      },
                    );

                    final data = result.data as Map<String, dynamic>?;
                    if (data?['error'] != null) {
                      setModalState(() => error = data!['error'] as String);
                      return;
                    }

                    ref.invalidate(_myChildrenProvider);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                ),
                const Gap(8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChildCard extends StatelessWidget {
  const _ChildCard({required this.child, required this.index});
  final Profile child;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final age = child.dateOfBirth != null
        ? '${_age(child.dateOfBirth!)} years old'
        : '';

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push('/parent/child/${child.id}'),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _avatarColor(index).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    child.fullName.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: _avatarColor(index),
                    ),
                  ),
                ),
              ),
              const Gap(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(child.fullName, style: theme.textTheme.titleMedium),
                    if (age.isNotEmpty)
                      Text(age, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textLight),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 80).ms).slideX(begin: 0.05);
  }

  static Color _avatarColor(int i) {
    const colors = [
      AppColors.primary,
      AppColors.accentGreen,
      AppColors.accent,
      AppColors.secondary,
    ];
    return colors[i % colors.length];
  }

  static int _age(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }
}
