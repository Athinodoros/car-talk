import 'package:flutter/material.dart';

import 'shimmer_message_tile.dart';

/// A reusable loading placeholder that shows [itemCount] shimmer tiles.
///
/// Used as a skeleton screen for inbox, sent, and other list views while
/// data is being fetched.
class ShimmerList extends StatelessWidget {
  const ShimmerList({super.key, this.itemCount = 8});

  /// The number of shimmer placeholder tiles to display.
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      excludeSemantics: true,
      label: 'Loading messages',
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: (context, index) => const ShimmerMessageTile(),
      ),
    );
  }
}
