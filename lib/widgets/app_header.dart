import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class AppHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget>? actions;
  final double height;
  final bool rounded;
  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.height = 44,
    this.rounded = true,
  });

  factory AppHeader.back(
    BuildContext context,
    String title, {
    String? subtitle,
    List<Widget>? actions,
    double height = 44,
    bool rounded = true,
    VoidCallback? onBack,
  }) {
    return AppHeader(
      title: title,
      subtitle: subtitle,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
        onPressed: onBack ?? () => Navigator.pop(context),
      ),
      actions: actions,
      height: height,
      rounded: rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final header = Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      decoration: const BoxDecoration(color: AppColors.verdeOscuro),
      child: Row(
        children: [
          if (leading != null) leading!,
          if (leading != null) const SizedBox(width: 1),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(title,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                        fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                if (subtitle != null)
                  Text(subtitle!,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                          fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white70)),
              ],
            ),
          ),
          if (actions != null) ...actions!,
        ],
      ),
    );

    if (!rounded) return header;

    return DecoratedBox(
      decoration: const BoxDecoration(
        boxShadow: [BoxShadow(color: Color(0x18000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        child: SafeArea(
          bottom: false,
          child: header,
        ),
      ),
    );
  }
}
