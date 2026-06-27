import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/prayer_model.dart';
import '../services/prayer_calculator.dart';
import '../services/storage_service.dart';
import '../services/honor_service.dart';
import '../widgets/honor_bar_widget.dart';
import 'force_prayer_screen.dart';
import 'streak_screen.dart';
import 'stats_screen.dart';
import 'code_screen.dart';
import 'honor_screen.dart';
import 'settings_screen.dart';
import 'dhikr_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<PrayerTime> _prayers = [];
  DayRecord? _todayRecord;
  int _streak = 0;
  HonorRecord? _honor;
  Timer? _timer;
  Duration _nextPrayerCountdown = Duration.zero;
  PrayerTime? _nextPrayer;

  // Honor overlay
  ({int delta, String reason, bool levelUp, bool levelDown})? _honorChange;

  @override
  void initState() { super.initState(); _load(); _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick()); }
  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  Future<void> _load() async {
    final useManual = await StorageService.getUseManual();
    List<PrayerTime> prayers;

    if (useManual) {
      final manual = await StorageService.getManualTimes();
      if (manual != null) {
        final now = DateTime.now();
        prayers = manual.entries.map((e) {
          final parts = e.value.split(':');
          final t = DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
          return PrayerTime(name: e.key, time: t);
        }).toList()..sort((a, b) => a.name.index.compareTo(b.name.index));
      } else {
        prayers = await _calcPrayers();
      }
    } else {
      prayers = await _calcPrayers();
    }

    final record = await StorageService.getTodayRecord();
    final streak = await StorageService.getStreak();
    final honor  = await StorageService.getHonor();
    setState(() { _prayers = prayers; _todayRecord = record; _streak = streak; _honor = honor; });
    _tick();
  }

  Future<List<PrayerTime>> _calcPrayers() async {
    final loc = await StorageService.getLocation();
    final lat = loc?['lat'] ?? 15.3694;
    final lng = loc?['lng'] ?? 44.1910;
    return PrayerCalculator(latitude: lat, longitude: lng, date: DateTime.now()).calculate();
  }

  void _tick() {
    final now = DateTime.now();
    for (final p in _prayers) {
      if (p.time.isAfter(now)) {
        setState(() { _nextPrayer = p; _nextPrayerCountdown = p.time.difference(now); });
        return;
      }
    }
    setState(() { _nextPrayer = null; });
  }

  String _fmt(Duration d) {
    final h = d.inHours, m = d.inMinutes % 60, s = d.inSeconds % 60;
    if (h > 0) return '${h}س ${m}د';
    if (m > 0) return '${m}د ${s}ث';
    return '${s}ث';
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 6)  return 'الليل عدو الفجر';
    if (h < 12) return 'صباح الطاعة';
    if (h < 17) return 'النهار أمانة';
    if (h < 20) return 'المغرب يطرق';
    return 'الليل للعبادة';
  }

  Future<void> _onPrayerTap(PrayerTime p, String status, bool isPast) async {
    if (status == 'done') return;
    if (!isPast) {
      final result = await Navigator.push<bool>(context,
          MaterialPageRoute(builder: (_) => ForcePrayerScreen(prayer: p)));
      if (result == true) {
        await StorageService.savePrayerStatus(p.name, 'done');
        final res = await HonorService.onPrayerDone(prayer: p.name, isOnTime: true, currentStreak: _streak);
        _showHonorChange(res.honor.history.first['delta'], res.honor.history.first['reason'], res.levelUp, res.levelDown);
        _load();
      }
    } else {
      showDialog(context: context, builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(p.name.arabic, style: const TextStyle(color: AppColors.danger, fontSize: 18)),
        content: const Text('صليتها أم فاتت؟', style: TextStyle(color: AppColors.textPrimary)),
        actions: [
          TextButton(child: const Text('فاتت', style: TextStyle(color: AppColors.danger)),
              onPressed: () async {
                await StorageService.savePrayerStatus(p.name, 'missed');
                final res = await HonorService.onPrayerMissed(p.name);
                Navigator.pop(ctx);
                _showHonorChange(res.honor.history.first['delta'], res.honor.history.first['reason'], res.levelUp, res.levelDown);
                _load();
              }),
          TextButton(child: const Text('قضيتها ✓', style: TextStyle(color: AppColors.success)),
              onPressed: () async {
                await StorageService.savePrayerStatus(p.name, 'done');
                final res = await HonorService.onPrayerDone(prayer: p.name, isOnTime: false, currentStreak: _streak);
                Navigator.pop(ctx);
                _showHonorChange(res.honor.history.first['delta'], res.honor.history.first['reason'], res.levelUp, res.levelDown);
                _load();
              }),
        ],
      ));
    }
  }

  void _showHonorChange(int delta, String reason, bool levelUp, bool levelDown) {
    setState(() => _honorChange = (delta: delta, reason: reason, levelUp: levelUp, levelDown: levelDown));
    Future.delayed(const Duration(milliseconds: 2600), () {
      if (mounted) setState(() => _honorChange = null);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: SafeArea(child: Stack(children: [
      SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _header(), const SizedBox(height: 20),
          _streakCard(), const SizedBox(height: 16),
          if (_nextPrayer != null) ...[_nextPrayerCard(), const SizedBox(height: 16)],
          _prayersList(), const SizedBox(height: 16),
          if (_honor != null) _honorSection(), const SizedBox(height: 16),
          _quickActions(), const SizedBox(height: 24),
          _bottomNav(),
        ]),
      ),
      // Honor Change Overlay
      if (_honorChange != null)
        Positioned(
          top: 80, left: 20, right: 20,
          child: HonorChangeOverlay(
            delta: _honorChange!.delta,
            reason: _honorChange!.reason,
            levelUp: _honorChange!.levelUp,
            levelDown: _honorChange!.levelDown,
            onDone: () { if (mounted) setState(() => _honorChange = null); },
          ),
        ),
    ])),
  );

  Widget _header() => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('الكود', style: TextStyle(color: AppColors.primary, fontSize: 28, fontWeight: FontWeight.bold)),
      Text(_greeting(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
    ]),
    Row(children: [
      GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DhikrScreen())),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppColors.primaryGlow, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.primary)),
          child: const Icon(Icons.grain, color: AppColors.primary, size: 20),
        ),
      ),
      const SizedBox(width: 8),
      GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())).then((_) => _load()),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
          child: const Icon(Icons.settings_outlined, color: AppColors.textSecondary, size: 20),
        ),
      ),
    ]),
  ]);

  Widget _streakCard() => GestureDetector(
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StreakScreen())),
    child: Container(
      width: double.infinity, padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: _streak > 0
            ? [const Color(0xFF1A1040), const Color(0xFF2A1A60)]
            : [AppColors.surface, AppColors.card]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _streak > 0 ? AppColors.primary : AppColors.border),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_streak > 0 ? '🔥 السلسلة' : '💀 السلسلة',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 2),
          Text('$_streak يوم', style: TextStyle(
            color: _streak > 0 ? AppColors.primary : AppColors.danger,
            fontSize: 20, fontWeight: FontWeight.bold,
          )),
        ]),
        if (_streak > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(color: AppColors.primaryGlow, borderRadius: BorderRadius.circular(16)),
            child: Text('$_streak 🔥', style: const TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
      ]),
    ),
  );

  Widget _nextPrayerCard() => Container(
    width: double.infinity, padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
    child: Column(children: [
      const Text('الصلاة القادمة', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      const SizedBox(height: 4),
      Text('${_nextPrayer!.name.emoji} ${_nextPrayer!.name.arabic}',
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 2),
      Text(_fmt(_nextPrayerCountdown),
          style: const TextStyle(color: AppColors.primary, fontSize: 34, fontWeight: FontWeight.bold)),
      Text('${_nextPrayer!.time.hour.toString().padLeft(2,'0')}:${_nextPrayer!.time.minute.toString().padLeft(2,'0')}',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
    ]),
  );

  Widget _prayersList() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('صلوات اليوم', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      const SizedBox(height: 10),
      ..._prayers.map(_prayerTile),
    ],
  );

  Widget _prayerTile(PrayerTime p) {
    final status   = _todayRecord?.status[p.name] ?? 'pending';
    final isDone   = status == 'done';
    final isMissed = status == 'missed';
    final isPast   = p.time.isBefore(DateTime.now());
    Color bc = isDone ? AppColors.success : isMissed ? AppColors.danger : isPast ? AppColors.warning : AppColors.border;
    IconData ic = isDone ? Icons.check_circle : isMissed ? Icons.cancel : isPast ? Icons.warning_amber : Icons.radio_button_unchecked;
    return GestureDetector(
      onTap: () => _onPrayerTap(p, status, isPast),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: bc, width: isDone || isMissed ? 1.5 : 1)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Text(p.name.emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.name.arabic, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
              Text('${p.time.hour.toString().padLeft(2,'0')}:${p.time.minute.toString().padLeft(2,'0')}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ]),
          ]),
          Icon(ic, color: bc, size: 24),
        ]),
      ),
    );
  }

  Widget _honorSection() => GestureDetector(
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HonorScreen())),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0500),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF8B6914), width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('شريط الشرف', style: TextStyle(color: Color(0xFF8B6914), fontSize: 12)),
          Icon(Icons.chevron_right, color: const Color(0xFF8B6914), size: 18),
        ]),
        const SizedBox(height: 8),
        HonorBarWidget(honor: _honor!),
      ]),
    ),
  );

  Widget _quickActions() => Row(children: [
    _qBtn('السبحة', Icons.grain, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DhikrScreen()))),
    const SizedBox(width: 10),
    _qBtn('الكود', Icons.shield_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CodeScreen()))),
    const SizedBox(width: 10),
    _qBtn('الإعدادات', Icons.settings, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())).then((_) => _load())),
  ]);

  Widget _qBtn(String label, IconData icon, VoidCallback onTap) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
        child: Column(children: [
          Icon(icon, color: AppColors.textSecondary, size: 22),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ]),
      ),
    ),
  );

  Widget _bottomNav() => Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
    _nb(Icons.bar_chart_rounded, 'الإحصائيات', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StatsScreen()))),
    _nb(Icons.local_fire_department, 'السلسلة', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StreakScreen()))),
    _nb(Icons.star, 'الشرف', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HonorScreen()))),
  ]);

  Widget _nb(IconData icon, String label, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Column(children: [
      Icon(icon, color: AppColors.textSecondary, size: 24),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
    ]),
  );
}
