import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/inbox_provider.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_view.dart';
import '../widgets/message_tile.dart';
import '../widgets/shimmer_list.dart';

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(inboxProvider.notifier).fetchNextPage();
    }
  }

  Future<void> _onRefresh() async {
    await ref.read(inboxProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final inboxState = ref.watch(inboxProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inbox'),
      ),
      body: Column(
        children: [
          Expanded(
            child: inboxState.when(
              loading: () => const ShimmerList(),
              error: (error, _) => ErrorView(
                message: error.toString(),
                onRetry: _onRefresh,
              ),
              data: (state) {
                if (state.messages.isEmpty) {
                  return Semantics(
                    label: 'Inbox is empty. Pull down to refresh.',
                    child: RefreshIndicator(
                      onRefresh: _onRefresh,
                      child: ListView(
                        children: const [
                          SizedBox(height: 200),
                          EmptyState(
                            icon: Icons.inbox_outlined,
                            title: 'No messages yet',
                            subtitle:
                                'Messages sent to your plates will appear here.',
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Semantics(
                  label: '${state.messages.length} messages. Pull down to refresh.',
                  child: RefreshIndicator(
                    onRefresh: _onRefresh,
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount:
                          state.messages.length + (state.isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == state.messages.length) {
                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: Center(
                              child: Semantics(
                                label: 'Loading more messages',
                                child: const CircularProgressIndicator(),
                              ),
                            ),
                          );
                        }

                        final message = state.messages[index];
                        return MessageTile(
                          title: message.senderDisplayName,
                          subtitle: message.subject ?? message.body,
                          timestamp: message.createdAt,
                          isRead: message.isRead,
                          onTap: () => context.go('/inbox/${message.id}'),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          const BannerAdWidget(),
        ],
      ),
    );
  }
}
