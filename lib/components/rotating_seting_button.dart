import 'package:flutter/material.dart';
import 'package:zypto/components/top_right_popup.dart';
class RotatingSettingsButton extends StatefulWidget {
  final bool isDark;
  final dynamic authService; // replace with the actual type if known

  const RotatingSettingsButton({
    super.key,
    required this.isDark,
    required this.authService,
  });

  @override
  State<RotatingSettingsButton> createState() => _RotatingSettingsButtonState();
}

class _RotatingSettingsButtonState extends State<RotatingSettingsButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  void _onPressed() {
    // Start the animation
    _controller.forward(from: 0);

    // Show dialog
    showDialog(
      context: context,
      builder: (context) => TopRightPopup(authService: widget.authService),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      padding: const EdgeInsets.all(8),
      onPressed: _onPressed,
      icon: RotationTransition(
        turns: Tween(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut)),
        child: Icon(
          Icons.settings,
          color: widget.isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }
}
