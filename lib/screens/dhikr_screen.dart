import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';

class DhikrScreen extends StatefulWidget {
  const DhikrScreen({super.key});
  @override State<DhikrScreen> createState() => _DhikrScreenState();
}

class _DhikrScreenState extends State<DhikrScreen> with SingleTickerProviderStateMixin {
  int _count = 0;
  int _target = 100;
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  final List<Map<String, dynamic>> _adhkar = [
    {'text': 'سُبْحَانَ اللهِ', 'target': 33, 'color': const Color(0xFF4CAF50)},
    {'text': 'الْحَمْدُ لِلَّهِ', 'target': 33, 'color': const Color(0xFF2196F3)},
    {'text': 'اللهُ أَكْبَرُ', 'target': 34, 'color': const Color(0xFF9C27B0)},
    {'text': 'لَا إِلَهَ إِلَّا اللهُ', 'target': 100, 'color': const Color(0xFFFFD700)},
    {'text': 'أَسْتَغْفِرُ اللهَ', 'target': 100, 'color': const Color(0xFFFF5722)},
  ];
  int _selectedDhikr = 0;

  @override
  void initState() {
    super.initState();
    _target = _adhkar[0]['target'];
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.92)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _load();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    final c = await StorageService.getDhikrCount();
    setState(() => _count = c);
  }

  Future<void> _tap() async {
    HapticFeedback.lightImpact();
    _ctrl.forward().then((_) => _ctrl.reverse());
    final c = await StorageService.incrementDhikr();
    setState(() => _count = c);
  }

  Future<void> _reset() async {
    await StorageService.resetDhikr();
    setState(() => _count = 0);
  }

  @override
  Widget build(BuildContext context) {
    final dhikr = _adhkar[_selectedDhikr];
    final color = dhikr['color'] as Color;
    final progress = (_count % (_target == 0 ? 1 : _target)) / _target;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        title: const Text('السبحة', style: TextStyle(color: AppColors.textPrimary)),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: AppColors.textSecondary), onPressed: _reset),
        ],
      ),
      body: Column(children: [
        // اختيار الذكر
        SizedBox(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _adhkar.length,
            itemBuilder: (_, i) {
              final selected = i == _selectedDhikr;
              final c = _adhkar[i]['color'] as Color;
              return GestureDetector(
                onTap: () {
                  setState(() { _selectedDhikr = i; _target = _adhkar[i]['target']; });
                  _reset();
                },
                child: Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? c.withOpacity(0.2) : AppColors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: selected ? c : AppColors.border),
                  ),
                  child: Text(_adhkar[i]['text'],
                      style: TextStyle(color: selected ? c : AppColors.textSecondary, fontSize: 12)),
                ),
              );
            },
          ),
        ),

        const Spacer(),

        // دائرة التقدم
        Stack(alignment: Alignment.center, children: [
          SizedBox(
            width: 220, height: 220,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 8,
              backgroundColor: AppColors.card,
              color: color,
            ),
          ),
          Column(mainAxisSize: MainAxisSize.min, children: [
            Text('$_count', style: TextStyle(color: color, fontSize: 64, fontWeight: FontWeight.bold)),
            Text('/ $_target', style: const TextStyle(color: AppColors.textSecondary, fontSize: 18)),
          ]),
        ]),

        const SizedBox(height: 20),

        Text(dhikr['text'], style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('${_count ~/ _target} × مكتمل', style: const TextStyle(color: AppColors.textSecondary)),

        const Spacer(),

        // زر الضغط
        GestureDetector(
          onTap: _tap,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Container(
              width: 180, height: 180,
              margin: const EdgeInsets.only(bottom: 40),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.1),
                border: Border.all(color: color, width: 3),
                boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 20, spreadRadius: 2)],
              ),
              child: Center(child: Text(dhikr['text'],
                  textAlign: TextAlign.center,
                  style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold))),
            ),
          ),
        ),
      ]),
    );
  }
}
