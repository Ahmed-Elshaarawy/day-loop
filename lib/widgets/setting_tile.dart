import 'package:flutter/material.dart';

class SettingTile extends StatelessWidget {
  const SettingTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.isDestructive = false,
    this.trailing,
  });

  /// Leading icon shown inside a rounded container.
  final IconData icon;

  /// Title text.
  final String title;

  /// Optional subtitle.
  final String? subtitle;

  /// Tap callback.
  final VoidCallback? onTap;

  /// When true, paints the title & icon with redAccent and hides the default chevron.
  final bool isDestructive;

  /// Optional trailing widget (e.g., spinner). If null and not destructive, shows a chevron.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final Widget trailingWidget = trailing ??
        (isDestructive
            ? const SizedBox.shrink()
            : const Icon(Icons.arrow_forward_ios,
            color: Color(0xFF888888), size: 16));

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF333333),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isDestructive ? Colors.redAccent : const Color(0xFF888888),
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.redAccent : Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
        subtitle!,
        style: const TextStyle(color: Color(0xFF888888), fontSize: 12),
      ),
      trailing: trailingWidget,
    );
  }
}
