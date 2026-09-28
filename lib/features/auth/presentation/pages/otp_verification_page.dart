import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/app_routes.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_providers.dart';

class OtpVerificationPage extends ConsumerStatefulWidget {
  const OtpVerificationPage({
    super.key,
    required this.challengeId,
    required this.destination,
    required this.rememberMe,
  });

  final String challengeId;
  final String destination;
  final bool rememberMe;

  @override
  ConsumerState<OtpVerificationPage> createState() =>
      _OtpVerificationPageState();
}

class _OtpVerificationPageState extends ConsumerState<OtpVerificationPage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_submitting || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final session = await ref.read(verifyLoginOtpUseCaseProvider)(
        widget.challengeId,
        _codeController.text.trim(),
      );
      await ref.read(authServiceProvider).setRememberMe(widget.rememberMe);
      await ref.read(sessionManagerProvider).markActive();
      ref.read(authProvider.notifier).setSession(session);
      if (mounted) context.go(AppRoutes.home);
    } on Object {
      if (mounted) {
        setState(
          () => _error =
              'That code is invalid or expired. Request a new sign-in code and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('OTP verification')),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.mark_email_read_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Check your inbox',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter the 6-digit sign-in code sent to ${widget.destination.isEmpty ? 'your registered email' : widget.destination}.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    textAlign: TextAlign.center,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    maxLength: 6,
                    onFieldSubmitted: (_) => _verify(),
                    decoration: const InputDecoration(
                      labelText: '6-digit code',
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
                    validator: (value) {
                      final code = value?.trim() ?? '';
                      if (!RegExp(r'^\d{6}$').hasMatch(code)) {
                        return 'Enter the 6-digit code';
                      }
                      return null;
                    },
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _submitting ? null : _verify,
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Verify and sign in'),
                  ),
                  TextButton(
                    onPressed: _submitting
                        ? null
                        : () => context.go(AppRoutes.login),
                    child: const Text('Back to sign in'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}