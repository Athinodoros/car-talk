import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/inbox_message.dart';
import 'repository_providers.dart';
import 'socket_provider.dart';

class InboxState {
  const InboxState({
    this.messages = const [],
    this.nextCursor,
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  final List<InboxMessage> messages;
  final String? nextCursor;
  final bool hasMore;
  final bool isLoadingMore;

  InboxState copyWith({
    List<InboxMessage>? messages,
    String? nextCursor,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return InboxState(
      messages: messages ?? this.messages,
      nextCursor: nextCursor ?? this.nextCursor,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

final inboxProvider = AsyncNotifierProvider<InboxNotifier, InboxState>(
  InboxNotifier.new,
);

class InboxNotifier extends AsyncNotifier<InboxState> {
  @override
  Future<InboxState> build() async {
    // Watch for new messages via socket — triggers rebuild on new_message events
    ref.listen(newMessageStreamProvider, (prev, next) {
      next.whenData((_) => refresh());
    });

    final messageRepo = ref.read(messageRepositoryProvider);
    final result = await messageRepo.getInbox();

    return InboxState(
      messages: result.messages,
      nextCursor: result.nextCursor,
      hasMore: result.nextCursor != null,
    );
  }

  Future<void> fetchNextPage() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final messageRepo = ref.read(messageRepositoryProvider);
      final result = await messageRepo.getInbox(cursor: current.nextCursor);

      state = AsyncData(InboxState(
        messages: [...current.messages, ...result.messages],
        nextCursor: result.nextCursor,
        hasMore: result.nextCursor != null,
      ));
    } catch (e, st) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
      state = AsyncError(e, st);
    }
  }

  Future<void> refresh() async {
    final messageRepo = ref.read(messageRepositoryProvider);
    final result = await messageRepo.getInbox();

    state = AsyncData(InboxState(
      messages: result.messages,
      nextCursor: result.nextCursor,
      hasMore: result.nextCursor != null,
    ));
  }
}
