import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/thread_provider.dart';
import '../providers/unread_count_provider.dart';
import '../utils/date_formatter.dart';
import '../widgets/error_view.dart';
import '../widgets/report_bottom_sheet.dart';
import '../widgets/shimmer_message_detail.dart';

class MessageDetailScreen extends ConsumerStatefulWidget {
  const MessageDetailScreen({super.key, required this.messageId});

  final String messageId;

  @override
  ConsumerState<MessageDetailScreen> createState() =>
      _MessageDetailScreenState();
}

class _MessageDetailScreenState extends ConsumerState<MessageDetailScreen> {
  final _replyController = TextEditingController();
  bool _hasMarkedRead = false;
  bool _hasReported = false;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  void _markAsReadOnce() {
    if (_hasMarkedRead) return;
    _hasMarkedRead = true;

    final thread = ref.read(threadProvider(widget.messageId));
    final detail = thread.value;
    if (detail != null && !detail.isRead) {
      markThreadAsRead(ref, widget.messageId);
      ref.read(unreadCountProvider.notifier).decrement();
    }
  }

  Future<void> _handleSendReply() async {
    final body = _replyController.text.trim();
    if (body.isEmpty) return;

    try {
      await sendReply(ref, widget.messageId, body);
      _replyController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send reply: $e')),
      );
    }
  }

  Future<void> _handleReport() async {
    final result = await showReportBottomSheet(
      context,
      messageId: widget.messageId,
    );
    if (result == true && mounted) {
      setState(() => _hasReported = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final threadState = ref.watch(threadProvider(widget.messageId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Message'),
        actions: [
          IconButton(
            icon: Icon(
              _hasReported ? Icons.flag : Icons.flag_outlined,
            ),
            tooltip: _hasReported ? 'Reported' : 'Report message',
            onPressed: _hasReported ? null : _handleReport,
          ),
        ],
      ),
      body: threadState.when(
        loading: () => const ShimmerMessageDetail(),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () =>
              ref.invalidate(threadProvider(widget.messageId)),
        ),
        data: (detail) {
          // Mark as read on first successful load
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _markAsReadOnce();
          });

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Message header
                    Semantics(
                      label: 'From ${detail.sender.displayName}, '
                          'to plate ${detail.recipientPlate.plateNumber}, '
                          '${formatMessageTimestamp(detail.createdAt)}',
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ExcludeSemantics(
                            child: CircleAvatar(
                              child: Text(
                                detail.sender.displayName.isNotEmpty
                                    ? detail.sender.displayName[0]
                                        .toUpperCase()
                                    : '?',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  detail.sender.displayName,
                                  style:
                                      theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'To: ${detail.recipientPlate.plateNumber}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color:
                                        theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            formatMessageTimestamp(detail.createdAt),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Subject
                    if (detail.subject != null &&
                        detail.subject!.isNotEmpty) ...[
                      Text(
                        detail.subject!,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    // Body
                    Text(
                      detail.body,
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    // Replies header
                    if (detail.replies.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Replies (${detail.replies.length})',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    // Replies list
                    ...detail.replies.map(
                      (reply) => Semantics(
                        label: 'Reply from ${reply.senderDisplayName}, '
                            '${formatMessageTimestamp(reply.createdAt)}, '
                            '${reply.body}',
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    reply.senderDisplayName,
                                    style:
                                        theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    formatMessageTimestamp(reply.createdAt),
                                    style:
                                        theme.textTheme.bodySmall?.copyWith(
                                      color:
                                          theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                reply.body,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Reply input bar
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _replyController,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _handleSendReply(),
                          decoration: const InputDecoration(
                            hintText: 'Write a reply...',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.send),
                        tooltip: 'Send reply',
                        onPressed: _handleSendReply,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
