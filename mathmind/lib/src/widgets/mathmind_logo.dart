import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MathMindLogo extends StatelessWidget {
  const MathMindLogo({super.key, this.height = 28, this.fit = BoxFit.contain});

  final double height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/mathmind_logo.svg',
      height: height,
      fit: fit,
      semanticsLabel: 'MathMind',
    );
  }
}
