import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/design_system.dart';

/// AirPak Express brand assets.
///
/// Three variants:
/// - [AirpakWordmark]  — the "Airpak" wordmark in bold sans-serif,
///   with the courier motion underline. Used on splash, login, hero
///   sections, and the app header.
/// - [AirpakMark]      — the square monogram (red rounded square with
///   a paper-plane "A"). Used for avatars, tab icons, the home tile,
///   and the live-map pin.
class AirpakWordmark extends StatelessWidget {
  final double size;
  final Color? color;
  final bool showUnderline;
  final FontWeight weight;
  const AirpakWordmark({
    super.key,
    this.size = 36,
    this.color,
    this.showUnderline = true,
    this.weight = FontWeight.w900,
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
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('Air',
                style: GoogleFonts.inter(
                    fontSize: size,
                    fontWeight: weight,
                    color: c,
                    letterSpacing: -0.02 * size,
                    height: 1.0)),
            Transform.translate(
              offset: const Offset(0, 0),
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: size * 0.04),
                width: size * 0.12,
                height: size * 0.12,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Text('pak',
                style: GoogleFonts.inter(
                    fontSize: size,
                    fontWeight: weight,
                    color: c,
                    letterSpacing: -0.02 * size,
                    height: 1.0)),
          ],
        ),
        if (showUnderline)
          Container(
            margin: EdgeInsets.only(top: size * 0.10),
            height: size * 0.10,
            width: size * 3.0,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [c.withValues(alpha: 0.0), c, c.withValues(alpha: 0.0)],
              ),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
      ],
    );
  }
}

/// Square compact mark used for small UI surfaces.
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

/// The full lockup used on splash + login: wordmark + "EXPRESS"
/// subtitle underneath.
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
          AirpakMark(size: width * 0.35, bg: c),
          const SizedBox(height: 14),
          AirpakWordmark(size: width * 0.22, color: c),
          const SizedBox(height: 6),
          Text('E X P R E S S',
              style: TextStyle(
                  color: c,
                  fontSize: 11,
                  letterSpacing: 6,
                  fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

/// Convenience widget for the header logo: square mark + small wordmark.
class AirpakHeaderLogo extends StatelessWidget {
  final double markSize;
  final double textSize;
  const AirpakHeaderLogo({
    super.key,
    this.markSize = 36,
    this.textSize = 18,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AirpakMark(size: markSize),
        const SizedBox(width: 10),
        AirpakWordmark(size: textSize, showUnderline: false),
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
