import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

/// 100% local on-device biometric authentication wrapper (Fingerprint / Face ID).
class BiometricService {
  BiometricService({
    LocalAuthentication? auth,
    this.isSupportedOverride,
  }) : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;
  final bool? isSupportedOverride;

  Future<bool> isBiometricAvailable() async {
    if (isSupportedOverride != null) return isSupportedOverride!;
    if (kIsWeb) return false;
    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      if (!supported || !canCheck) return false;
      final enrolled = await _auth.getAvailableBiometrics();
      return enrolled.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate() async {
    if (isSupportedOverride == false || kIsWeb) return false;
    try {
      return await _auth.authenticate(
        localizedReason: 'Unlock your local Money Manager',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }
}
