import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BrandKit {
  final String id;
  final String name;
  final Color primaryColor;
  final Color secondaryColor;
  final String tagline;
  final BrandCategory category;
  final String assetPath;
  final bool svgSupportsColorFilter;

  const BrandKit({
    required this.id,
    required this.name,
    required this.primaryColor,
    this.secondaryColor = Colors.white,
    required this.tagline,
    required this.category,
    required this.assetPath,
    this.svgSupportsColorFilter = true,
  });

  Widget logo(double size, {Color? color}) {
    final effectiveColor = color ?? primaryColor;
    return SizedBox(
      height: size,
      child: SvgPicture.asset(
        assetPath,
        height: size,
        colorFilter: svgSupportsColorFilter
            ? ColorFilter.mode(effectiveColor, BlendMode.srcIn)
            : null,
      ),
    );
  }
}

enum BrandCategory { phone, camera, lens }

class BrandKits {
  static const _svgBase = 'assets/logos/svg';

  static final List<BrandKit> all = [...phones, ...cameras, ...lenses];

  static const List<LogoColorOption> colorOptions = [
    LogoColorOption('Default', null),
    LogoColorOption('White', Colors.white),
    LogoColorOption('Black', Color(0xFF1A1A1A)),
    LogoColorOption('Gray', Color(0xFF888888)),
    LogoColorOption('Light Gray', Color(0xFFCCCCCC)),
    LogoColorOption('Gold', Color(0xFFD4A843)),
    LogoColorOption('Silver', Color(0xFFB0B0B0)),
  ];

  static final List<BrandKit> phones = [
    BrandKit(
      id: 'xiaomi', name: 'Xiaomi',
      primaryColor: const Color(0xFFFF6900),
      tagline: 'Shot on Xiaomi',
      category: BrandCategory.phone,
      assetPath: '$_svgBase/xiaomi.svg',
      svgSupportsColorFilter: false,
    ),
    BrandKit(
      id: 'samsung', name: 'Samsung',
      primaryColor: const Color(0xFF1428A0),
      tagline: 'Shot on Samsung',
      category: BrandCategory.phone,
      assetPath: '$_svgBase/samsung.svg',
    ),
    BrandKit(
      id: 'apple', name: 'Apple',
      primaryColor: const Color(0xFF555555),
      tagline: 'Shot on iPhone',
      category: BrandCategory.phone,
      assetPath: '$_svgBase/apple.svg',
    ),
    BrandKit(
      id: 'google', name: 'Google Pixel',
      primaryColor: const Color(0xFF4285F4),
      tagline: 'Shot on Pixel',
      category: BrandCategory.phone,
      assetPath: '$_svgBase/google.svg',
      svgSupportsColorFilter: false,
    ),
    BrandKit(
      id: 'oppo', name: 'OPPO',
      primaryColor: const Color(0xFF1A8A37),
      tagline: 'Shot on OPPO',
      category: BrandCategory.phone,
      assetPath: '$_svgBase/oppo.svg',
    ),
    BrandKit(
      id: 'oneplus', name: 'OnePlus',
      primaryColor: const Color(0xFFEB0028),
      tagline: 'Shot on OnePlus',
      category: BrandCategory.phone,
      assetPath: '$_svgBase/oneplus.svg',
    ),
    BrandKit(
      id: 'vivo', name: 'Vivo',
      primaryColor: const Color(0xFF415FFF),
      tagline: 'Shot on Vivo',
      category: BrandCategory.phone,
      assetPath: '$_svgBase/vivo.svg',
    ),
    BrandKit(
      id: 'huawei', name: 'Huawei',
      primaryColor: const Color(0xFFCF0A2C),
      tagline: 'Taken by Huawei',
      category: BrandCategory.phone,
      assetPath: '$_svgBase/huawei.svg',
      svgSupportsColorFilter: false,
    ),
    BrandKit(
      id: 'nothing', name: 'Nothing',
      primaryColor: const Color(0xFF000000),
      tagline: 'Shot on Nothing',
      category: BrandCategory.phone,
      assetPath: '$_svgBase/nothing.svg',
    ),
    BrandKit(
      id: 'realme', name: 'Realme',
      primaryColor: const Color(0xFFFFC800),
      tagline: 'Dare to Leap',
      category: BrandCategory.phone,
      assetPath: '$_svgBase/realme.svg',
      svgSupportsColorFilter: false,
    ),
    BrandKit(
      id: 'motorola', name: 'Motorola',
      primaryColor: const Color(0xFF5C68BC),
      tagline: 'Shot on Motorola',
      category: BrandCategory.phone,
      assetPath: '$_svgBase/motorola.svg',
    ),
    BrandKit(
      id: 'honor', name: 'Honor',
      primaryColor: const Color(0xFF0AB2FA),
      tagline: 'Shot on Honor',
      category: BrandCategory.phone,
      assetPath: '$_svgBase/honor.svg',
    ),
    BrandKit(
      id: 'iqoo', name: 'iQOO',
      primaryColor: const Color(0xFFFF6B00),
      tagline: 'Shot on iQOO',
      category: BrandCategory.phone,
      assetPath: '$_svgBase/iqoo.svg',
    ),
    BrandKit(
      id: 'nubia', name: 'nubia',
      primaryColor: const Color(0xFFE60012),
      tagline: 'Shot on nubia',
      category: BrandCategory.phone,
      assetPath: '$_svgBase/nubia.svg',
    ),
  ];

