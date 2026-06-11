import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/carrier.dart';

/// Renders the real bundled carrier logo if we have one, otherwise
/// falls back to a stylised brand-letter mark on the carrier's
/// official brand colour.
///
/// The widget is sized via [size] (a square box) and the inner logo
/// scales to fit while preserving its aspect ratio.
class CarrierLogo extends StatelessWidget {
  final Carrier carrier;
  final double size;
  final bool selected;
  final double? fontSize;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;

  const CarrierLogo({
    super.key,
    required this.carrier,
    this.size = 40,
    this.selected = false,
    this.fontSize,
    this.backgroundColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(size * 0.25);
    final hasLogo = carrier.logoAsset != null;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: hasLogo
            ? (backgroundColor ?? Colors.white)
            : (backgroundColor ?? carrier.brandColor),
        borderRadius: radius,
        boxShadow: selected
            ? [
                BoxShadow(
                  color: carrier.brandColor.withValues(alpha: 0.45),
                  blurRadius: size * 0.4,
                  offset: Offset(0, size * 0.12),
                ),
              ]
            : null,
      ),
      child: hasLogo
          ? Padding(
              padding: EdgeInsets.all(size * 0.15),
              child: SvgPicture.asset(
                carrier.logoAsset!,
                fit: BoxFit.contain,
                colorFilter: const ColorFilter.mode(
                  Color(0xFF111111),
                  BlendMode.srcIn,
                ),
              ),
            )
          : _LetterMark(
              text: carrier.name,
              color: Colors.white,
              size: size,
              fontSize: fontSize,
            ),
    );
  }
}

/// A simple wordmark that uses the first 2 letters of the brand
/// rendered in the carrier's primary brand colour, styled bold.
class _LetterMark extends StatelessWidget {
  final String text;
  final Color color;
  final Color? backgroundColor;
  final double size;
  final double? fontSize;
  const _LetterMark({
    required this.text,
    required this.color,
    required this.size,
    this.backgroundColor,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final upper = text.toUpperCase();
    final compact = upper.length <= 4
        ? upper
        : (upper.contains(' ')
            ? upper
                .split(' ')
                .map((w) => w[0])
                .take(2)
                .join()
            : upper.substring(0, 4));
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: size * 0.1),
          child: Text(
            compact,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: fontSize ?? size * 0.36,
              letterSpacing: -0.5,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}
