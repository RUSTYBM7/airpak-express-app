import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/design_system.dart';

/// AirPak Express brand assets.
///
/// The actual brand uses a custom flowing script "Airpak" with a small
/// ® mark and "AIRPAK EXPRESS" as a letter-spaced wordmark below.
/// For Flutter web we approximate the script with Google Fonts
/// [Pacifico] (closest match) and inline a custom ® glyph + brand
/// subtitle.
class AirpakWordmark extends StatelessWidget {
  final double size;
  final Color? color;
  final bool showUnderline;
  final bool showR;
  const AirpakWordmark({
    super.key,
    this.size = 28,
    this.color,
    this.showUnderline = true,
    this.showR = true,
  });
  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.brand;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Airpak',
              style: GoogleFonts.pacifico(
                fontSize: size * 1.5,
                fontWeight: FontWeight.w400,
                color: c,
                height: 1.0,
                letterSpacing: 0.5,
              ),
            ),
            if (showR)
              Padding(
                padding: EdgeInsets.only(top: size * 0.1, left: 1),
                child: Text(
                  '®',
                  style: TextStyle(
                    color: c,
                    fontSize: size * 0.6,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
          ],
        ),
        if (showUnderline)
          Container(
            margin: EdgeInsets.only(top: size * 0.14, left: 2),
            height: size * 0.08,
            width: size * 4.2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  c.withValues(alpha: 0.0),
                  c,
                  c.withValues(alpha: 0.0),
                ],
              ),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
      ],
    );
  }
}

/// Square compact mark used for small UI surfaces — uses the AirPak
/// mark SVG with a paper-plane "A".
class AirpakMark extends StatelessWidget {
  final double size;
  final Color? bg;
  final Color? fg;
  const AirpakMark({super.key, this.size = 40, this.bg, this.fg});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [bg ?? AppColors.brand, AppColors.brandDark],
        ),
        borderRadius: BorderRadius.circular(size * 0.26),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.30),
            blurRadius: size * 0.3,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: Center(
        child: SvgPicture.asset(
          'assets/brand/airpak_mark.svg',
          width: size * 0.62,
          height: size * 0.62,
          colorFilter:
              ColorFilter.mode(fg ?? Colors.white, BlendMode.srcIn),
        ),
      ),
    );
  }
}

/// Full lockup used on splash + login: mark + script wordmark + AIRPAK EXPRESS.
class AirpakBrandLockup extends StatelessWidget {
  final double width;
  final Color? color;
  const AirpakBrandLockup({super.key, this.width = 220, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.brand;
    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AirpakMark(size: width * 0.30, bg: c),
          const SizedBox(height: 16),
          AirpakWordmark(size: width * 0.18, color: c, showR: true),
          const SizedBox(height: 4),
          Text(
            'AIRPAK EXPRESS',
            style: TextStyle(
              color: c,
              fontSize: 10,
              letterSpacing: 4,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Header logo: square mark + small wordmark side by side.
class AirpakHeaderLogo extends StatelessWidget {
  final double markSize;
  final double textSize;
  final bool showR;
  const AirpakHeaderLogo({
    super.key,
    this.markSize = 36,
    this.textSize = 22,
    this.showR = false,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AirpakMark(size: markSize),
        const SizedBox(width: 10),
        AirpakWordmark(size: textSize, showUnderline: false, showR: showR),
      ],
    );
  }
}

/// Circular avatar showing the AirPak monogram.
class AirpakAvatar extends StatelessWidget {
  final double size;
  const AirpakAvatar({super.key, this.size = 32});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.25),
            blurRadius: size * 0.2,
            spreadRadius: size * 0.05,
          ),
        ],
      ),
      child: ClipOval(
        child: AirpakMark(size: size),
      ),
    );
  }
}
