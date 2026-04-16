import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static final lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF1E3A8A),
      secondary: Color(0xFF10B981),
    ),
    textTheme: GoogleFonts.poppinsTextTheme(),
  );
}