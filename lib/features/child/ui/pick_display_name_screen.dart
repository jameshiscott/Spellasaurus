import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../core/theme/app_colors.dart';
import '../data/display_name_generator.dart';

class PickDisplayNameScreen extends ConsumerStatefulWidget {
  const PickDisplayNameScreen({super.key, required this.onNamePicked});

  final void Function(String displayName) onNamePicked;

  @override
  ConsumerState<PickDisplayNameScreen> createState() =>
      _PickDisplayNameScreenState();
}

class _PickDisplayNameScreenState extends ConsumerState<PickDisplayNameScreen> {
  String? _generatedName;
  String? _selectedName;
  bool _checking = false;
  String? _error;
  final _rng = Random();

  void _generateFromCategory(NameCategory category) {
    setState(() {
      _generatedName = category.generate(_rng);
      _selectedName = null;
      _error = null;
    });
  }

  Future<void> _confirmName() async {
    final name = _generatedName;
    if (name == null) return;

    setState(() {
      _checking = true;
      _error = null;
    });

    try {
      final available = await supabase
          .rpc('is_display_name_available', params: {'p_name': name});

      if (available == true) {
        setState(() => _selectedName = name);
        widget.onNamePicked(name);
      } else {
        setState(() => _error = 'That name is taken! Try generating another.');
      }
    } catch (e) {
      setState(() => _error = 'Something went wrong. Try again.');
    } finally {
      setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Gap(24),
              Text(
                'Pick Your Name! 🎉',
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ).animate().fadeIn(),
              const Gap(8),
              Text(
                'Tap a category to generate a fun display name.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 100.ms),
              const Gap(20),

              // ── Generated name preview ──────────────────────────────────
              if (_generatedName != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _generatedName!,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_error != null) ...[
                        const Gap(8),
                        Text(
                          _error!,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: AppColors.secondary),
                        ),
                      ],
                    ],
                  ),
                ).animate().scale(duration: 300.ms, curve: Curves.elasticOut),

              if (_generatedName != null) const Gap(12),

              // ── Confirm button ──────────────────────────────────────────
              if (_generatedName != null && _selectedName == null)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _checking ? null : _confirmName,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentGreen,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _checking
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text(
                            "I'm keeping this one! ✅",
                            style: theme.textTheme.labelLarge,
                          ),
                  ),
                ).animate().fadeIn(delay: 200.ms),

              const Gap(16),

              // ── Category buttons ────────────────────────────────────────
              Expanded(
                child: ListView.separated(
                  itemCount: nameCategories.length,
                  separatorBuilder: (_, __) => const Gap(10),
                  itemBuilder: (_, i) {
                    final cat = nameCategories[i];
                    return _CategoryButton(
                      category: cat,
                      onTap: () => _generateFromCategory(cat),
                      index: i,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryButton extends StatelessWidget {
  const _CategoryButton({
    required this.category,
    required this.onTap,
    required this.index,
  });

  final NameCategory category;
  final VoidCallback onTap;
  final int index;

  static const _gradients = [
    [Color(0xFFFF6B6B), Color(0xFFFF8E53)], // Animal Chaos
    [Color(0xFFFFC832), Color(0xFFFF8E53)], // Food
    [Color(0xFF6C3CE1), Color(0xFF9B6FF5)], // Gamer
    [Color(0xFF2196F3), Color(0xFF00BCD4)], // Hero
    [Color(0xFF8D6E63), Color(0xFFBCAAA4)], // Historical
    [Color(0xFFE91E63), Color(0xFFAB47BC)], // Goofiness
    [Color(0xFF607D8B), Color(0xFF455A64)], // Why does this exist
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final grad = _gradients[index % _gradients.length];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: grad,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: grad[0].withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(
              category.emoji,
              style: const TextStyle(fontSize: 32),
            ),
            const Gap(16),
            Expanded(
              child: Text(
                category.label,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Icon(Icons.refresh_rounded,
                color: Colors.white70, size: 28),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 60).ms).slideX(begin: 0.1);
  }
}
