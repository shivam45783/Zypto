import 'dart:io';
import 'package:flutter/material.dart';

class CompressedImageCard extends StatelessWidget {
  final bool isDark;
  final File compressedImage;
  final int compWidth;
  final int compHeight;
  final int sizeInKbAfter;
  final TextEditingController qualityController;
  const CompressedImageCard({
    Key? key,
    required this.isDark,
    required this.compressedImage,
    required this.compWidth,
    required this.compHeight,
    required this.sizeInKbAfter,
    required this.qualityController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 340,
      height: 400,
      padding: const EdgeInsets.all(15),
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.white.withOpacity(0.3),
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
        children: [
          
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Image.file(compressedImage, height: 185, width: 165),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Width: $compWidth px",
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    "Height: $compHeight px",
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    "Size: $sizeInKbAfter KB",
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  // Text(
                  //   "Size: ${qualityController.text} %",
                  //   style: TextStyle(
                  //     fontSize: 14,
                  //     color: isDark ? Colors.white : Colors.black87,
                  //   ),
                  // ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
