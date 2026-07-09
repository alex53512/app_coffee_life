import 'package:flutter/material.dart';

class OvalBottomClipper extends CustomClipper<Path> {
  final double offset;

  const OvalBottomClipper({this.offset = 60});

  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - offset);
    path.quadraticBezierTo(
      size.width / 2,
      size.height + offset,
      size.width,
      size.height - offset,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(OvalBottomClipper old) => old.offset != offset;
}
