import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/prayer_model.dart';
import '../services/storage_service.dart';
import '../services/location_service.dart';
import '../services/prayer_calculator.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _useManual = false;
  bool _loadingGPS = false;
  Map<PrayerName, TimeOfDay> _manualTimes = {};
  Map<String, double>? _location;
  List<PrayerTime> _calculatedTimes = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final useManual = await StorageService.getUseManual();
    final manualRaw = await StorageService.getManualTimes();
    final loc = await StorageService.getLocation();

    Map<PrayerName, TimeOfDay> manual = {};
    if (manualRaw != null) {
      for (final e in manualRaw.entries) {
        final parts = e.value.split(':');
        manual[e.key] = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
    }

    // احسب الأوقات التلقائية
    final lat = loc?['lat'] ?? 15.3694;
    final lng = loc?['lng'] ?? 44.1910;
    final calc = PrayerCalculator(latitude: lat, longitude: lng, date: DateTime.now());
    final times = calc.calculate();

    // لو ما في أوقات يدوية، ابدأ بالمحسوبة
    if (manual.isEmpty) {
      for (final t in times) {
        manual[t.name] = TimeOfDay(hour: t.time.hour, minute: t.time.minute);
      }
    }

    setState(() {
      _useManual = useManual;
      _manualTimes = manual;
      _location = loc;
      _calculatedTimes = times;
    });
  }

  Future<void> _getGPS() async {
    setState(() => _loadingGPS = true);
    final loc = await LocationService.getCurrentLocation();
    if (loc != null) {
      await StorageService.saveLocation(loc['lat']!, loc['lng']!);
      final calc = PrayerCalculator(
          latitude: loc['lat']!, longitude: loc['lng']!, date: DateTime.now());
      final times = calc.calculate();
      // حدّث الأوقات اليدوية بالمحسوبة الجديدة
      final newManual = <PrayerName, TimeOfDay>{};
      for (final t in times) {
        newManual[t.name] = TimeOfDay(hour: t.time.hour, minute: t.time.minute);
      }
      setState(() { _location = loc; _calculatedTimes = times; _manualTimes = newManual; _loadingGPS = false; });
      _showSnack('✓ تم تحديث الموقع والأوقات', AppColors.success);
    } else {
      setState(() => _loadingGPS = false);
      _showSnack('فشل تحديد الموقع — تأكد من تفعيل GPS', AppColors.danger);
    }
  }

  Future<void> _pickTime(PrayerName prayer) async {
    final current = _manualTimes[prayer] ?? TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _manualTimes[prayer] = picked);
    }
  }

  Future<void> _saveManual() async {
    final map = _manualTimes.map((k, v) =>
        MapEntry(k, '${v.hour.toString().padLeft(2,'0')}:${v.minute.toString().padLeft(2,'0')}'));
    await StorageService.saveManualTimes(map);
    await StorageService.setUseManual(_useManual);
    _showSnack('✓ تم الحفظ', AppColors.success);
  }

  Future<void> _export() async {
    final data = await StorageService.exportData();
    // نعرضه في dialog للنسخ
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('تصدير البيانات', style: TextStyle(color: AppColors.textPrimary)),
        content: SingleChildScrollView(
          child: SelectableText(data,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Future<void> _import() async {
    final controller = TextEditingController();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('استيراد البيانات', style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: controller,
          maxLines: 6,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 11),
          decoration: const InputDecoration(
            hintText: 'الصق بيانات JSON هنا...',
            hintStyle: TextStyle(color: AppColors.textSecondary),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء', style: TextStyle(color: AppColors.textSecondary))),
          TextButton(
            onPressed: () async {
              final ok = await StorageService.importData(controller.text);
              Navigator.pop(ctx);
              _showSnack(ok ? '✓ تم الاستيراد' : 'خطأ في البيانات', ok ? AppColors.success : AppColors.danger);
            },
            child: const Text('استيراد', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
      duration: const Duration(seconds: 2),
    ));
  }

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}';

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      title: const Text('الإعدادات', style: TextStyle(color: AppColors.textPrimary)),
      elevation: 0,
      actions: [
        TextButton(
          onPressed: _saveManual,
          child: const Text('حفظ', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
        ),
      ],
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ===== الموقع =====
        _sectionTitle('📍 الموقع'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDeco(),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (_location != null)
              Text(
                'lat: ${_location!['lat']!.toStringAsFixed(4)}  lng: ${_location!['lng']!.toStringAsFixed(4)}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              )
            else
              const Text('لم يُحدَّد الموقع بعد', style: TextStyle(color: AppColors.danger, fontSize: 12)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loadingGPS ? null : _getGPS,
                icon: _loadingGPS
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.my_location, size: 18),
                label: Text(_loadingGPS ? 'جاري التحديد...' : 'تحديد موقعي تلقائياً'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ]),
        ),

        const SizedBox(height: 20),

        // ===== أوقات الصلاة =====
        _sectionTitle('🕌 أوقات الصلاة'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDeco(),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('تعديل يدوي', style: TextStyle(color: AppColors.textPrimary)),
              Switch(
                value: _useManual,
                onChanged: (v) => setState(() => _useManual = v),
                activeColor: AppColors.primary,
              ),
            ]),
            const Divider(color: AppColors.border),
            ...PrayerName.values.map((p) {
              final manual = _manualTimes[p];
              final calc = _calculatedTimes.where((t) => t.name == p).firstOrNull;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      Text(p.emoji, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(p.arabic, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15)),
                        if (calc != null)
                          Text(
                            'محسوب: ${calc.time.hour.toString().padLeft(2,'0')}:${calc.time.minute.toString().padLeft(2,'0')}',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                          ),
                      ]),
                    ]),
                    GestureDetector(
                      onTap: _useManual ? () => _pickTime(p) : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _useManual ? AppColors.primaryGlow : AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _useManual ? AppColors.primary : AppColors.border,
                          ),
                        ),
                        child: Text(
                          manual != null ? _fmtTime(manual) : '--:--',
                          style: TextStyle(
                            color: _useManual ? AppColors.primary : AppColors.textSecondary,
                            fontSize: 16, fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ]),
        ),

        const SizedBox(height: 20),

        // ===== استيراد / تصدير =====
        _sectionTitle('💾 البيانات'),
        Row(children: [
          Expanded(child: _actionBtn('📤 تصدير', AppColors.primary, _export)),
          const SizedBox(width: 12),
          Expanded(child: _actionBtn('📥 استيراد', AppColors.warning, _import)),
        ]),

        const SizedBox(height: 30),
      ]),
    ),
  );

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(t, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
  );

  BoxDecoration _cardDeco() => BoxDecoration(
    color: AppColors.card,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: AppColors.border),
  );

  Widget _actionBtn(String label, Color color, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Center(child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold))),
    ),
  );
}
