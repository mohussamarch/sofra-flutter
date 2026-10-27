import 'package:flutter/material.dart';

import '../scene3d/kitchen_3d.dart';
import '../ui/design.dart';
import 'common.dart';

/// "شكل المطبخ": the kitchen's swappable parts. The cabinet colour already
/// changes live on the real-time 3D kitchen (engine spike); curtain, rug and
/// table become 3D options once Codex exports them as separate parts.
class KitchenStyleScreen extends StatefulWidget {
  const KitchenStyleScreen({super.key, this.show3d = true});

  /// Off in widget tests, where no WebView exists.
  final bool show3d;

  static const pending = [
    (id: 'curtain', name: 'الستارة', icon: Icons.curtains_outlined),
    (id: 'rug', name: 'السجادة', icon: Icons.texture_rounded),
    (id: 'table', name: 'الطاولة', icon: Icons.table_restaurant_outlined),
  ];

  /// Cabinet colours; null is the colour of the Blender render.
  static const cabinetColors = <(String, Color?)>[
    ('الأصلي', null),
    ('كريمي', Color(0xFFE9DFC8)),
    ('أزرق رمادي', Color(0xFF7D93A3)),
    ('تيراكوتا', Color(0xFFC0705A)),
  ];

  @override
  State<KitchenStyleScreen> createState() => _KitchenStyleScreenState();
}

class _KitchenStyleScreenState extends State<KitchenStyleScreen> {
  final viewer = Kitchen3DController();
  var shot = 0;
  var cabinet = 0;

  void _shot(int i) {
    setState(() => shot = i);
    switch (i) {
      case 1:
        viewer.open();
      case 2:
        viewer.open(freezer: true);
      default:
        viewer.overview();
    }
  }

  void _cabinet(int i) {
    setState(() => cabinet = i);
    viewer.cabinets(KitchenStyleScreen.cabinetColors[i].$2);
  }

  @override
  Widget build(BuildContext context) => ScreenBody(
    children: [
      const SizedBox(height: 4),
      if (widget.show3d) ...[
        ClipRRect(
          borderRadius: BorderRadius.circular(Sofra.r22),
          child: SizedBox(height: 380, child: Kitchen3D(controller: viewer)),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            for (final (i, label) in const [
              'المطبخ كله',
              'افتح الثلاجة',
              'افتح الفريزر',
            ].indexed)
              SofraChip(
                key: ValueKey('style-shot-$i'),
                label: Text(label),
                selected: shot == i,
                onSelected: (_) => _shot(i),
              ),
          ],
        ),
        const SizedBox(height: 20),
      ],
      const SectionTitle('لون الدواليب'),
      const SizedBox(height: 10),
      Row(
        children: [
          for (final (i, (name, color))
              in KitchenStyleScreen.cabinetColors.indexed)
            Expanded(
              child: _Swatch(
                key: ValueKey('style-cabinet-$i'),
                name: name,
                color: color ?? const Color(0xFF9DB8A0),
                selected: cabinet == i,
                onTap: () => _cabinet(i),
              ),
            ),
        ],
      ),
      const SizedBox(height: 24),
      for (final g in KitchenStyleScreen.pending) ...[
        Surface(
          key: ValueKey('style-group-${g.id}'),
          child: Row(
            children: [
              Icon(g.icon, color: Sofra.greenDark),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  g.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Text(
                'قريبًا',
                style: TextStyle(color: Sofra.muted, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    ],
  );
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    super.key,
    required this.name,
    required this.color,
    required this.selected,
    required this.onTap,
  });
  final String name;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: name,
    child: PressScale(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            AnimatedContainer(
              duration: Sofra.motion(context, true),
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? Sofra.ink : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
