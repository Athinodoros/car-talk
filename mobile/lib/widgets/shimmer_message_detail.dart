import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// A shimmer/skeleton loading placeholder for the message detail screen.
///
/// Mimics the layout of the message detail view including the avatar, sender
/// name, recipient line, subject, and body paragraphs.
class ShimmerMessageDetail extends StatelessWidget {
  const ShimmerMessageDetail({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final baseColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final highlightColor =
        isDark ? Colors.grey.shade600 : Colors.grey.shade100;

    return Semantics(
      excludeSemantics: true,
      label: 'Loading message details',
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: avatar + name/recipient + timestamp
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar placeholder
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: baseColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Name and recipient placeholders
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 14,
                          width: 120,
                          decoration: BoxDecoration(
                            color: baseColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 12,
                          width: 80,
                          decoration: BoxDecoration(
                            color: baseColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Timestamp placeholder
                  Container(
                    height: 10,
                    width: 50,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Subject placeholder
              Container(
                height: 18,
                width: 200,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),
              // Body line placeholders
              _buildBodyLine(baseColor, double.infinity),
              const SizedBox(height: 8),
              _buildBodyLine(baseColor, double.infinity),
              const SizedBox(height: 8),
              _buildBodyLine(baseColor, 240),
              const SizedBox(height: 8),
              _buildBodyLine(baseColor, 180),
              const SizedBox(height: 20),
              // Divider placeholder
              Container(
                height: 1,
                color: baseColor,
              ),
              const SizedBox(height: 16),
              // Replies header placeholder
              Container(
                height: 14,
                width: 100,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBodyLine(Color color, double width) {
    return Container(
      height: 12,
      width: width,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
