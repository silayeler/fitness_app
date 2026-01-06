import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


class UIStyles {
  // Colors (From Reference)
  static const Color primaryBlue = Color(0xFF137FEC); // #137fec
  static const Color dangerRed = Color(0xFFEF4444); // #ef4444
  static const Color successGreen = Color(0xFF4ADE80); // green-400
  static const Color darkBackground = Color(0xFF101922); // #101922
  static const Color glassWhite = Color(0x33FFFFFF); // Transparent White
  
  // Text Styles
  // Text Styles
  static TextStyle heading = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    letterSpacing: 0.5,
  );

  static TextStyle timer = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: Colors.white70,
    letterSpacing: 1.0,
  );

  static TextStyle chipText = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static TextStyle scoreText = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: successGreen,
  );

  static TextStyle cardTitle = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  static TextStyle cardBody = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: Colors.white70,
  );
  
  static TextStyle buttonText = GoogleFonts.poppins(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: Colors.white70,
  );
}
