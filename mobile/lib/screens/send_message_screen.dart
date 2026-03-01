import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/repository_providers.dart';
import '../utils/plate_formatter.dart';
import '../utils/validators.dart';
import '../widgets/loading_button.dart';
import '../widgets/plate_input_field.dart';

class SendMessageScreen extends ConsumerStatefulWidget {
  const SendMessageScreen({super.key});

  @override
  ConsumerState<SendMessageScreen> createState() => _SendMessageScreenState();
}

class _SendMessageScreenState extends ConsumerState<SendMessageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _plateController = TextEditingController();
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _bodyController.addListener(_onBodyChanged);
  }

  @override
  void dispose() {
    _bodyController.removeListener(_onBodyChanged);
    _plateController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _onBodyChanged() {
    setState(() {});
  }

  Future<void> _handleSend() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final subject = _subjectController.text.trim();
      await ref.read(messageRepositoryProvider).sendMessage(
            plateNumber: normalizePlate(_plateController.text),
            subject: subject.isEmpty ? null : subject,
            body: _bodyController.text.trim(),
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message sent successfully')),
      );

      _formKey.currentState!.reset();
      _plateController.clear();
      _subjectController.clear();
      _bodyController.clear();
    } on DioException catch (e) {
      if (!mounted) return;
      final message =
          (e.response?.data is Map)
              ? (e.response!.data as Map)['message'] as String? ??
                  'Failed to send message'
              : 'Failed to send message';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Message'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PlateInputField(
                controller: _plateController,
                validator: validatePlate,
                label: 'Recipient License Plate',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _subjectController,
                validator: validateSubject,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Subject (optional)',
                  prefixIcon: Icon(Icons.subject),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bodyController,
                validator: validateMessageBody,
                maxLines: 8,
                maxLength: 2000,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  labelText: 'Message',
                  alignLabelWithHint: true,
                  border: const OutlineInputBorder(),
                  counterText:
                      '${_bodyController.text.length} / 2000',
                ),
              ),
              const SizedBox(height: 24),
              LoadingButton(
                label: 'Send',
                isLoading: _isLoading,
                onPressed: _handleSend,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
