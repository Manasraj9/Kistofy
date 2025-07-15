import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AnimatedCurvedNavBar extends StatefulWidget {
  final int selectedIndex;
  const AnimatedCurvedNavBar({super.key, this.selectedIndex = 0});

  @override
  State<AnimatedCurvedNavBar> createState() => _AnimatedCurvedNavBarState();
}

class _AnimatedCurvedNavBarState extends State<AnimatedCurvedNavBar>
    with SingleTickerProviderStateMixin {
  late int _selected;
  late final AnimationController _ctl;
  late Animation<double> _notchAnim;

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedIndex;
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _notchAnim = Tween<double>(
      begin: _pos(_selected),
      end: _pos(_selected),
    ).animate(_curve(_ctl));
  }

  double _pos(int i) => (i + 0.5) / 5; // 5 icons

  CurvedAnimation _curve(AnimationController c) =>
      CurvedAnimation(parent: c, curve: Curves.easeOutCubic);

  void _tap(int i) {
    if (i == _selected) return;

    _notchAnim =
        Tween<double>(begin: _notchAnim.value, end: _pos(i)).animate(_curve(_ctl));
    _ctl.forward(from: 0);
    setState(() => _selected = i);

    switch (i) {
      case 0: Navigator.pushReplacementNamed(context, '/home');           break;
      case 1: Navigator.pushReplacementNamed(context, '/customers');  break;
      case 2: Navigator.pushReplacementNamed(context, '/create-invoice'); break;
      case 3: Navigator.pushReplacementNamed(context, '/products');       break;
      case 4: Navigator.pushReplacementNamed(context, '/seller-profile'); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF1E1E1E);
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
                children: [
                  Transform.translate(
                    offset: const Offset(-5, -5),
                    child: IconButton(
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      icon: Icon(
                        CupertinoIcons.home,
                        color: _selected == 0 ? sel : Colors.white70,
                      ),
                      onPressed: () => _tap(0),
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(-2.5, -5),
                    child: IconButton(
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      icon: Icon(
                        CupertinoIcons.person_add_solid,
                        color: _selected == 1 ? sel : Colors.white70,
                      ),
                      onPressed: () => _tap(1),
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -5),
                    child: IconButton(
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      icon: Icon(
                        CupertinoIcons.plus,
                        color: _selected == 2 ? sel : Colors.white70,
                      ),
                      onPressed: () => _tap(2),
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(3, -5),
                    child: IconButton(
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      icon: Icon(
                        CupertinoIcons.bag_fill,
                        color: _selected == 3 ? sel : Colors.white70,
                      ),
                      onPressed: () => _tap(3),
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(7, -5),
                    child: IconButton(
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      icon: Icon(
                        CupertinoIcons.profile_circled,
                        color: _selected == 4 ? sel : Colors.white70,
                      ),
                      onPressed: () => _tap(4),
                    ),
                  ),
                ],
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

class _CurvePainter extends CustomPainter {
  const _CurvePainter({required this.notchX, required this.color});

  final double notchX;
  final Color color;

  @override
  void paint(Canvas canvas, Size s) {
    const notchW = 45.0, notchH = 34.0;
    final cx = s.width * notchX;
    final half = notchW / 2;

    final paint = Paint()..color = color;
    final p = Path()..moveTo(0, 0);

    p.lineTo(cx - half - 12, 0);
    p.quadraticBezierTo(cx - half, 0, cx - half, notchH / 2);
    p.arcToPoint(
      Offset(cx + half, notchH / 2),
      radius: const Radius.circular(22),
      clockwise: false,
    );
    p.quadraticBezierTo(cx + half, 0, cx + half + 12, 0);

    p.lineTo(s.width, 0);
    p.lineTo(s.width, s.height);
    p.lineTo(0, s.height);
    p.close();

    canvas.drawPath(p, paint);
  }

  @override
  bool shouldRepaint(_CurvePainter old) => old.notchX != notchX;
}
