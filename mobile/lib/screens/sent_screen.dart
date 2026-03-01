import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/sent_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_view.dart';
import '../widgets/message_tile.dart';
import '../widgets/shimmer_list.dart';

class SentScreen extends ConsumerStatefulWidget {
  const SentScreen({super.key});

  @override
  ConsumerState<SentScreen> createState() => _SentScreenState();
}

class _SentScreenState extends ConsumerState<SentScreen> {
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
      ref.read(sentProvider.notifier).fetchNextPage();
    }
  }

  Future<void> _onRefresh() async {
    await ref.read(sentProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final sentState = ref.watch(sentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sent'),
      ),
      body: sentState.when(
        loading: () => const ShimmerList(),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: _onRefresh,
        ),
        data: (state) {
          if (state.messages.isEmpty) {
            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: ListView(
                children: const [
                  SizedBox(height: 200),
                  EmptyState(
                    icon: Icons.outbox_outlined,
                    title: 'No sent messages',
                    subtitle: 'Messages you send will appear here.',
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView.builder(
              controller: _scrollController,
              itemCount: state.messages.length + (state.isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == state.messages.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final message = state.messages[index];
                return MessageTile(
                  title: message.recipientPlateNumber,
                  subtitle: message.subject ?? message.body,
                  timestamp: message.createdAt,
                  isRead: message.isRead,
                  onTap: () => context.go('/sent/${message.id}'),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
