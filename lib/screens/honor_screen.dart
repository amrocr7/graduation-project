import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/prayer_model.dart';
import '../services/storage_service.dart';
import '../services/honor_service.dart';
import '../widgets/honor_bar_widget.dart';

class HonorScreen extends StatefulWidget {
  const HonorScreen({super.key});
  @override State<HonorScreen> createState() => _HonorScreenState();
}

class _HonorScreenState extends State<HonorScreen> {
  HonorRecord? _honor;
  final _actionController = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _actionController.dispose(); super.dispose(); }

  Future<void> _load() async {
    final h = await StorageService.getHonor();
    setState(() => _honor = h);
  }

  Color get _levelColor {
    if (_honor == null) return AppColors.primary;
    switch (_honor!.level) {
      case HonorLevel.dishonorable: return const Color(0xFF8B0000);
      case HonorLevel.sinner:       return const Color(0xFFB22222);
      case HonorLevel.repentant:    return const Color(0xFFCD853F);
      case HonorLevel.upright:      return const Color(0xFFDAA520);
      case HonorLevel.honorable:    return const Color(0xFFFFD700);
      case HonorLevel.legend:       return const Color(0xFFFFFFFF);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_honor == null) return const Scaffold(backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        title: const Text('الشرف', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [

          // ===== البطاقة الرئيسية =====
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF0D0500),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF8B6914), width: 2),
              boxShadow: [BoxShadow(color: _levelColor.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)],
            ),
            child: Column(children: [
              // أيقونة المستوى
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1A0A00),
                  border: Border.all(color: _levelColor, width: 2.5),
                  boxShadow: [BoxShadow(color: _levelColor.withOpacity(0.5), blurRadius: 15)],
                ),
                child: Icon(
                  _honorIcon(_honor!.level),
                  color: _levelColor, size: 40,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _honor!.level.arabic,
                style: TextStyle(color: _levelColor, fontSize: 28, fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: _levelColor, blurRadius: 8)]),
              ),
              const SizedBox(height: 4),
              Text(_honorDesc(_honor!.level),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
              const SizedBox(height: 20),

              // شريط الشرف الكبير
              HonorBarWidget(honor: _honor!, animate: true),

              const SizedBox(height: 12),
              Text('${_honor!.points} / 1000 نقطة',
                  style: TextStyle(color: _levelColor, fontSize: 16, fontWeight: FontWeight.bold)),
            ]),
          ),

          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showActionDialog,
              icon: const Icon(Icons.add_task),
              label: const Text('تسجيل عمل جيد أو خطأ'),
              style: ElevatedButton.styleFrom(backgroundColor: _levelColor, foregroundColor: Colors.black),
            ),
          ),

          const SizedBox(height: 20),

          // ===== جدول النقاط =====
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('جدول النقاط', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 12),
              _pointRow('صلاة في وقتها', '+60', AppColors.success),
              _pointRow('قضاء صلاة', '+20', AppColors.warning),
              _pointRow('صلاة فاتت', '-120', AppColors.danger),
              _pointRow('يوم متتالي', '+15', AppColors.primary),
              _pointRow('أسبوع كامل', '+30', AppColors.primary),
              _pointRow('عمل جيد صغير / متوسط / كبير', '+10 / +25 / +60', AppColors.success),
              _pointRow('خطأ صغير / متوسط / كبير', '-10 / -35 / -80', AppColors.danger),
            ]),
          ),

          const SizedBox(height: 20),

          // ===== آخر التغييرات =====
          if (_honor!.history.isNotEmpty) ...[
            const Align(alignment: Alignment.centerRight,
                child: Text('آخر التغييرات', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))),
            const SizedBox(height: 10),
            ..._honor!.history.take(10).map((h) {
              final delta = h['delta'] as int;
              final isPos = delta > 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: (isPos ? AppColors.success : AppColors.danger).withOpacity(0.3),
                  ),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(h['reason'] ?? '', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                  Text(
                    isPos ? '+$delta' : '$delta',
                    style: TextStyle(
                      color: isPos ? AppColors.success : AppColors.danger,
                      fontWeight: FontWeight.bold, fontSize: 14,
                    ),
                  ),
                ]),
              );
            }),
          ],
        ]),
      ),
    );
  }


  Future<void> _showActionDialog() async {
    int delta = 25;
    String category = 'متوسط';
    _actionController.clear();
    final result = await showDialog<({String title, int delta, String category})>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('تسجيل عمل', style: TextStyle(color: AppColors.textPrimary)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: _actionController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              hintText: 'مثال: صدقة، غضب، تأخير صلاة...',
              hintStyle: TextStyle(color: AppColors.textSecondary),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: delta,
            dropdownColor: AppColors.card,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'التصنيف', labelStyle: TextStyle(color: AppColors.textSecondary)),
            items: const [
              DropdownMenuItem(value: 10, child: Text('عمل جيد صغير  +10')),
              DropdownMenuItem(value: 25, child: Text('عمل جيد متوسط  +25')),
              DropdownMenuItem(value: 60, child: Text('عمل جيد كبير  +60')),
              DropdownMenuItem(value: -10, child: Text('خطأ صغير  -10')),
              DropdownMenuItem(value: -35, child: Text('خطأ متوسط  -35')),
              DropdownMenuItem(value: -80, child: Text('خطأ كبير  -80')),
            ],
            onChanged: (v) => setDialogState(() {
              delta = v ?? 25;
              category = delta.abs() >= 60 ? 'كبير' : delta.abs() >= 25 ? 'متوسط' : 'صغير';
            }),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: AppColors.textSecondary))),
          TextButton(
            onPressed: () {
              final title = _actionController.text.trim();
              if (title.isEmpty) return;
              Navigator.pop(ctx, (title: title, delta: delta, category: category));
            },
            child: const Text('تسجيل', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      )),
    );
    if (result == null) return;
    await HonorService.applyAction(title: result.title, delta: result.delta, category: result.category);
    await _load();
  }


  IconData _honorIcon(HonorLevel level) {
    switch (level) {
      case HonorLevel.dishonorable: return Icons.cancel;
      case HonorLevel.sinner:       return Icons.warning;
      case HonorLevel.repentant:    return Icons.refresh;
      case HonorLevel.upright:      return Icons.shield;
      case HonorLevel.honorable:    return Icons.star;
      case HonorLevel.legend:       return Icons.auto_awesome;
    }
  }

  String _honorDesc(HonorLevel level) {
    switch (level) {
      case HonorLevel.dishonorable: return 'الصلاة متروكة والقلب مُظلم\nهذا ليس الكود';
      case HonorLevel.sinner:       return 'تُصلي أحياناً وتتركها أحياناً\nلا تكن نصف نصف';
      case HonorLevel.repentant:    return 'في طريق الرجوع\nاستمر ولا تتوقف';
      case HonorLevel.upright:      return 'تُصلي وتُحاسب نفسك\nأنت تتبع الكود';
      case HonorLevel.honorable:    return 'الصلاة صارت جزءاً منك\nحافظ عليها';
      case HonorLevel.legend:       return 'أسطورة — الكود حياتك\nلا تكسر السلسلة';
    }
  }

  Widget _pointRow(String label, String points, Color color) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(points, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    ]),
  );
}
