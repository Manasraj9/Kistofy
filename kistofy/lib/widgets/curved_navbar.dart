import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Animated curved bottom‑navigation bar (5 tabs)
/// Give [selectedIndex] from 0‑4 so the notch starts under the current tab.
class AnimatedCurvedNavBar extends StatefulWidget {
  final int selectedIndex;                            // 👈 NEW
  const AnimatedCurvedNavBar({super.key, this.selectedIndex = 0});

  @override
  State<AnimatedCurvedNavBar> createState() => _AnimatedCurvedNavBarState();
}

class _AnimatedCurvedNavBarState extends State<AnimatedCurvedNavBar>
    with SingleTickerProviderStateMixin {
  late int _selected;                                 // <-- init from widget
  late final AnimationController _ctl;
  late Animation<double> _notchAnim;

  // 🔧 icons in order (must stay length 5)
  final _icons = <IconData>[
    CupertinoIcons.home,
    CupertinoIcons.bell,
    CupertinoIcons.plus,      // centre
    CupertinoIcons.settings,
    CupertinoIcons.person,
  ];

  /*──────── init ───────*/
  @override
  void initState() {
    super.initState();
    _selected = widget.selectedIndex;                 // 👈 set from param
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // notch begins under current tab
    _notchAnim = Tween<double>(
      begin: _pos(_selected),
      end: _pos(_selected),
    ).animate(_curve(_ctl));
  }

  /*──────── helpers ─────*/
  // converts tab 0‑4 → notch centre 0.1 .. 0.9
  double _pos(int i) => (i + 0.5) / _icons.length;
  CurvedAnimation _curve(AnimationController c) =>
      CurvedAnimation(parent: c, curve: Curves.easeOutCubic);

  /*──────── on‑tap ─────*/
  void _tap(int i) {
    if (i == _selected) return;                       // stop re‑routing

    // animate the notch
    _notchAnim =
        Tween<double>(begin: _notchAnim.value, end: _pos(i)).animate(_curve(_ctl));
    _ctl.forward(from: 0);
    setState(() => _selected = i);

    /*—— route changes ———*/
    switch (i) {
      case 0: Navigator.pushReplacementNamed(context, '/home');           break;
      case 1: Navigator.pushReplacementNamed(context, '/notifications');  break;
      case 2: Navigator.pushReplacementNamed(context, '/create-invoice'); break;
      case 3: Navigator.pushReplacementNamed(context, '/products');       break;
      case 4: Navigator.pushReplacementNamed(context, '/seller-profile'); break;
    }
  }

  /*──────── build bar ─────*/
  @override
  Widget build(BuildContext context) {
    const bg  = Color(0xFF1E1E1E);
    const sel = Color(0xFFFF2D55);

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
                  const offs = Offset(0, -5); // subtle global lift
                  return Transform.translate(
                    offset: offs,
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

/*──────── painter for bar & moving notch ─────*/
class _CurvePainter extends CustomPainter {
  const _CurvePainter({required this.notchX, required this.color});

  final double notchX; // 0‑1
  final Color  color;

  @override
  void paint(Canvas canvas, Size s) {
    const notchW = 45.0, notchH = 34.0;
    final cx = s.width * notchX;
    final half = notchW / 2;

    final paint = Paint()..color = color;
    final p = Path()..moveTo(0, 0);

    // left straight
    p.lineTo(cx - half - 12, 0);
    // curve up
    p.quadraticBezierTo(cx - half, 0, cx - half, notchH / 2);
    // concave arc
    p.arcToPoint(
      Offset(cx + half, notchH / 2),
      radius: const Radius.circular(22),
      clockwise: false,
    );
    // curve down
    p.quadraticBezierTo(cx + half, 0, cx + half + 12, 0);
    p
      ..lineTo(s.width, 0)
      ..lineTo(s.width, s.height)
      ..lineTo(0, s.height)
      ..close();

    canvas.drawPath(p, paint);
  }

  @override
  bool shouldRepaint(_CurvePainter old) => old.notchX != notchX;
}