  static final List<BrandKit> cameras = [
    BrandKit(
      id: 'canon', name: 'Canon',
      primaryColor: const Color(0xFFBC0024),
      tagline: 'Shot on Canon',
      category: BrandCategory.camera,
      assetPath: '$_svgBase/canon.svg',
    ),
    BrandKit(
      id: 'nikon', name: 'Nikon',
      primaryColor: const Color(0xFFFDC800),
      secondaryColor: Colors.black,
      tagline: 'Shot on Nikon',
      category: BrandCategory.camera,
      assetPath: '$_svgBase/nikon.svg',
      svgSupportsColorFilter: false,
    ),
    BrandKit(
      id: 'sony_camera', name: 'Sony',
      primaryColor: const Color(0xFF000000),
      tagline: 'Shot on Sony',
      category: BrandCategory.camera,
      assetPath: '$_svgBase/sony_camera.svg',
    ),
    BrandKit(
      id: 'fujifilm', name: 'Fujifilm',
      primaryColor: const Color(0xFF86BC25),
      tagline: 'Shot on Fujifilm',
      category: BrandCategory.camera,
      assetPath: '$_svgBase/fujifilm.svg',
      svgSupportsColorFilter: false,
    ),
    BrandKit(
      id: 'panasonic', name: 'Panasonic Lumix',
      primaryColor: const Color(0xFF003087),
      tagline: 'Shot on Lumix',
      category: BrandCategory.camera,
      assetPath: '$_svgBase/panasonic.svg',
    ),
    BrandKit(
      id: 'olympus', name: 'OM System',
      primaryColor: const Color(0xFF003DA5),
      tagline: 'Shot on OM System',
      category: BrandCategory.camera,
      assetPath: '$_svgBase/olympus.svg',
      svgSupportsColorFilter: false,
    ),
    BrandKit(
      id: 'pentax', name: 'Pentax',
      primaryColor: const Color(0xFFCC0000),
      tagline: 'Shot on Pentax',
      category: BrandCategory.camera,
      assetPath: '$_svgBase/pentax.svg',
    ),
    BrandKit(
      id: 'ricoh', name: 'Ricoh',
      primaryColor: const Color(0xFFCC0000),
      tagline: 'Shot on Ricoh GR',
      category: BrandCategory.camera,
      assetPath: '$_svgBase/ricoh.svg',
    ),
    BrandKit(
      id: 'dji', name: 'DJI',
      primaryColor: const Color(0xFF333333),
      tagline: 'Shot on DJI',
      category: BrandCategory.camera,
      assetPath: '$_svgBase/dji.svg',
    ),
  ];

  static final List<BrandKit> lenses = [
    BrandKit(
      id: 'leica', name: 'Leica',
      primaryColor: const Color(0xFFE4002B),
      tagline: 'Shot on Leica',
      category: BrandCategory.lens,
      assetPath: '$_svgBase/leica.svg',
      svgSupportsColorFilter: false,
    ),
    BrandKit(
      id: 'hasselblad', name: 'Hasselblad',
      primaryColor: const Color(0xFF1A1A1A),
      tagline: 'Shot on Hasselblad',
      category: BrandCategory.lens,
      assetPath: '$_svgBase/hasselblad.svg',
    ),
    BrandKit(
      id: 'zeiss', name: 'ZEISS',
      primaryColor: const Color(0xFF003399),
      tagline: 'Shot with ZEISS',
      category: BrandCategory.lens,
      assetPath: '$_svgBase/zeiss.svg',
      svgSupportsColorFilter: false,
    ),
    BrandKit(
      id: 'sigma', name: 'Sigma',
      primaryColor: const Color(0xFF1A1A1A),
      tagline: 'Shot with Sigma',
      category: BrandCategory.lens,
      assetPath: '$_svgBase/sigma.svg',
    ),
    BrandKit(
      id: 'schneider', name: 'Schneider',
      primaryColor: const Color(0xFF003366),
      tagline: 'Schneider Kreuznach',
      category: BrandCategory.lens,
      assetPath: '$_svgBase/schneider.svg',
    ),
  ];

  static BrandKit? findById(String id) {
    try {
      return all.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }
}

class LogoColorOption {
  final String label;
  final Color? color;
  const LogoColorOption(this.label, this.color);
}
