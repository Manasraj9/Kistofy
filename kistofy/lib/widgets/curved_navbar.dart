import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Animated curved bottom‑navigation bar (5 items)
/// Put inside Scaffold.bottomNavigationBar:  const AnimatedCurvedNavBar()
class AnimatedCurvedNavBar extends StatefulWidget {
  const AnimatedCurvedNavBar({super.key});

  @override
  State<AnimatedCurvedNavBar> createState() => _AnimatedCurvedNavBarState();
}

class _AnimatedCurvedNavBarState extends State<AnimatedCurvedNavBar>
    with SingleTickerProviderStateMixin {
  int _selected = 0;

  // ⇢ Change icons / order here (must stay length 5)
  final _icons = <IconData>[
    CupertinoIcons.home,
    CupertinoIcons.bell,
    CupertinoIcons.plus,         // center
    CupertinoIcons.settings,
    CupertinoIcons.person,
  ];

  late final AnimationController _ctl;
  late Animation<double> _notchAnim;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _notchAnim = Tween<double>(begin: _pos(0), end: _pos(0)).animate(_curve(_ctl));
  }

  /* ───────── helpers ───────── */
  // Map 0‑4 → 0.1, 0.3, 0.5, 0.7, 0.9  (center of notch)
  double _pos(int i) => (i + 0.5) / _icons.length;

  CurvedAnimation _curve(AnimationController c) =>
      CurvedAnimation(parent: c, curve: Curves.easeOutCubic);
  /* ─────────────────────────── */

  void _tap(int i) {
    // animate notch
    _notchAnim =
        Tween<double>(begin: _notchAnim.value, end: _pos(i)).animate(_curve(_ctl));
    _ctl.forward(from: 0);
    setState(() => _selected = i);

    // 👉  route navigation (edit to fit your app)
    switch (i) {
      case 0: Navigator.pushNamed(context, '/home');       break;
      case 1: Navigator.pushNamed(context, '/notifications'); break;
      case 2: Navigator.pushNamed(context, '/create-invoice'); break;
      case 3: Navigator.pushNamed(context, '/products');   break;
      case 4: Navigator.pushNamed(context, '/seller-profile');  break;
    }
  }

  @override
  Widget build(BuildContext context) {
    const bg  = Color(0xFF1E1E1E);  // nav bar background
    const sel = Color(0xFFFF2D55);  // selected icon color

    return BottomAppBar(
      color: Colors.transparent,
      elevation: 0,
      child: AnimatedBuilder(
        animation: _notchAnim,
        builder: (_, __) => Stack(
          alignment: Alignment.bottomCenter,
          children: [
            CustomPaint(
              size: const Size(double.infinity, 100),
              painter: _CurvePainter(notchX: _notchAnim.value, color: bg),
            ),
            SizedBox(
              height: 70,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(_icons.length, (i) {
                  // Customize per-icon shifts here:
                  final offsets = [
                    const Offset(-5, -5),   // Home: left 8, down 2
                    const Offset(-5, -5),    // Bell: default
                    const Offset(-5, -5),   // Plus: slightly up
                    const Offset(-5, -5),    // Settings: right 4, down 2
                    const Offset(-5, -5),    // Profile: right 6
                  ];

                  return Transform.translate(
                    offset: offsets[i],
                    child: IconButton(
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      icon: Icon(
                        _icons[i],
                        color: i == _selected ? sel : Colors.white70,
                      ),
                      onPressed: () => _tap(i),
                    ),
                  );
                }),

              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }
}

/*───────────── Painter that draws the moving notch ─────────────*/
class _CurvePainter extends CustomPainter {
  const _CurvePainter({required this.notchX, required this.color});

  final double notchX;   // 0–1 position of notch center
  final Color  color;

  @override
  void paint(Canvas canvas, Size s) {
    const notchW = 45.0;
    const notchH = 34.0;
    final cx   = s.width * notchX;     // notch center X
    final half = notchW / 2;

    final paint = Paint()..color = color;
    final path  = Path()..moveTo(0, 0);

    // left straight
    path.lineTo(cx - half - 12, 0);

    // left curve up
    path.quadraticBezierTo(cx - half, 0, cx - half, notchH / 2);

    // concave arc
    path.arcToPoint(
      Offset(cx + half, notchH / 2),
      radius: const Radius.circular(22),
      clockwise: false,
    );

    // right curve down
    path.quadraticBezierTo(cx + half, 0, cx + half + 12, 0);

    // right edge & close
    path
      ..lineTo(s.width, 0)
      ..lineTo(s.width, s.height)
      ..lineTo(0, s.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CurvePainter old) => old.notchX != notchX;
}
