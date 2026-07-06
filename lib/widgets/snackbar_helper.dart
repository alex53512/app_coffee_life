import 'package:flutter/material.dart';

void showStyledSnackBar(BuildContext context, String message, {Color? backgroundColor, Duration? duration, SnackBarAction? action}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: duration ?? const Duration(seconds: 3),
      action: action,
    ),
  );
}
