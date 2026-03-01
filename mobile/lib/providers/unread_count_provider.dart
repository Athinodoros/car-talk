import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'repository_providers.dart';

final unreadCountProvider = AsyncNotifierProvider<UnreadCountNotifier, int>(
  UnreadCountNotifier.new,
);

class UnreadCountNotifier extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    final messageRepo = ref.read(messageRepositoryProvider);
    return messageRepo.getUnreadCount();
  }

  void decrement() {
    final current = state.value;
    if (current != null && current > 0) {
      state = AsyncData(current - 1);
    }
  }

  Future<void> refresh() async {
    final messageRepo = ref.read(messageRepositoryProvider);
    final count = await messageRepo.getUnreadCount();
    state = AsyncData(count);
  }
}
