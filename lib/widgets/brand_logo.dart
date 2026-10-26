import 'package:flutter/material.dart';

/// The DiscountBay logo, from the bundled assets in assets/brand
/// (1x / 2.0x / 3.0x variants, so it stays sharp at any size).
///
/// * [BrandLogo.horizontal] — bag + wordmark on one line: headers, top bars.
/// * [BrandLogo.full] — stacked logo with the tagline: welcome, login, splash-like moments.
/// * [BrandLogo.mark] — bag and tag only: tight spaces, avatars.
/// * [BrandLogo.badge] — the round navy badge.
///
/// Set [onDark] on navy / gradient backgrounds to use the white-bag artwork.
class BrandLogo extends StatelessWidget {
  const BrandLogo._(this._name, {super.key, this.height, this.width, this.onDark = false});

  const BrandLogo.horizontal({Key? key, double height = 32, bool onDark = false})
      : this._('logo_horizontal', key: key, height: height, onDark: onDark);
  const BrandLogo.full({Key? key, double? height, double? width, bool onDark = false})
      : this._('logo_full', key: key, height: height, width: width, onDark: onDark);
  const BrandLogo.mark({Key? key, double height = 40, bool onDark = false})
      : this._('logo_mark', key: key, height: height, onDark: onDark);
  const BrandLogo.badge({Key? key, double size = 96})
      : this._('logo_badge', key: key, height: size, width: size);

  final String _name;
  final double? height;
  final double? width;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final file = onDark && _name != 'logo_badge' ? '${_name}_dark' : _name;
    return Semantics(
      label: 'DiscountBay',
      image: true,
      child: Image.asset(
        'assets/brand/$file.png',
        height: height,
        width: width,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        excludeFromSemantics: true,
      ),
    );
  }
}
