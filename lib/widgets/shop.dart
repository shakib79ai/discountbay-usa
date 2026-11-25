import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../state/saved.dart';
import '../theme/identity.dart';
import '../theme/tokens.dart';
import 'components.dart' show expiryText;

/// Building blocks of the store-front design: photo cards, store cards, category tiles,
/// headers and chips. Every screen is made from these.

// ------------------------------------------------------------------ photos

/// A photo from the network (offer / banner image) with a bundled photo as the fallback.
class Photo extends StatelessWidget {
  const Photo({super.key, this.url, required this.fallback, this.fit = BoxFit.cover});

  final String? url;

  /// Asset path, e.g. `assets/photos/cookware.jpg`.
  final String fallback;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final asset = Image.asset(fallback, fit: fit, width: double.infinity, height: double.infinity);
    final u = url;
    if (u == null || u.isEmpty || u.toLowerCase().split('?').first.endsWith('.svg')) return asset;
    return CachedNetworkImage(
      imageUrl: u,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      placeholder: (_, __) => asset,
      errorWidget: (_, __, ___) => asset,
    );
  }
}

/// A photo that fades in from one side over a brand-colour gradient (store covers).
class FadedCover extends StatelessWidget {
  const FadedCover({super.key, required this.gradient, required this.photo, this.url, this.widthFactor = 0.75, this.child});

  final Gradient gradient;
  final String photo;
  final String? url;
  final double widthFactor;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: gradient),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: widthFactor,
              heightFactor: 1,
              child: ShaderMask(
                shaderCallback: (r) => const LinearGradient(
                  colors: [Colors.transparent, Colors.black],
                  stops: [0, 0.45],
                ).createShader(r),
                blendMode: BlendMode.dstIn,
                child: Photo(url: url, fallback: photo),
              ),
            ),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ store tile

/// The store's logo tile: the API logo when there is one, else coloured initials.
class StoreBadge extends StatelessWidget {
  const StoreBadge({super.key, required this.look, this.logoUrl, this.size = 54, this.ring = 3});

  final StoreLook look;
  final String? logoUrl;
  final double size;
  final double ring;

  @override
  Widget build(BuildContext context) {
    final radius = look.roundTile ? size / 2 : size * 0.28;
    final initialsText = Center(
      child: Text(look.initials,
          style: DB.heading(size * (look.initials.length > 1 ? 0.34 : 0.42), color: logoUrl == null ? look.tileFg : look.brand)),
    );
    Widget inner = initialsText;
    final u = logoUrl;
    if (u != null && u.isNotEmpty) {
      inner = Padding(
        padding: EdgeInsets.all(size * 0.14),
        child: u.toLowerCase().split('?').first.endsWith('.svg')
            ? SvgPicture.network(u, fit: BoxFit.contain, placeholderBuilder: (_) => initialsText)
            : CachedNetworkImage(imageUrl: u, fit: BoxFit.contain, errorWidget: (_, __, ___) => initialsText),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: u == null || u.isEmpty ? look.tileBg : Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white, width: ring),
        boxShadow: const [BoxShadow(color: Color(0x2E12203A), blurRadius: 12, offset: Offset(0, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: inner,
    );
  }
}

/// Small square store chip used inside deal cards.
class StoreChip extends StatelessWidget {
  const StoreChip({super.key, required this.name, required this.look, this.size = 18});
  final String name;
  final StoreLook look;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: look.brand, borderRadius: BorderRadius.circular(5)),
        child: Text(look.initials, style: DB.heading(size * 0.5, color: Colors.white)),
      ),
      const SizedBox(width: 6),
      Flexible(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: DB.body(11.5, weight: FontWeight.w700))),
    ]);
  }
}

// ------------------------------------------------------------------ small pieces

class SaleBadge extends StatelessWidget {
  const SaleBadge(this.text, {super.key, this.color = DB.sale, this.size = 10});
  final String text;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(horizontal: size * 0.6, vertical: size * 0.3),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
        child: Text(text, style: DB.heading(size, color: Colors.white)),
      );
}

class SaveHeart extends StatelessWidget {
  const SaveHeart({super.key, required this.offer, this.size = 40});
  final Offer offer;
  final double size;

