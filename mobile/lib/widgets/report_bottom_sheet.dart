import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/repository_providers.dart';

/// Reason options matching the backend enum.
enum ReportReason {
  spam('spam', 'Spam'),
  harassment('harassment', 'Harassment'),
  fraudulentPlate('fraudulent_plate', 'Fraudulent Plate'),
  other('other', 'Other');

  const ReportReason(this.value, this.label);

  final String value;
  final String label;
}

/// Shows a modal bottom sheet for reporting a message.
///
/// Returns `true` if the report was submitted successfully, `null` otherwise.
Future<bool?> showReportBottomSheet(
  BuildContext context, {
  required String messageId,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => ReportBottomSheet(messageId: messageId),
  );
}

class ReportBottomSheet extends ConsumerStatefulWidget {
  const ReportBottomSheet({super.key, required this.messageId});

  final String messageId;

  @override
  ConsumerState<ReportBottomSheet> createState() => _ReportBottomSheetState();
}

class _ReportBottomSheetState extends ConsumerState<ReportBottomSheet> {
  ReportReason? _selectedReason;
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_selectedReason == null || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final reportRepo = ref.read(reportRepositoryProvider);
      await reportRepo.createReport(
        reportedMessageId: widget.messageId,
        reason: _selectedReason!.value,
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
      );

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop(true);
      messenger.showSnackBar(
        const SnackBar(content: Text('Report submitted. Thank you.')),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      final statusCode = e.response?.statusCode;
      final String message;
      if (statusCode == 409) {
        message = 'You have already reported this message.';
      } else {
        message = 'Failed to submit report. Please try again.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Title
          Text(
            'Report Message',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Select a reason for reporting this message.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          // Reason options
          IgnorePointer(
            ignoring: _isSubmitting,
            child: RadioGroup<ReportReason>(
              groupValue: _selectedReason,
              onChanged: (value) => setState(() => _selectedReason = value),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: ReportReason.values
                    .map(
                      (reason) => RadioListTile<ReportReason>(
                        title: Text(reason.label),
                        value: reason,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Description field
          TextField(
            controller: _descriptionController,
            enabled: !_isSubmitting,
            maxLength: 500,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Additional details (optional)',
              hintText: 'Provide any extra context...',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Submit button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed:
                  (_selectedReason == null || _isSubmitting) ? null : _handleSubmit,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Submit Report'),
            ),
          ),
        ],
      ),
    );
  }
}
