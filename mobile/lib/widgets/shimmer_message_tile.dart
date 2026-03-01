import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// A shimmer/skeleton loading placeholder that mimics the [MessageTile] layout.
///
/// Displays gray rounded rectangles in place of the unread indicator, title,
/// subtitle, and timestamp while data is loading. Adapts base and highlight
/// colors to the current light/dark theme.
class ShimmerMessageTile extends StatelessWidget {
  const ShimmerMessageTile({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final baseColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final highlightColor =
        isDark ? Colors.grey.shade600 : Colors.grey.shade100;

    return Semantics(
      excludeSemantics: true,
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: ListTile(
          leading: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: baseColor,
              shape: BoxShape.circle,
            ),
          ),
          title: Container(
            height: 14,
            width: 120,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              height: 12,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          trailing: Container(
            height: 10,
            width: 40,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }
}