  @override
  Widget build(BuildContext context) {
    final saved = context.watch<SavedState>();
    final on = saved.isSaved(offer);
    return Semantics(
      button: true,
      label: on ? 'Remove from saved' : 'Save deal',
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 2,
        shadowColor: const Color(0x3312203A),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => saved.toggleOffer(offer),
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(on ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                size: size * 0.45, color: on ? DB.sale : DB.ink),
          ),
        ),
      ),
    );
  }
}

/// Full-width or compact button in a solid colour.
class SolidButton extends StatelessWidget {
  const SolidButton(this.label,
      {super.key, required this.onPressed, this.bg = DB.ink, this.fg = Colors.white, this.height = 46, this.icon, this.outline = false});
  final String label;
  final VoidCallback? onPressed;
  final Color bg;
  final Color fg;
  final double height;
  final IconData? icon;
  final bool outline;

  @override
  Widget build(BuildContext context) {
    final color = outline ? Colors.white : bg;
    final text = outline ? bg : fg;
    return SizedBox(
      height: height,
      child: Material(
        color: onPressed == null ? color.withValues(alpha: 0.5) : color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(height * 0.26),
          side: outline ? BorderSide(color: bg, width: 1.5) : BorderSide.none,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(height * 0.26),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
              Flexible(
                child: Text(label,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: DB.body(height > 44 ? 14 : 12.5, color: text, weight: FontWeight.w800)),
              ),
              if (icon != null) ...[const SizedBox(width: 6), Icon(icon, size: 16, color: text)],
            ]),
          ),
        ),
      ),
    );
  }
}

/// Pill chips in a horizontal row (category / sort / store filters).
class PillRow<T> extends StatelessWidget {
  const PillRow({super.key, required this.values, required this.selected, required this.label, required this.onSelected, this.photo});

  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onSelected;

  /// Optional round photo at the start of each pill.
  final String? Function(T)? photo;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: DB.gutter),
        itemCount: values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final v = values[i];
          final on = v == selected;
          final img = photo?.call(v);
          return Material(
            color: on ? DB.ink : Colors.white,
            shape: StadiumBorder(side: BorderSide(color: on ? DB.ink : DB.border, width: 1.4)),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: () => onSelected(v),
              child: Padding(
                padding: EdgeInsets.fromLTRB(img == null ? 14 : 4, 0, 14, 0),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (img != null) ...[
                    ClipOval(child: Image.asset(img, width: 30, height: 30, fit: BoxFit.cover)),
                    const SizedBox(width: 7),
                  ],
                  Text(label(v), style: DB.body(12.5, color: on ? Colors.white : DB.ink, weight: FontWeight.w700)),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.subtitle, this.action, this.onAction, this.top = 20});
  final String title;
  final String? subtitle;
  final String? action;
  final VoidCallback? onAction;
  final double top;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(DB.gutter, top, DB.gutter, 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: DB.heading(18)),
            if (subtitle != null) Text(subtitle!, style: DB.body(12, color: DB.muted)),
          ]),
        ),
        if (action != null)
          InkWell(
            onTap: onAction,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(action!, style: DB.body(12.5, color: DB.orange, weight: FontWeight.w700)),
            ),
          ),
      ]),
    );
  }
}

/// Search box on white (inside dark headers or on the page).
class SearchBox extends StatelessWidget {
  const SearchBox({super.key, this.hint = 'Search', this.onChanged, this.onTap, this.controller, this.readOnly = false, this.autofocus = false});
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final TextEditingController? controller;
  final bool readOnly;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: DB.borderStrong)),
      child: Row(children: [
        const Icon(Icons.search_rounded, color: DB.muted, size: 21),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            autofocus: autofocus,
            onTap: onTap,
            onChanged: onChanged,
            style: DB.body(14, weight: FontWeight.w500),
            cursorColor: DB.orange,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              hintText: hint,
              hintStyle: DB.body(14, color: const Color(0xFF8A93A5), weight: FontWeight.w500),
            ),
          ),
        ),
      ]),
    );
  }
}

