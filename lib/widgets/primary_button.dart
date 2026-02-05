import 'package:flutter/material.dart';

class PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  const PrimaryButton({super.key, required this.label, this.onPressed, this.busy = false});

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final canPress = !widget.busy && widget.onPressed != null;
    final glowColor = Colors.pink.shade400.withOpacity(0.45);
    return SizedBox(
      width: double.infinity,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: _pressed
              ? [
                  BoxShadow(
                    color: glowColor,
                    blurRadius: 18,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: GestureDetector(
          onTapDown: canPress ? (_) => setState(() => _pressed = true) : null,
          onTapUp: canPress ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: canPress ? () => setState(() => _pressed = false) : null,
          child: ElevatedButton(
            onPressed: widget.busy ? null : widget.onPressed,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: Colors.pink.shade600,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: widget.busy
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Theme.of(context).colorScheme.onPrimary),
                    ),
                  )
                : Text(
                    widget.label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white),
                  ),
          ),
        ),
      ),
    );
  }
}
