import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models/prayer_model.dart';

class ForcePrayerScreen extends StatefulWidget {
  final PrayerTime prayer;
  const ForcePrayerScreen({super.key, required this.prayer});
  @override State<ForcePrayerScreen> createState() => _ForcePrayerScreenState();
}

class _ForcePrayerScreenState extends State<ForcePrayerScreen>
    with SingleTickerProviderStateMixin {
  bool _canDelay = true;
  int _delaySeconds = 0;
  Timer? _delayTimer;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  int _quoteIndex = 0;

  final List<String> _quotes = [
    '"إن أول ما يُحاسب العبد عنه الصلاة"\nالنبي ﷺ',
    '"من فاتته صلاة العصر فكأنما وُتر أهله وماله"\nالنبي ﷺ',
    '"الصلاة عماد الدين — من تركها فقد هدم الدين"',
    '"بين الرجل وبين الشرك والكفر ترك الصلاة"\nالنبي ﷺ',
    '"لا تكن ممن تهاون بالصلاة\nفخسر الدنيا والآخرة"',
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.93, end: 1.07).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    Timer.periodic(const Duration(seconds: 7), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _quoteIndex = (_quoteIndex + 1) % _quotes.length);
    });
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _pulseCtrl.dispose();
    _delayTimer?.cancel();
    super.dispose();
  }

  void _onDelay() {
    if (!_canDelay) return;
    setState(() { _canDelay = false; _delaySeconds = 900; });
    _delayTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_delaySeconds <= 0) { t.cancel(); return; }
      if (mounted) setState(() => _delaySeconds--);
    });
  }

  String _fmtDelay(int s) =>
      '${(s ~/ 60).toString().padLeft(2,'0')}:${(s % 60).toString().padLeft(2,'0')}';

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) async {
      if (didPop) return;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.card,
          title: const Text('تهرب من الصلاة؟', style: TextStyle(color: AppColors.danger, fontSize: 18)),
          content: const Text('الخروج بدون صلاة = فاتتك وينزل شرفك\nهل أنت متأكد؟',
              style: TextStyle(color: AppColors.textPrimary)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false),
                child: const Text('ارجع وصلِّ', style: TextStyle(color: AppColors.success))),
            TextButton(onPressed: () => Navigator.pop(ctx, true),
                child: const Text('أتحمل المسؤولية', style: TextStyle(color: AppColors.danger))),
          ],
        ),
      );
      if (confirm == true && mounted) Navigator.pop(context, false);
    },
    child: Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          const Spacer(),
          ScaleTransition(
            scale: _pulseAnim,
            child: Text(widget.prayer.name.emoji, style: const TextStyle(fontSize: 80)),
          ),
          const SizedBox(height: 16),
          Text(widget.prayer.name.arabic,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 36, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('وقتها الآن', style: TextStyle(color: AppColors.primary.withOpacity(0.8), fontSize: 16)),
          const SizedBox(height: 36),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: Container(
              key: ValueKey(_quoteIndex),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.card, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(_quotes[_quoteIndex],
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, height: 1.6)),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('✓  صليت', style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
          if (_canDelay)
            TextButton(onPressed: _onDelay,
                child: const Text('أحتاج 15 دقيقة', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)))
          else if (_delaySeconds > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.warning)),
              child: Text('باقي ${_fmtDelay(_delaySeconds)} — لا تأجيل ثانٍ',
                  style: const TextStyle(color: AppColors.warning, fontSize: 14)),
            )
          else
            const Text('انتهى وقت التأجيل', style: TextStyle(color: AppColors.danger, fontSize: 14)),
          const SizedBox(height: 20),
        ]),
      )),
    ),
  );
}