/// Navy page header used by every tab: big title, a line under it, then [child] (usually a search box).
class DarkHeader extends StatelessWidget {
  const DarkHeader({super.key, required this.title, this.trailing, this.child, this.leading});
  final String title;
  final String? trailing;
  final Widget? child;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DB.ink,
      padding: EdgeInsets.fromLTRB(DB.gutter, MediaQuery.paddingOf(context).top + 14, DB.gutter, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          if (leading != null) ...[leading!, const SizedBox(width: 10)],
          Expanded(child: Text(title, style: DB.headline(24, color: Colors.white))),
          if (trailing != null) Text(trailing!, style: DB.body(12, color: const Color(0xFFC9D2DE))),
        ]),
        if (child != null) ...[const SizedBox(height: 12), child!],
      ]),
    );
  }
}

class BackSquare extends StatelessWidget {
  const BackSquare({super.key, this.onDark = true});
  final bool onDark;

  @override
  Widget build(BuildContext context) => Material(
        color: onDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.of(context).maybePop(),
          child: const SizedBox(width: 44, height: 44, child: Icon(Icons.chevron_left_rounded, color: Colors.white, size: 26)),
        ),
      );
}

// ------------------------------------------------------------------ deal cards

/// Product-style deal card for 2-column grids: photo, badge, heart, store, title, value, Get deal.
class DealCard extends StatelessWidget {
  const DealCard({super.key, required this.offer, required this.onOpen, this.onStore, this.photoHeight = 120});

  final Offer offer;
  final VoidCallback onOpen;
  final VoidCallback? onStore;
  final double photoHeight;

  @override
  Widget build(BuildContext context) {
    final look = StoreLook.forOffer(offer);
    final ends = expiryText(offer);
    final soon = ends == 'Ends today' || ends == 'Ends in 1 day';
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: DB.border)),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
          height: photoHeight,
          child: Stack(fit: StackFit.expand, children: [
            GestureDetector(onTap: onOpen, child: Photo(url: offer.imageUrl, fallback: offerPhoto(offer))),
            Positioned(left: 8, top: 8, child: SaleBadge(offerBadge(offer), size: 9.5)),
            Positioned(right: 6, top: 6, child: SaveHeart(offer: offer, size: 34)),
            if (soon) Positioned(left: 8, bottom: 8, child: SaleBadge('⏱ $ends', color: DB.ink, size: 9)),
          ]),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              GestureDetector(onTap: onStore, child: StoreChip(name: offer.storeName, look: look)),
              const SizedBox(height: 5),
              Expanded(
                child: Text(offer.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: DB.heading(12.5, weight: FontWeight.w700)),
              ),
              Text(offerValue(offer), style: DB.headline(14, color: DB.price)),
              const SizedBox(height: 6),
              SolidButton(offer.kind == OfferKind.code ? 'Get code' : 'Get deal', onPressed: onOpen, height: 34),
            ]),
          ),
        ),
      ]),
    );
  }
}

/// Horizontal deal card for lists (Saved, search results).
class DealRow extends StatelessWidget {
  const DealRow({super.key, required this.offer, required this.onOpen});
  final Offer offer;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final look = StoreLook.forOffer(offer);
    final ends = expiryText(offer);
    final soon = ends == 'Ends today' || ends == 'Ends in 1 day';
    return Container(
      height: 128,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: DB.border)),
      clipBehavior: Clip.antiAlias,
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
          width: 108,
          child: Stack(fit: StackFit.expand, children: [
            GestureDetector(onTap: onOpen, child: Photo(url: offer.imageUrl, fallback: offerPhoto(offer))),
            Positioned(left: 6, top: 6, child: SaleBadge(offerBadge(offer), size: 8.5)),
          ]),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Expanded(child: StoreChip(name: offer.storeName, look: look)), SaveHeart(offer: offer, size: 32)]),
              Expanded(child: Text(offer.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: DB.heading(13, weight: FontWeight.w700))),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(offerValue(offer), style: DB.headline(14, color: DB.price)),
                    Text(ends, style: DB.body(10.5, color: soon ? const Color(0xFFC2410C) : DB.muted, weight: FontWeight.w700)),
                  ]),
                ),
                SolidButton(offer.kind == OfferKind.code ? 'Get code' : 'Use deal', onPressed: onOpen, height: 34),
              ]),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ------------------------------------------------------------------ store cards

