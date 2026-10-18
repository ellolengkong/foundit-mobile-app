import 'package:flutter/material.dart';

/// Primary CTA button following UI_UX_DESIGN.md §3.
///
/// - Background: `primary` (indigo).
/// - Height: 48–52dp.
/// - Corner radius: 14dp.
/// - Full width by default.
///
/// Supports a [loading] state that disables the button and shows a spinner,
/// preventing duplicate submissions, and an optional [icon].
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return ElevatedButton(
        onPressed: null,
        child: const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        ),
      );
    }

    if (icon != null) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
      );
    }

    return ElevatedButton(onPressed: onPressed, child: Text(label));
  }
}
