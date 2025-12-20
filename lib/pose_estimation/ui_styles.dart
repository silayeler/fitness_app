import 'package:flutter/material.dart';


class UIStyles {
  // Colors (From Reference)
  static const Color primaryBlue = Color(0xFF137FEC); // #137fec
  static const Color dangerRed = Color(0xFFEF4444); // #ef4444
  static const Color successGreen = Color(0xFF4ADE80); // green-400
  static const Color darkBackground = Color(0xFF101922); // #101922
  static const Color glassWhite = Color(0x33FFFFFF); // Transparent White
  
  // Text Styles
  static const TextStyle heading = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    letterSpacing: 0.5,
  );

  static const TextStyle timer = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: Colors.white70,
    letterSpacing: 1.0,
  );

  static const TextStyle chipText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static const TextStyle scoreText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: successGreen,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle cardBody = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: Colors.white70,
  );
  
  static const TextStyle buttonText = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: Colors.white70,
  );
}
