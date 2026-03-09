import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import '../../../core/theme/app_colors.dart';
import '../data/dino_data.dart';

class PickDinoScreen extends StatefulWidget {
  const PickDinoScreen({super.key, required this.onDinoPicked});

  final void Function(DinoType type, DinoColor color) onDinoPicked;

  @override
  State<PickDinoScreen> createState() => _PickDinoScreenState();
}

class _PickDinoScreenState extends State<PickDinoScreen> {
  DinoType? _selectedType;
  DinoColor _selectedColor = DinoColor.green;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            const Gap(24),
            Text(
              'Choose Your Dino! 🦖',
              style: theme.textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ).animate().fadeIn(),
            const Gap(8),
            Text(
              'Pick a dinosaur and a colour. You can unlock more later!',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 100.ms),
            const Gap(20),

            // ── Preview ─────────────────────────────────────────────────
            if (_selectedType != null)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: _selectedColor.color.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    DinoAvatar(
                      type: _selectedType!,
                      color: _selectedColor,
                      size: 120,
                    ),
                    const Gap(8),
                    Text(
                      '${_selectedColor.displayName} ${_selectedType!.displayName}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ).animate().scale(duration: 300.ms, curve: Curves.elasticOut),

            if (_selectedType != null) const Gap(16),

            // ── Colour selector ─────────────────────────────────────────
            if (_selectedType != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: DinoColor.values.map((dc) {
                    final isSelected = dc == _selectedColor;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = dc),
                      child: AnimatedContainer(
                        duration: 200.ms,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        width: isSelected ? 44 : 36,
                        height: isSelected ? 44 : 36,
                        decoration: BoxDecoration(
                          color: dc.color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: dc.color.withOpacity(0.5),
                                    blurRadius: 10,
                                  ),
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 20)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ).animate().fadeIn(delay: 100.ms),

            const Gap(16),

            // ── Dino grid ───────────────────────────────────────────────
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.0,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemCount: DinoType.values.length,
                itemBuilder: (_, i) {
                  final dt = DinoType.values[i];
                  final isSelected = dt == _selectedType;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedType = dt),
                    child: AnimatedContainer(
                      duration: 200.ms,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: isSelected
                            ? Border.all(
                                color: _selectedColor.color, width: 3)
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color:
                                      _selectedColor.color.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          DinoAvatar(
                            type: dt,
                            color: _selectedColor,
                            size: 80,
                          ),
                          const Gap(8),
                          Text(
                            dt.displayName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight:
                                  isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected
                                  ? _selectedColor.color
                                  : AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: (i * 50).ms)
                      .scale(begin: const Offset(0.9, 0.9), delay: (i * 50).ms);
                },
              ),
            ),

            // ── Confirm button ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _selectedType == null
                      ? null
                      : () =>
                          widget.onDinoPicked(_selectedType!, _selectedColor),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.primary.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                  ),
                  child: Text(
                    _selectedType == null
                        ? 'Pick a dinosaur first!'
                        : "That's my dino! 🦕",
                    style: theme.textTheme.labelLarge,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
