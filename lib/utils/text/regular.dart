import 'package:flutter/material.dart';

class RegularText extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color color;
  final int? maxLine;

  const RegularText({
    super.key,
    required this.text,
    required this.fontSize,
    required this.color,
    this.maxLine,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: maxLine,
      overflow: maxLine != null ? TextOverflow.ellipsis : null,
      style: TextStyle(
        fontSize: fontSize,
        color: color,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}