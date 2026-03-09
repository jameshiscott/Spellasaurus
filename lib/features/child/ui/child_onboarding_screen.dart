import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/dino_data.dart';
import 'pick_display_name_screen.dart';
import 'pick_dino_screen.dart';

/// Two-step onboarding:  1) Pick a display name  2) Pick a dinosaur
class ChildOnboardingScreen extends ConsumerStatefulWidget {
  const ChildOnboardingScreen({super.key});

  @override
  ConsumerState<ChildOnboardingScreen> createState() =>
      _ChildOnboardingScreenState();
}

class _ChildOnboardingScreenState
    extends ConsumerState<ChildOnboardingScreen> {
  final _controller = PageController();
  String? _displayName;
  bool _saving = false;

  void _onNamePicked(String name) {
    setState(() => _displayName = name);
    _controller.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _onDinoPicked(DinoType type, DinoColor color) async {
    final user = ref.read(currentUserProvider);
    if (user == null || _displayName == null) return;

    setState(() => _saving = true);

    try {
      await supabase.rpc('complete_child_onboarding', params: {
        'p_child_id': user.id,
        'p_display_name': _displayName,
        'p_dino_type': type.name,
        'p_dino_color': color.name,
      });

      // Refresh profile so the router picks up onboarding_complete = true
      ref.invalidate(currentProfileProvider);

      if (mounted) context.go('/child');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView(
          controller: _controller,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            PickDisplayNameScreen(onNamePicked: _onNamePicked),
            PickDinoScreen(onDinoPicked: _onDinoPicked),
          ],
        ),
        if (_saving)
          const Positioned.fill(
            child: ColoredBox(
              color: Colors.black26,
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}
