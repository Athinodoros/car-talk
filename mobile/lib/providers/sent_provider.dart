import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/sent_message.dart';
import 'repository_providers.dart';

class SentState {
  const SentState({
    this.messages = const [],
    this.nextCursor,
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  final List<SentMessage> messages;
  final String? nextCursor;
  final bool hasMore;
  final bool isLoadingMore;

  SentState copyWith({
    List<SentMessage>? messages,
    String? nextCursor,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return SentState(
      messages: messages ?? this.messages,
      nextCursor: nextCursor ?? this.nextCursor,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

final sentProvider = AsyncNotifierProvider<SentNotifier, SentState>(
  SentNotifier.new,
);

class SentNotifier extends AsyncNotifier<SentState> {
  @override
  Future<SentState> build() async {
    final messageRepo = ref.read(messageRepositoryProvider);
    final result = await messageRepo.getSent();

    return SentState(
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
      final result = await messageRepo.getSent(cursor: current.nextCursor);

      state = AsyncData(SentState(
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
    final result = await messageRepo.getSent();

    state = AsyncData(SentState(
      messages: result.messages,
      nextCursor: result.nextCursor,
      hasMore: result.nextCursor != null,
    ));
  }
}
