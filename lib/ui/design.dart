import 'package:flutter/material.dart';

abstract final class Sofra {
  static const ink = Color(0xFF243F36);
  static const muted = Color(0xFF657469);
  static const green = Color(0xFF278459);
  static const greenDark = Color(0xFF196846);
  static const mint = Color(0xFFE7F3E6);
  static const cream = Color(0xFFFFFCF5);
  static const line = Color(0xFFE7EADF);
  static const orange = Color(0xFFEF8358);
  static const peach = Color(0xFFFFEBDD);
  static const yellow = Color(0xFFFFDA78);
  static const quick = Duration(milliseconds: 180);
  static const calm = Duration(milliseconds: 380);
  static Duration motion(BuildContext context, [bool quick = false]) =>
      MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : quick
      ? Sofra.quick
      : calm;
}

class DepthButton extends StatefulWidget {
  const DepthButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.secondary = false,
    this.icon,
    this.compact = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool secondary;
  final bool compact;
  final IconData? icon;
  @override
  State<DepthButton> createState() => _DepthButtonState();
}

class _DepthButtonState extends State<DepthButton> {
  bool pressed = false;
  void setPressed(bool value) {
    if (pressed != value) setState(() => pressed = value);
  }

  @override
  void didUpdateWidget(covariant DepthButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.onPressed == null) pressed = false;
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final face = !enabled
        ? Sofra.line
        : widget.secondary
        ? Colors.white
        : Sofra.green;
    final edge = !enabled
        ? const Color(0xFFD5DCCF)
        : widget.secondary
        ? const Color(0xFFD8E1D4)
        : Sofra.greenDark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : Duration(milliseconds: pressed ? 80 : 180),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, pressed ? 4 : 0, 0),
        decoration: BoxDecoration(
          color: face,
          borderRadius: BorderRadius.circular(18),
          border: widget.secondary
              ? Border.all(color: Sofra.line, width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(color: edge, offset: Offset(0, pressed ? 1 : 5)),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            onHighlightChanged: setPressed,
            borderRadius: BorderRadius.circular(18),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: widget.compact ? 48 : 56),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: widget.compact ? 14 : 20,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(
                        widget.icon,
                        size: 21,
                        color: widget.secondary ? Sofra.ink : Colors.white,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        widget.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: widget.compact ? 14 : 16,
                          color: !enabled
                              ? Sofra.muted
                              : widget.secondary
                              ? Sofra.ink
                              : Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Surface extends StatelessWidget {
  const Surface({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.padding = const EdgeInsets.all(20),
    this.border = false,
  });
  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;
  final bool border;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(24),
      border: border ? Border.all(color: Sofra.line, width: 1.5) : null,
      boxShadow: [
        BoxShadow(
          color: Sofra.ink.withValues(alpha: .035),
          blurRadius: 22,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Material(type: MaterialType.transparency, child: child),
  );
}

class ChoiceTile extends StatelessWidget {
  const ChoiceTile({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.icon = Icons.check_circle_outline_rounded,
  });
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Semantics(
      selected: selected,
      child: Material(
        color: selected ? Sofra.mint : Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: Sofra.motion(context, true),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? Sofra.green : Sofra.line,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: selected ? Sofra.greenDark : Sofra.muted,
                  size: 26,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: const TextStyle(
                            color: Sofra.muted,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: selected ? Sofra.green : const Color(0xFFD5DBCF),
                  size: 23,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class SoftTag extends StatelessWidget {
  const SoftTag(
    this.text, {
    super.key,
    this.color = Sofra.mint,
    this.ink = Sofra.greenDark,
    this.icon,
  });
  final String text;
  final Color color;
  final Color ink;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: ink),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              color: ink,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
          ),
        ),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action!)),
      ],
    ),
  );
}

class Counter extends StatelessWidget {
  const Counter({
    super.key,
    required this.value,
    required this.onChanged,
    this.max = 12,
  });
  final int value;
  final int max;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton.filledTonal(
        onPressed: value < max ? () => onChanged(value + 1) : null,
        icon: const Icon(Icons.add_rounded),
        tooltip: 'زيادة العدد',
      ),
      SizedBox(
        width: 50,
        child: Text(
          '$value',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
      ),
      IconButton.filledTonal(
        onPressed: value > 1 ? () => onChanged(value - 1) : null,
        icon: const Icon(Icons.remove_rounded),
        tooltip: 'تقليل العدد',
      ),
    ],
  );
}
