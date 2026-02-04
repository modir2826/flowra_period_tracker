import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  const PrimaryButton({super.key, required this.label, this.onPressed, this.busy = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: busy ? null : onPressed,
        child: busy
            ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Theme.of(context).colorScheme.onPrimary)))
            : Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white)),
      ),
    );
  }
}
