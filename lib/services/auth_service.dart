import 'package:local_auth/local_auth.dart';
import 'storage_service.dart';

class AuthService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> canUseBiometrics() async {
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  static Future<bool> unlockWithBiometrics() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'افتح تطبيق الكود بالبصمة أو قفل الجهاز',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  static Future<bool> verifyPassword(String password) async {
    final saved = await StorageService.getAppPassword();
    return saved != null && saved == password;
  }
}
