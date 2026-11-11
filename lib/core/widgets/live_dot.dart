import 'package:flutter/material.dart';

/// A small status dot with an optional soft pulse.
///
/// The pulse is disabled automatically when the platform asks for reduced
/// motion. The dot keeps a fixed layout box so rows never jump while it
/// animates.
class LiveDot extends StatefulWidget {
  final double size;
  final Color color;
  final bool pulse;
  final String? semanticsLabel;

  const LiveDot({
    super.key,
    this.size = 7,
    this.color = const Color(0xFF16A36A),
    this.pulse = true,
    this.semanticsLabel,
  });

  @override
  State<LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<LiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _haloOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _haloOpacity = Tween<double>(
      begin: 0.28,
      end: 0.02,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    // MediaQuery is not available in initState; the animation starts in
    // didChangeDependencies, which runs before the first frame.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  void _syncAnimation() {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (widget.pulse && !reduceMotion) {
      if (!_controller.isAnimating) {
        _controller.repeat(reverse: true);
      }
    } else if (_controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dot = Semantics(
      label: widget.semanticsLabel,
      child: SizedBox(
        width: widget.size * 2.4,
        height: widget.size * 2.4,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (widget.pulse)
              FadeTransition(
                opacity: _haloOpacity,
                child: Container(
                  width: widget.size * 2.2,
                  height: widget.size * 2.2,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.35),
                    blurRadius: widget.size * 0.8,
                    spreadRadius: widget.size * 0.12,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return dot;
  }
}

/// Compact label + live dot used for queue and availability states.
class LiveStatusPill extends StatelessWidget {
  final String label;
  final Color foreground;
  final Color background;
  final bool pulse;
  final EdgeInsetsGeometry padding;

  const LiveStatusPill({
    super.key,
    required this.label,
    this.foreground = const Color(0xFF006D44),
    this.background = const Color(0xFFEAF7EF),
    this.pulse = true,
    this.padding = const EdgeInsets.fromLTRB(8, 3, 10, 3),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LiveDot(
            size: 6,
            color: foreground,
            pulse: pulse,
            semanticsLabel: '$label status',
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
                color: foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
