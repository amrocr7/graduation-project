import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});
  @override State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _controller = TextEditingController();
  bool _hasPassword = false;
  bool _biometricEnabled = false;
  bool _busy = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  Future<void> _load() async {
    final hasPassword = await StorageService.hasAppPassword();
    final biometricEnabled = await StorageService.getBiometricUnlockEnabled();
    if (!mounted) return;
    setState(() { _hasPassword = hasPassword; _biometricEnabled = biometricEnabled; _busy = false; });
    if (!hasPassword) _openHome();
    if (hasPassword && biometricEnabled) _unlockBiometric();
  }

  Future<void> _unlockBiometric() async {
    final ok = await AuthService.unlockWithBiometrics();
    if (ok && mounted) _openHome();
  }

  Future<void> _unlockPassword() async {
    final ok = await AuthService.verifyPassword(_controller.text.trim());
    if (ok) {
      _openHome();
    } else {
      setState(() => _error = 'كلمة المرور غير صحيحة');
    }
  }

  void _openHome() => Navigator.of(context).pushReplacement(
    MaterialPageRoute(builder: (_) => const HomeScreen()),
  );

  @override
  Widget build(BuildContext context) {
    if (_busy || !_hasPassword) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.lock_rounded, color: AppColors.primary, size: 72),
            const SizedBox(height: 18),
            const Text('الكود مقفل', style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('أدخل كلمة المرور أو استخدم البصمة', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              obscureText: true,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                errorText: _error,
                hintText: 'كلمة المرور',
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onSubmitted: (_) => _unlockPassword(),
            ),
            const SizedBox(height: 14),
            SizedBox(width: double.infinity, child: ElevatedButton.icon(
              onPressed: _unlockPassword,
              icon: const Icon(Icons.login),
              label: const Text('فتح'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            )),
            if (_biometricEnabled) TextButton.icon(
              onPressed: _unlockBiometric,
              icon: const Icon(Icons.fingerprint, color: AppColors.primary),
              label: const Text('استخدام البصمة', style: TextStyle(color: AppColors.primary)),
            ),
          ]),
        ),
      ),
    );
  }
}
