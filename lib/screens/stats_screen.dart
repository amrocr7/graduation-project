import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/prayer_model.dart';
import '../services/storage_service.dart';
import '../services/ai_coach_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  List<DayRecord> _days = [];
  AiPrayerInsight? _insight;

  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final days = await StorageService.getLastDays(30);
    final today = await StorageService.getTodayRecord();
    final streak = await StorageService.getStreak();
    final insight = AiCoachService.buildDailyInsight(
      recentDays: days,
      today: today,
      now: DateTime.now(),
      nextPrayer: null,
      streak: streak,
    );
    setState(() { _days = days; _insight = insight; });
  }

  int get _totalDone   => _days.fold(0, (s, d) => s + d.doneCount);
  int get _totalMissed => _days.fold(0, (s, d) => s + d.missedCount);
  int get _perfectDays => _days.where((d) => d.isPerfect).length;
  double get _rate     => _days.isEmpty ? 0 : _totalDone / (_days.length * 5) * 100;

  String _rateMsg() {
    if (_rate >= 95) return 'أنت تعيش الكود';
    if (_rate >= 80) return 'جيد — لكن لا مكان للتهاون';
    if (_rate >= 60) return 'النصف مو كافي';
    if (_rate >= 30) return 'الوضع خطير — واجه نفسك';
    return 'الصراحة: مو مصلٍّ حتى الآن';
  }

  Color get _rateColor {
    if (_rate >= 95) return AppColors.success;
    if (_rate >= 80) return AppColors.primary;
    if (_rate >= 60) return AppColors.warning;
    return AppColors.danger;
  }

  Map<PrayerName, int> get _byPrayer {
    final map = {for (var p in PrayerName.values) p: 0};
    for (final day in _days) {
      for (final p in PrayerName.values) {
        if (day.status[p] == 'done') map[p] = map[p]! + 1;
      }
    }
    return map;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      title: const Text('السجل الصادق', style: TextStyle(color: AppColors.textPrimary)),
      elevation: 0,
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // معدل الالتزام
        Container(
          width: double.infinity, padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
          child: Column(children: [
            const Text('معدل الالتزام (30 يوم)', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 8),
            Text('${_rate.toStringAsFixed(0)}%', style: TextStyle(color: _rateColor, fontSize: 48, fontWeight: FontWeight.bold)),
            Text(_rateMsg(), style: TextStyle(color: _rateColor, fontSize: 14)),
          ]),
        ),

        const SizedBox(height: 16),

        // الأرقام
        Row(children: [
          Expanded(child: _statCard('✓ صليت', '$_totalDone', AppColors.success)),
          const SizedBox(width: 12),
          Expanded(child: _statCard('✗ فاتت', '$_totalMissed', AppColors.danger)),
          const SizedBox(width: 12),
          Expanded(child: _statCard('🌟 كاملة', '$_perfectDays', AppColors.primary)),
        ]),

        const SizedBox(height: 16),
        if (_insight != null) ...[_aiStatsCard(), const SizedBox(height: 20)],
        const Text('أضعف صلاة عندك', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 12),

        // كل صلاة
        ..._byPrayer.entries.map((e) {
          final pct = _days.isEmpty ? 0.0 : e.value / _days.length;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
            child: Row(children: [
              Text(e.key.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(e.key.arabic, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15)),
                  Text('${e.value}/${_days.length}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ]),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation(_pctColor(pct)),
                    minHeight: 6,
                  ),
                ),
              ])),
            ]),
          );
        }),
      ]),
    ),
  );



  Widget _aiStatsCard() {
    final insight = _insight!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.6)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.psychology_alt, color: AppColors.primary, size: 20),
          SizedBox(width: 8),
          Text('تحليل الذكاء', style: TextStyle(color: AppColors.primary, fontSize: 15, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 8),
        Text(insight.message, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.45)),
        const SizedBox(height: 10),
        ...insight.actions.map((action) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text('• $action', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        )),
      ]),
    );
  }

  Color _pctColor(double p) {
    if (p >= 0.9) return AppColors.success;
    if (p >= 0.7) return AppColors.warning;
    return AppColors.danger;
  }

  Widget _statCard(String label, String value, Color color) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.4))),
    child: Column(children: [
      Text(value, style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12), textAlign: TextAlign.center),
    ]),
  );
}
