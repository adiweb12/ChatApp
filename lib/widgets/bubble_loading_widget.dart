import 'package:flutter/material.dart';

class BubbleLoading extends StatefulWidget {
  const BubbleLoading({super.key});

  @override
  State<BubbleLoading> createState() => _BubbleLoadingState();
}

class _BubbleLoadingState extends State<BubbleLoading> with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 10,
              width: 10,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(
                  Tween(begin: 0.3, end: 1.0)
                      .animate(CurvedAnimation(
                        parent: _controller,
                        curve: Interval(index * 0.2, 0.6 + (index * 0.2), curve: Curves.linear),
                      ))
                      .value,
                ),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}
