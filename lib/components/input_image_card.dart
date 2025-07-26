import 'dart:io';
import 'package:flutter/material.dart';

class InputImageCard extends StatelessWidget {
  final bool isDark;
  final File fileImage;
  final int width;
  final int height;
  final int sizeInKbBefore;
  final TextEditingController qualityController;

  const InputImageCard({
    Key? key,
    required this.isDark,
    required this.fileImage,
    required this.width,
    required this.height,
    required this.sizeInKbBefore,
    required this.qualityController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 340,
      child: Container(
        padding: const EdgeInsets.all(15),
        height: 400,
        alignment: Alignment.center,
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
            // Text(
            //   "Original Image",
            //   style: TextStyle(
            //     decoration: TextDecoration.underline,
            //     decorationColor: isDark ? Colors.white : Colors.black87,
            //     fontSize: 20,
            //     fontWeight: FontWeight.bold,
            //     color: isDark ? Colors.white : Colors.black87,
            //   ),
            // ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.file(fileImage, height: 185, width: 165),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Width: $width px",
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      "Height: $height px",
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      "Size: $sizeInKbBefore KB",
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: qualityController,
              keyboardType: TextInputType.number,
              cursorColor: isDark ? Colors.white : Colors.black87,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                icon: Icon(
                  Icons.high_quality,
                  color: isDark ? Colors.white30 : Colors.black87,
                ),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black87.withOpacity(0.05),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                labelText: 'Quality',
                labelStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white30 : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
