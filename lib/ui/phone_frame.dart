import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';

/// In a desktop browser the app is always shown inside an iPhone 16 Pro screen (402×874, Dynamic Island, home
/// indicator), so every layout is judged at a real phone's size.
class PhoneFrame extends StatelessWidget {
  const PhoneFrame({super.key, required this.child});
  final Widget child;

  static const screen = Size(402, 874);
  static const safe = EdgeInsets.only(top: 54, bottom: 34);
  static const _bezel = 12.0;

  /// A browser on an actual phone shows the app full screen.
  static bool get _onPhone =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    if (!kIsWeb || _onPhone) return child;
    // A short window (e.g. a side pane) would shrink the frame until text is
    // unreadable; show the app at real size in a phone-wide column instead.
    if (media.size.height < 640) {
      final width = media.size.width.clamp(0, screen.width).toDouble();
      return ColoredBox(
        color: const Color(0xFFE9E5DF),
        child: Center(
          child: SizedBox(
            width: width,
            child: MediaQuery(
              data: media.copyWith(size: Size(width, media.size.height)),
              child: child,
            ),
          ),
        ),
      );
    }
    final inner = media.copyWith(
      size: screen,
      padding: safe,
      viewPadding: safe,
      viewInsets: EdgeInsets.zero,
    );
    return ColoredBox(
      color: const Color(0xFFE9E5DF),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FittedBox(
            child: Container(
              width: screen.width + _bezel * 2,
              height: screen.height + _bezel * 2,
              padding: const EdgeInsets.all(_bezel),
              decoration: BoxDecoration(
                color: const Color(0xFF1B1B1D),
                borderRadius: BorderRadius.circular(64),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 60,
                    offset: Offset(0, 24),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(52),
                child: MediaQuery(
                  data: inner,
                  child: Stack(
                    children: [
                      Positioned.fill(child: child),
                      const Positioned(
                        top: 11,
                        left: 0,
                        right: 0,
                        child: Center(child: _Island()),
                      ),
                      const Positioned(
                        bottom: 8,
                        left: 0,
                        right: 0,
                        child: Center(child: _HomeIndicator()),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Island extends StatelessWidget {
  const _Island();
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: 126,
      height: 37,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
      ),
    ),
  );
}

class _HomeIndicator extends StatelessWidget {
  const _HomeIndicator();
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: 140,
      height: 5,
      decoration: BoxDecoration(
        color: const Color(0x99888888),
        borderRadius: BorderRadius.circular(3),
      ),
    ),
  );
}
