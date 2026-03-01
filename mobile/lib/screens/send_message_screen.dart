import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/ad_provider.dart';
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

class _SendMessageScreenState extends ConsumerState<SendMessageScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _plateController = TextEditingController();
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isLoading = false;
  bool _showSuccess = false;

  late final AnimationController _successAnimController;
  late final Animation<double> _successOpacity;

  @override
  void initState() {
    super.initState();
    _bodyController.addListener(_onBodyChanged);
    // Preload an interstitial so it is ready by the time the user sends.
    ref.read(adProvider.notifier).preloadInterstitial();

    _successAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _successOpacity = TweenSequence<double>([
      // Fade in over the first 20%
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
      // Hold fully visible for 50%
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: 50,
      ),
      // Fade out over the last 30%
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_successAnimController);

    _successAnimController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _showSuccess = false);
      }
    });
  }

  @override
  void dispose() {
    _successAnimController.dispose();
    _bodyController.removeListener(_onBodyChanged);
    _plateController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _onBodyChanged() {
    setState(() {});
  }

  void _playSendSuccess() {
    setState(() => _showSuccess = true);
    _successAnimController.forward(from: 0);
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

      // Track the send and show an interstitial every Nth send.
      final adNotifier = ref.read(adProvider.notifier);
      adNotifier.incrementSendCount();
      final adState = ref.read(adProvider);
      if (adState.shouldShowInterstitial) {
        adNotifier.showInterstitial();
        // Preload the next interstitial for future sends.
        adNotifier.preloadInterstitial();
      }

      _formKey.currentState!.reset();
      _plateController.clear();
      _subjectController.clear();
      _bodyController.clear();

      _playSendSuccess();
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Message'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
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
          // Success overlay
          if (_showSuccess)
            Positioned.fill(
              child: FadeTransition(
                opacity: _successOpacity,
                child: Semantics(
                  liveRegion: true,
                  label: 'Message sent successfully',
                  child: Container(
                    color: theme.colorScheme.surface.withAlpha(230),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 72,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Message sent!',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
