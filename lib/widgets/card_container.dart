import 'package:flutter/material.dart';

class CardContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const CardContainer({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Color(0x05000000), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }
}
