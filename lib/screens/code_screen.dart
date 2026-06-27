import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CodeScreen extends StatelessWidget {
  const CodeScreen({super.key});

  static const _rules = [
    ('القاعدة الأولى', 'الأذان = توقف فوري', 'أي شيء تسويه يتوقف. مو بعد الجزء. الآن.', '⚡'),
    ('القاعدة الثانية', '"بعدين" و"بكره" محذوفتان', 'لما يقولها عقلك = قم تتوضأ فوراً. هذا الرد الوحيد.', '🚫'),
    ('القاعدة الثالثة', 'لا حوار داخلي', 'أي تفكير في "هل أصلي؟" = الشيطان يتكلم. الرد: قم.', '🤫'),
    ('القاعدة الرابعة', 'الوضوء يسبق القرار', 'ما تسأل نفسك. تقوم وتتوضأ. بعدها الجسم يمشي لوحده.', '💧'),
  ];

  static const _triggers = [
    ('⚠️ محفز الليل', 'ما يجي نوم + ضغط الدراسة', 'شغّل البلايستيشن أو يوتيوب هادئ. ممنوع تفتح المتصفح بدون هدف.'),
    ('👁️ محفز بصري', 'شفت شيء بالغلط', 'قم من مكانك فوراً. غير الغرفة. توضأ — حتى لو ما صليت بعدها.'),
    ('😮‍💨 محفز الضغط', 'ضغط دراسة أو تعب نفسي', 'البلايستيشن حليفك هنا. شغّله كدرع مو كمكافأة.'),
  ];

  static const _afterFall = [
    ('ممنوع', 'كره النفس والاحتقار واللعن', false),
    ('ممنوع', 'الندم المفرط الذي يُضعف', false),
    ('مسموح', 'استغفر جملة واحدة', true),
    ('مسموح', 'قم اتوضأ — انتهى', true),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      title: const Text('الكود', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
      elevation: 0,
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // الجملة الرئيسية
        Container(
          width: double.infinity, padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF1A1040), Color(0xFF2A1A60)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary, width: 1.5),
          ),
          child: Column(children: [
            const Text('🛡️', style: TextStyle(fontSize: 36)),
            const SizedBox(height: 12),
            const Text('"أنا مو ما أقدر\nأنا اخترت\nوأقدر أختار غير"',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.bold, height: 1.6)),
          ]),
        ),

        const SizedBox(height: 28),
        _sectionTitle('القواعد الثابتة — لا تُفاوَض'),
        const SizedBox(height: 12),

        ..._rules.map((r) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r.$4, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.$1, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              const SizedBox(height: 2),
              Text(r.$2, style: const TextStyle(color: AppColors.primary, fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(r.$3, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.5)),
            ])),
          ]),
        )),

        const SizedBox(height: 20),
        _sectionTitle('كود المحفزات'),
        const SizedBox(height: 12),

        ..._triggers.map((t) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.warning.withOpacity(0.3)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t.$1, style: const TextStyle(color: AppColors.warning, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(t.$2, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            Text('← ${t.$3}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.5)),
          ]),
        )),

        const SizedBox(height: 20),
        _sectionTitle('كود ما بعد السقوط'),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
          child: Column(
            children: _afterFall.map((a) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: a.$3 ? AppColors.success.withOpacity(0.15) : AppColors.danger.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(a.$1, style: TextStyle(
                    color: a.$3 ? AppColors.success : AppColors.danger,
                    fontSize: 12, fontWeight: FontWeight.bold,
                  )),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(a.$2, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13))),
              ]),
            )).toList(),
          ),
        ),

        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.danger.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.danger.withOpacity(0.3)),
          ),
          child: const Text('الندم الزايد = فخ الشيطان الثاني\nتاب وقام = انتهى. بدون محاكمة.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.danger, fontSize: 13, height: 1.5)),
        ),

        const SizedBox(height: 30),
      ]),
    ),
  );

  Widget _sectionTitle(String t) => Text(t, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600));
}
