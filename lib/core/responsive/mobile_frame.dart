import 'package:flutter/material.dart';

/// Makes a browser preview on a wide (desktop-sized) viewport look
/// like a real phone: the app is letterboxed into a fixed-width
/// column with a subtle shadow, instead of stretching edge-to-edge
/// across a wide browser window.
///
/// On any viewport already at or below phone width — a real phone
/// browser, a narrowed desktop browser window, or the native Android
/// app itself — this is a complete no-op: [child] is returned as-is,
/// unwrapped. It never changes layout, spacing, or behavior on an
/// actual phone. This is purely a browser-preview affordance and
/// carries no Phase 0/1 functional or security implications.
class MobileFrame extends StatelessWidget {
  const MobileFrame({super.key, required this.child});

  final Widget child;

  /// Roughly the width of a large phone in logical pixels. Below this,
  /// the viewport already looks like a phone, so there's nothing to
  /// frame.
  static const double _maxContentWidth = 480;

  static const Color _letterboxColor = Color(0xFF10241A); // matches web/index.html

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= _maxContentWidth) {
          return child;
        }
        return ColoredBox(
          color: _letterboxColor,
          child: Center(
            child: SizedBox(
              width: _maxContentWidth,
              child: Material(
                elevation: 12,
                clipBehavior: Clip.antiAlias,
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
