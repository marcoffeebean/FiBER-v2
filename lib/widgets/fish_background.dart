import 'package:flutter/material.dart';

class FishBackground extends StatelessWidget {
  const FishBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: Container(color: Colors.lightBlue.shade50)),
        Positioned.fill(
          child: Opacity(
            opacity: 0.7,
            child: Image.asset(
              'lib/assets/images/Minimalist Blue Fish Pattern.png',
              fit: BoxFit.cover,
              color: Colors.lightBlue.shade200,
              colorBlendMode: BlendMode.modulate,
            ),
          ),
        ),
        child,
      ],
    );
  }
}
