import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class FeatureCard extends StatelessWidget {
  final String animationPath;
  final String label;
  final VoidCallback onTap;
  final bool isDark;

  const FeatureCard({
    super.key,
    required this.animationPath,
    required this.label,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        borderRadius: BorderRadius.circular(15),
        elevation: 4,
        // color: Colors.transparent,
        child: InkWell(
          splashColor: isDark
              ? Colors.white24
              : Colors.black26, // splash effect color
          highlightColor: isDark
              ? Colors.white10
              : Colors.black12, // pressed-down color
          borderRadius: BorderRadius.circular(15),
          onTap: onTap,
          child: Container(
            width: 155,
            // padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Lottie.asset(animationPath, height: 150, width: 150),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 5,
                    bottom: 10,
                    top: 5,
                    right: 5,
                  ),
                  child: Text(
                    textAlign: TextAlign.center,

                    label,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
