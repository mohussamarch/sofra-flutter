import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../l10n/l10n.dart';
import '../scene/scene_lighting.dart';
import '../scene3d/kitchen_3d.dart';
import '../ui/design.dart';
import 'common.dart';

/// "شكل المطبخ": the kitchen's swappable parts, Codex's R24 options library
/// (cabinet style, fridge, range, rug, curtain, plants, cane) plus the
/// classic cabinet colour. Choices are saved in [Profile.kitchenLook] and
/// dress the home kitchen too.
class KitchenStyleScreen extends StatefulWidget {
  const KitchenStyleScreen({super.key, this.show3d = true});

  /// Off in widget tests, where no WebView exists.
  final bool show3d;

  /// Each group's choices, the first being the base kitchen. Values are the
  /// option names in Codex's model (r23-options.mjs); labels are in [t]'s
  /// language.
  static List<({String id, String name, List<(String, String)> items})> groups(
    AppLocalizations t,
  ) => [
    (
      id: 'style',
      name: t.profStyleCabinets,
      items: [
        ('classic', t.profStyleClassic),
        ('modern', t.profStyleModern),
        ('japandi', t.profStyleJapandi),
      ],
    ),
    (
      id: 'fridge',
      name: t.profStyleFridge,
      items: [('default', t.profFridgeRetro), ('double', t.profFridgeDouble)],
    ),
    (
      id: 'range',
      name: t.profStyleRange,
      items: [
        ('default', t.profRangeFreestanding),
        ('builtin', t.profRangeBuiltin),
      ],
    ),
    (
      id: 'rug',
      name: t.profStyleRug,
      items: [
        ('none', t.profRugNone),
        ('rug_persian', t.profRugPersian),
        ('rug_teal', t.profRugTeal),
        ('rug_ochre', t.profRugOchre),
      ],
    ),
    (
      id: 'curtain',
      name: t.profStyleCurtain,
      items: [
        ('gingham', t.profCurtainGingham),
        ('white_blind', t.profCurtainBlind),
        ('none', t.profCurtainNone),
      ],
    ),
  ];

  /// Cabinet colours (hex, as saved); null is the colour of the render.
  /// The colour is the classic painted timber's, so it shows on classic only.
  static List<(String, String?)> cabinetColors(AppLocalizations t) => [
    (t.profColorOriginal, null),
    (t.profColorCream, 'E9DFC8'),
    (t.profColorBlueGray, '7D93A3'),
    (t.profColorTerracotta, 'C0705A'),
  ];

  @override
  State<KitchenStyleScreen> createState() => _KitchenStyleScreenState();
}

class _KitchenStyleScreenState extends State<KitchenStyleScreen> {
  final viewer = Kitchen3DController();
  var shot = 0;

  @override
  void initState() {
    super.initState();
    // The same hour as the home kitchen, on the same schedule.
    viewer.light(LightingSchedule.provisional().weightsAtTime(DateTime.now()));
  }

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

  /// Saves one choice; null removes it (back to the base kitchen).
  void _set(String key, String? value) {
    // A fridge swap shuts the old one's doors first.
    if (key == 'fridge' && shot != 0) _shot(0);
    SofraScope.controllerOf(context).updateProfile(
      (p) => p.copyWith(
        kitchenLook: {
          for (final e in p.kitchenLook.entries)
            if (e.key != key) e.key: e.value,
          key: ?value,
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final look = SofraScope.controllerOf(context).profile.kitchenLook;
    final style = look['style'] ?? 'classic';
    final t = context.l10n;
    return ScreenBody(
      children: [
        const SizedBox(height: 4),
        if (widget.show3d) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(Sofra.r22),
            child: SizedBox(
              height: 380,
              child: Kitchen3D(controller: viewer, look: look),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final (i, label) in [
                t.profShotKitchen,
                t.profShotFridge,
                // The double fridge opens both doors either way.
                if (look['fridge'] != 'double') t.profShotFreezer,
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
        for (final g in KitchenStyleScreen.groups(t)) ...[
          SectionTitle(g.name),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (i, (value, label)) in g.items.indexed)
                SofraChip(
                  key: ValueKey('look-${g.id}-$value'),
                  label: Text(label),
                  selected: (look[g.id] ?? g.items.first.$1) == value,
                  onSelected: (_) => _set(g.id, i == 0 ? null : value),
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (g.id == 'style' && style == 'classic') ...[
            SectionTitle(t.profCabinetColor),
            const SizedBox(height: 10),
            Row(
              children: [
                for (final (i, (name, hex)) in KitchenStyleScreen.cabinetColors(
                  t,
                ).indexed)
                  Expanded(
                    child: _Swatch(
                      key: ValueKey('style-cabinet-$i'),
                      name: name,
                      color: hex == null
                          ? const Color(0xFF9DB8A0)
                          : Color(int.parse('FF$hex', radix: 16)),
                      selected: look['cabinet'] == hex,
                      onTap: () => _set('cabinet', hex),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ],
        SectionTitle(t.profExtras),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            SofraChip(
              key: const ValueKey('look-plants'),
              label: Text(t.profPlants),
              selected: look['plants'] == '1',
              onSelected: (on) => _set('plants', on ? '1' : null),
            ),
            // Cane panels belong to the japandi cabinets.
            if (style == 'japandi')
              SofraChip(
                key: const ValueKey('look-cane'),
                label: Text(t.profCane),
                selected: look['cane'] == '1',
                onSelected: (on) => _set('cane', on ? '1' : null),
              ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
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
