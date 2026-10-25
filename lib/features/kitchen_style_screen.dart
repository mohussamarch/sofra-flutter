import 'package:flutter/material.dart';

import '../ui/design.dart';
import 'common.dart';

/// "شكل المطبخ": the kitchen's swappable parts. Each group holds one choice;
/// only the rendered base exists today, so the page shows it as current and
/// says the rest is still being rendered instead of offering fake options.
class KitchenStyleScreen extends StatelessWidget {
  const KitchenStyleScreen({super.key});

  static const groups = [
    (id: 'curtain', name: 'الستارة', icon: Icons.curtains_outlined),
    (id: 'rug', name: 'السجادة', icon: Icons.texture_rounded),
    (id: 'table', name: 'الترابيزة', icon: Icons.table_restaurant_outlined),
    (id: 'cabinets', name: 'لون الدواليب', icon: Icons.palette_outlined),
  ];

  @override
  Widget build(BuildContext context) => ScreenBody(
    children: [
      const SizedBox(height: 4),
      const Text(
        'هنا هتختار شكل كل حتة في مطبخك. دلوقتي فيه الشكل الأساسي بس.',
        style: TextStyle(color: Sofra.muted),
      ),
      const SizedBox(height: 16),
      for (final g in groups) ...[
        Surface(
          key: ValueKey('style-group-${g.id}'),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Sofra.green.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(Sofra.r16),
                ),
                child: Icon(g.icon, color: Sofra.greenDark),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      g.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'اختيارات تانية بتترندر دلوقتي',
                      style: TextStyle(color: Sofra.muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SoftTag('الحالي'),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    ],
  );
}
