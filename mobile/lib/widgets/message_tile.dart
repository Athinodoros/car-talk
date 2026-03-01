import 'package:flutter/material.dart';

import '../utils/date_formatter.dart';

class MessageTile extends StatelessWidget {
  const MessageTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.isRead,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final DateTime timestamp;
  final bool isRead;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: onTap,
      leading: isRead
          ? const SizedBox(width: 12)
          : Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
        ),
      ),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        formatRelativeTime(timestamp),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
