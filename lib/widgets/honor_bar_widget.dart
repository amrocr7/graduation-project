import 'package:flutter/material.dart';
import '../models/prayer_model.dart';
import '../theme/app_theme.dart';

class HonorBarWidget extends StatefulWidget {
  final HonorRecord honor;
  final bool animate;
  const HonorBarWidget({super.key, required this.honor, this.animate = false});
  @override State<HonorBarWidget> createState() => _HonorBarWidgetState();
}

class _HonorBarWidgetState extends State<HonorBarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.3, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Color get _levelColor {
    switch (widget.honor.level) {
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
    return LayoutBuilder(builder: (context, constraints) {
      final barWidth = constraints.maxWidth;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('ذليل', style: TextStyle(color: Colors.red[800], fontSize: 10)),
            AnimatedBuilder(
              animation: _glowAnim,
              builder: (_, __) => Text(
                widget.honor.level.arabic,
                style: TextStyle(
                  color: _levelColor.withOpacity(widget.animate ? _glowAnim.value : 1.0),
                  fontSize: 13, fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text('أسطورة', style: TextStyle(color: Colors.amber[200], fontSize: 10)),
          ]),
          const SizedBox(height: 6),
          Stack(children: [
            // خلفية
            Container(
              height: 22,
              decoration: BoxDecoration(
                color: const Color(0xFF1A0A00),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: const Color(0xFF8B6914), width: 1.5),
              ),
            ),
            // التعبئة
            AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              height: 22,
              width: barWidth * widget.honor.percentage,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_levelColor.withOpacity(0.4), _levelColor, _levelColor.withOpacity(0.6)],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // خطوط فاصلة
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(9, (i) => Container(
                width: 1, height: 22,
                color: const Color(0xFF8B6914).withOpacity(0.5),
              )),
            ),
          ]),
          const SizedBox(height: 4),
          Text('${widget.honor.points} نقطة شرف',
              style: TextStyle(color: _levelColor.withOpacity(0.6), fontSize: 10)),
        ]),
      );
    });
  }
}

class HonorChangeOverlay extends StatefulWidget {
  final int delta;
  final String reason;
  final bool levelUp;
  final bool levelDown;
  final VoidCallback onDone;
  const HonorChangeOverlay({
    super.key, required this.delta, required this.reason,
    required this.levelUp, required this.levelDown, required this.onDone,
  });
  @override State<HonorChangeOverlay> createState() => _HonorChangeOverlayState();
}

class _HonorChangeOverlayState extends State<HonorChangeOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500));
    _fadeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: 1), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 1, end: 1), weight: 60),
      TweenSequenceItem(tween: Tween<double>(begin: 1, end: 0), weight: 20),
    ]).animate(_ctrl);
    _slideAnim = Tween<double>(begin: 30, end: 0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward().then((_) { if (mounted) widget.onDone(); });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isPos = widget.delta > 0;
    final color = isPos ? AppColors.success : AppColors.danger;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Opacity(
        opacity: _fadeAnim.value,
        child: Transform.translate(
          offset: Offset(0, -_slideAnim.value),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color, width: 1.5),
              boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 12)],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (widget.levelUp || widget.levelDown) ...[
                Text(
                  widget.levelUp ? '⬆️ ارتفع الشرف' : '⬇️ انخفض الشرف',
                  style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                isPos ? '+${widget.delta} شرف' : '${widget.delta} شرف',
                style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              Text(widget.reason, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ]),
          ),
        ),
      ),
    );
  }
}
