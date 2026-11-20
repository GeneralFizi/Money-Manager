import 'package:material_ui/material_ui.dart';

import '../../home/view_models/app_view_model.dart';
import '../../../core/app_theme.dart';

/// Minimalist on-device Biometric unlock screen (Fingerprint / Face ID).
class LockScreen extends StatefulWidget {
  const LockScreen({super.key, required this.viewModel});

  final AppViewModel viewModel;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  bool _authenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerBiometric();
    });
  }

  Future<void> _triggerBiometric() async {
    if (_authenticating) return;
    setState(() => _authenticating = true);
    try {
      await widget.viewModel.unlockWithBiometrics();
    } finally {
      if (mounted) {
        setState(() => _authenticating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.moneyColors;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: colors.softTint,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(
                      Icons.fingerprint_rounded,
                      size: 36,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Money Manager',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Verify with Fingerprint or Face ID to access your local records',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.mutedText,
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _authenticating ? null : _triggerBiometric,
                      icon: const Icon(Icons.fingerprint_rounded),
                      label: Text(
                        _authenticating
                            ? 'Verifying...'
                            : 'Unlock with Biometrics',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
