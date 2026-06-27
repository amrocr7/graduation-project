import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/prayer_model.dart';
import '../services/storage_service.dart';

class StreakScreen extends StatefulWidget {
  const StreakScreen({super.key});
  @override State<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends State<StreakScreen> {
  int _streak = 0;
  List<DayRecord> _days = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final streak = await StorageService.getStreak();
    final days   = await StorageService.getLastDays(30);
    setState(() { _streak = streak; _days = days; });
  }

  String _streakMsg() {
    if (_streak == 0)  return 'السلسلة منكسرة\nابدأ اليوم من الصفر';
    if (_streak < 3)   return 'البداية دائماً صعبة\nاستمر';
    if (_streak < 7)   return 'أسبوع واحد يغير العادة\nأنت في الطريق';
    if (_streak < 30)  return 'شهر كامل بدون انكسار\nهذا ليس تحفيزاً — هذا واقعك';
    return 'هذا هو الكود\nأنت تثبته كل يوم';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      title: const Text('السلسلة', style: TextStyle(color: AppColors.textPrimary)),
      elevation: 0,
    ),
    body: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        // الرقم الكبير
        Container(
          width: double.infinity, padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: _streak > 0
                ? [const Color(0xFF1A1040), const Color(0xFF2A1A60)]
                : [AppColors.surface, AppColors.card]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _streak > 0 ? AppColors.primary : AppColors.danger, width: 1.5),
          ),
          child: Column(children: [
            Text(_streak > 0 ? '🔥' : '💀', style: const TextStyle(fontSize: 52)),
            const SizedBox(height: 8),
            Text('$_streak', style: TextStyle(
              color: _streak > 0 ? AppColors.primary : AppColors.danger,
              fontSize: 64, fontWeight: FontWeight.bold,
            )),
            Text('يوم متتالي', style: const TextStyle(color: AppColors.textSecondary, fontSize: 16)),
            const SizedBox(height: 16),
            Text(_streakMsg(), textAlign: TextAlign.center,
                style: TextStyle(color: _streak > 0 ? AppColors.textPrimary : AppColors.danger, fontSize: 15, height: 1.5)),
          ]),
        ),

        const SizedBox(height: 24),
        const Align(alignment: Alignment.centerRight,
            child: Text('آخر 30 يوم', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))),
        const SizedBox(height: 12),

        // شبكة الأيام
        Expanded(child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7, crossAxisSpacing: 6, mainAxisSpacing: 6,
          ),
          itemCount: _days.length,
          itemBuilder: (_, i) {
            final day = _days[_days.length - 1 - i];
            final done = day.doneCount;
            Color color;
            if (done == 5)      color = AppColors.success;
            else if (done >= 3) color = AppColors.warning;
            else if (done > 0)  color = AppColors.danger.withOpacity(0.6);
            else                color = AppColors.card;
            return Tooltip(
              message: '${day.date}\n$done/5',
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Center(child: Text('$done', style: const TextStyle(fontSize: 10, color: Colors.white70))),
              ),
            );
          },
        )),

        // Legend
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _legend(AppColors.success, '5/5'),
          const SizedBox(width: 16),
          _legend(AppColors.warning, '3-4'),
          const SizedBox(width: 16),
          _legend(AppColors.danger.withOpacity(0.6), '1-2'),
          const SizedBox(width: 16),
          _legend(AppColors.card, '0'),
        ]),
      ]),
    ),
  );

  Widget _legend(Color color, String label) => Row(children: [
    Container(width: 14, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
  ]);
}
