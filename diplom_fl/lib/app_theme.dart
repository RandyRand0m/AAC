import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData buildTheme() {
    return ThemeData(
      primaryColor: const Color.fromRGBO(222,188,255, 1),
      scaffoldBackgroundColor: const Color.fromRGBO(222,188,255, 1), 
      appBarTheme: AppBarTheme(
        backgroundColor: const Color.fromRGBO(222,188,255, 1),
        titleTextStyle: TextStyle(color: Colors.white),
      ),
      textTheme: TextTheme(
        titleLarge: GoogleFonts.oswald(
          fontSize: 20, 
          fontWeight: FontWeight.bold,
          color: Colors.black, 
        ),
        bodyLarge: GoogleFonts.oswald(
          fontSize: 16,
          color: Colors.black, 
        ),
        labelSmall: GoogleFonts.roboto(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: const Color.fromARGB(255, 0, 0, 0),
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: const Color.fromARGB(255, 255, 255, 255),
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromRGBO(159,71,246, 1), 
        ),
      ),
      cardColor: Colors.white,
      dividerColor: Colors.black26,
    );
  }
}