/// Wide card for horizontal "Featured stores" rows.
class StoreFeatureCard extends StatelessWidget {
  const StoreFeatureCard({super.key, required this.store, required this.onTap, this.width = 230});
  final Store store;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    final look = StoreLook.of(store);
    return SizedBox(
      width: width,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: DB.border)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              SizedBox(
                height: 84,
                child: FadedCover(
                  gradient: look.gradient,
                  photo: look.cover,
                  widthFactor: 0.8,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: SizedBox(
                        width: width * 0.5,
                        child: Text(look.category.label, maxLines: 2, style: DB.heading(11.5, color: Colors.white)),
                      ),
                    ),
                  ),
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    StoreBadge(look: look, logoUrl: store.logoUrl, size: 44, ring: 2),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(store.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: DB.heading(14)),
                        Text('${store.offerCount} offers', style: DB.body(11, color: DB.muted)),
                      ]),
                    ),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// List card for the Stores tab and category pages: cover photo + tile on the left.
class StoreListCard extends StatelessWidget {
  const StoreListCard({super.key, required this.store, required this.onTap, this.trailing});
  final Store store;
  final VoidCallback onTap;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final look = StoreLook.of(store);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 112,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: DB.border)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SizedBox(
              width: 100,
              child: Stack(fit: StackFit.expand, children: [
                DecoratedBox(decoration: BoxDecoration(gradient: look.gradient)),
                Opacity(opacity: 0.85, child: Image.asset(look.cover, fit: BoxFit.cover)),
                Positioned(left: 10, bottom: 10, child: StoreBadge(look: look, logoUrl: store.logoUrl, size: 42, ring: 2)),
              ]),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(look.category.label.toUpperCase(), style: DB.label(9)),
                  const SizedBox(height: 2),
                  Text(store.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: DB.heading(14)),
                  const Spacer(),
                  Row(children: [
                    Expanded(
                      child: Text(trailing ?? '${store.offerCount} ${store.offerCount == 1 ? 'offer' : 'offers'}',
                          style: DB.body(11.5, color: DB.muted, weight: FontWeight.w600)),
                    ),
                    Container(
                      height: 30,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: look.button, borderRadius: BorderRadius.circular(8)),
                      child: Text('Open', style: DB.body(11.5, color: look.buttonText, weight: FontWeight.w800)),
                    ),
                  ]),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ categories

/// Round category photo with a label underneath (home row, category chips).
class CategoryCircle extends StatelessWidget {
  const CategoryCircle({super.key, required this.label, required this.photo, required this.onTap, this.selected = false});
  final String label;
  final String photo;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 76,
        child: Column(children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: selected ? DB.orange : Colors.white, width: 2.5),
              boxShadow: const [BoxShadow(color: Color(0x2412203A), blurRadius: 10, offset: Offset(0, 3))],
              image: DecorationImage(image: AssetImage(photo), fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 6),
          Text(label, maxLines: 2, textAlign: TextAlign.center, style: DB.body(11, weight: FontWeight.w700).copyWith(height: 1.2)),
        ]),
      ),
    );
  }
}

/// Photo tile with the name over a dark fade (Categories tab grid).
class CategoryPhotoTile extends StatelessWidget {
  const CategoryPhotoTile({super.key, required this.label, required this.meta, required this.photo, required this.onTap, this.badge});
  final String label;
  final String meta;
  final String photo;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(fit: StackFit.expand, children: [
          Image.asset(photo, fit: BoxFit.cover),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Color(0xB8000000), Color(0x00000000)],
                stops: [0, 0.6],
              ),
            ),
          ),
          if (badge != null) Positioned(right: 8, top: 8, child: SaleBadge(badge!, size: 9)),
          Positioned(
            left: 12,
            right: 12,
            bottom: 10,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: DB.heading(15, color: Colors.white)),
              Text(meta, style: DB.body(11, color: Colors.white.withValues(alpha: 0.9), weight: FontWeight.w600)),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Simple centred loader / message for the new light pages.
class Loading extends StatelessWidget {
  const Loading({super.key});
  @override
  Widget build(BuildContext context) =>
      const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)));
}

class EmptyNote extends StatelessWidget {
  const EmptyNote(this.text, {super.key, this.action, this.onAction});
  final String text;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: DB.gutter, vertical: 8),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFC5D1DF)),
        ),
        child: Column(children: [
          Text(text, textAlign: TextAlign.center, style: DB.body(13, color: DB.body2)),
          if (action != null) ...[
            const SizedBox(height: 10),
            SolidButton(action!, onPressed: onAction, height: 40),
          ],
        ]),
      );
}
