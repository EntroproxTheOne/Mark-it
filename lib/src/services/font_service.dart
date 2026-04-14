import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum FontCategory { script, display, clean, decorative, google }

class FontEntry {
  final String name;
  final String displayName;
  final FontCategory category;
  final bool isBundled;

  const FontEntry({
    required this.name,
    required this.displayName,
    required this.category,
    this.isBundled = false,
  });
}

class FontService {
  static const bundledFonts = <FontEntry>[
    FontEntry(name: 'Autography', displayName: 'Autography', category: FontCategory.script, isBundled: true),
    FontEntry(name: 'PhotographSignature', displayName: 'Photograph', category: FontCategory.script, isBundled: true),

    FontEntry(name: 'Orbitron', displayName: 'Orbitron', category: FontCategory.display, isBundled: true),
    FontEntry(name: 'Michroma', displayName: 'Michroma', category: FontCategory.display, isBundled: true),
    FontEntry(name: 'Righteous', displayName: 'Righteous', category: FontCategory.display, isBundled: true),
    FontEntry(name: 'Mograph', displayName: 'Mograph', category: FontCategory.display, isBundled: true),

    FontEntry(name: 'CherryCreamSoda', displayName: 'Cherry Cream', category: FontCategory.decorative, isBundled: true),
    FontEntry(name: 'PoiretOne', displayName: 'Poiret One', category: FontCategory.decorative, isBundled: true),
    FontEntry(name: 'Gruppo', displayName: 'Gruppo', category: FontCategory.decorative, isBundled: true),
  ];

  static const googleFonts = <FontEntry>[
    FontEntry(name: 'Inter', displayName: 'Inter', category: FontCategory.google),
    FontEntry(name: 'Roboto', displayName: 'Roboto', category: FontCategory.google),
    FontEntry(name: 'Open Sans', displayName: 'Open Sans', category: FontCategory.google),
    FontEntry(name: 'Lato', displayName: 'Lato', category: FontCategory.google),
    FontEntry(name: 'Montserrat', displayName: 'Montserrat', category: FontCategory.google),
    FontEntry(name: 'Poppins', displayName: 'Poppins', category: FontCategory.google),
    FontEntry(name: 'Raleway', displayName: 'Raleway', category: FontCategory.google),
    FontEntry(name: 'Playfair Display', displayName: 'Playfair', category: FontCategory.google),
    FontEntry(name: 'Source Code Pro', displayName: 'Source Code', category: FontCategory.google),
    FontEntry(name: 'Nunito', displayName: 'Nunito', category: FontCategory.google),
    FontEntry(name: 'Quicksand', displayName: 'Quicksand', category: FontCategory.google),
    FontEntry(name: 'DM Sans', displayName: 'DM Sans', category: FontCategory.google),
    FontEntry(name: 'Space Grotesk', displayName: 'Space Grotesk', category: FontCategory.google),
    FontEntry(name: 'Pacifico', displayName: 'Pacifico', category: FontCategory.google),
    FontEntry(name: 'Manrope', displayName: 'Manrope', category: FontCategory.google),
    FontEntry(name: 'Plus Jakarta Sans', displayName: 'Jakarta Sans', category: FontCategory.google),
    FontEntry(name: 'Outfit', displayName: 'Outfit', category: FontCategory.google),
    FontEntry(name: 'Sora', displayName: 'Sora', category: FontCategory.google),
    FontEntry(name: 'Lexend', displayName: 'Lexend', category: FontCategory.google),
    FontEntry(name: 'Urbanist', displayName: 'Urbanist', category: FontCategory.google),
    FontEntry(name: 'Figtree', displayName: 'Figtree', category: FontCategory.google),
  ];

  static final Set<String> _bundledNames =
      bundledFonts.map((f) => f.name).toSet();

  static List<FontEntry> get allFonts => [...bundledFonts, ...googleFonts];

  static List<FontEntry> byCategory(FontCategory cat) =>
      allFonts.where((f) => f.category == cat).toList();

  static TextStyle getFont(String name,
      {double? fontSize, FontWeight? fontWeight, Color? color}) {
    if (_bundledNames.contains(name)) {
      return TextStyle(
        fontFamily: name,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );
    }
    try {
      return GoogleFonts.getFont(
        name,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );
    } catch (_) {
      return TextStyle(fontSize: fontSize, fontWeight: fontWeight, color: color);
    }
  }
}
