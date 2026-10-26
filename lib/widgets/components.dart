import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/models.dart';
import '../state/saved.dart';
import '../theme/tokens.dart';
import 'decor.dart';

// ------------------------------------------------------------------ helpers

Future<void> openExternal(BuildContext context, String? url) async {
  final uri = url == null ? null : Uri.tryParse(url);
  if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Couldn't open the store link")));
    }
  }
}

String expiryText(Offer o) {
  final e = o.expiresAt;
  if (o.expired) return 'Expired';
  if (e == null) return 'Ongoing deal';
  final days = e.difference(DateTime.now()).inDays;
  if (days <= 0) return 'Ends today';
  if (days == 1) return 'Ends in 1 day';
  if (days <= 14) return 'Ends in $days days';
  return 'Ends ${DateFormat('MMM d, yyyy').format(e)}';
}

// ------------------------------------------------------------------ logos

/// Store logo from the API (SVG or raster), with an initial-letter fallback.
class NetLogo extends StatelessWidget {
  const NetLogo({super.key, required this.url, required this.name, this.size = 48, this.padding = 6});

  final String? url;
  final String name;
  final double size;
  final double padding;

  @override
  Widget build(BuildContext context) {
    final fallback = Center(
      child: Text(name.isEmpty ? '?' : name[0].toUpperCase(), style: DB.display(size * 0.42, color: DB.coral)),
    );
    Widget child = fallback;
    final u = url;
    if (u != null && u.isNotEmpty) {
      child = u.toLowerCase().split('?').first.endsWith('.svg')
          ? SvgPicture.network(u, fit: BoxFit.contain, placeholderBuilder: (_) => fallback)
          : CachedNetworkImage(
              imageUrl: u,
              fit: BoxFit.contain,
              placeholder: (_, __) => fallback,
              errorWidget: (_, __, ___) => fallback,
            );
    }
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DB.line),
      ),
      child: child,
    );
  }
}

// ------------------------------------------------------------------ buttons

enum PillStyle { mustard, coral, ink, outlineInk, outlinePaper }

class PillButton extends StatelessWidget {
  const PillButton(
    this.label, {
    super.key,
    required this.onPressed,
    this.style = PillStyle.mustard,
    this.icon,
    this.expand = false,
    this.dense = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final PillStyle style;
  final IconData? icon;
  final bool expand;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (style) {
      PillStyle.mustard => (DB.mustard, DB.ink, Colors.transparent),
      PillStyle.coral => (DB.coral, DB.ink, Colors.transparent),
      PillStyle.ink => (DB.ink, DB.paper, Colors.transparent),
      PillStyle.outlineInk => (Colors.transparent, DB.ink, DB.ink),
      PillStyle.outlinePaper => (Colors.transparent, DB.paper, DB.lineOnInk),
    };
    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[Icon(icon, size: dense ? 16 : 18, color: fg), const SizedBox(width: 6)],
        Flexible(
          child: Text(label,
              overflow: TextOverflow.ellipsis, style: DB.body(dense ? 13 : 14, color: fg, weight: FontWeight.w700)),
        ),
      ],
    );
    return Material(
      color: bg,
      shape: StadiumBorder(side: BorderSide(color: border, width: 1.4)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onPressed,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: dense ? 14 : 20, vertical: dense ? 9 : 13),
          child: content,
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ sections

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.actionLabel,
    this.onAction,
    this.onInk = false,
  });

  final String title;
  final String? eyebrow;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool onInk;

  @override
  Widget build(BuildContext context) {
    final fg = onInk ? DB.paper : DB.ink;
    return Padding(
      padding: const EdgeInsets.fromLTRB(DB.gutter, 28, DB.gutter, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null) ...[Eyebrow(eyebrow!), const SizedBox(height: 6)],
                Text(title.toUpperCase(), style: DB.display(26, color: fg)),
              ],
            ),
          ),
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              child: Text('$actionLabel →',
                  style: DB.body(13, color: onInk ? DB.mustard : DB.coral, weight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}

/// Horizontal filter chips (All / Codes / Deals / Ending soon).
class ChipBar<T> extends StatelessWidget {
  const ChipBar({
    super.key,
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelected,
    this.onInk = false,
  });

  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onSelected;
  final bool onInk;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: DB.gutter),
        itemCount: values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final v = values[i];
          final on = v == selected;
          final idleFg = onInk ? DB.paper : DB.ink;
          return GestureDetector(
            onTap: () => onSelected(v),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: on ? (onInk ? DB.mustard : DB.ink) : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: on ? Colors.transparent : (onInk ? DB.lineOnInk : DB.line), width: 1.4),
              ),
              child: Text(label(v),
                  style: DB.body(13, color: on ? (onInk ? DB.ink : DB.paper) : idleFg, weight: FontWeight.w600)),
            ),
          );
        },
      ),
    );
  }
}

// ------------------------------------------------------------------ offer ticket

/// The signature coupon card: paper ticket with side notches, dashed tear line,
/// tilted discount stamp, store logo, title, expiry and a CTA.
class OfferTicket extends StatelessWidget {
  const OfferTicket({super.key, required this.offer, required this.onOpen, this.showStore = true});

  final Offer offer;
  final VoidCallback onOpen;
  final bool showStore;

  @override
  Widget build(BuildContext context) {
    final saved = context.watch<SavedState>();
    final isCode = offer.kind == OfferKind.code;
    final (top, bottom) = offer.stampParts;
    final accent = offer.expired ? Colors.grey : (isCode ? DB.coral : DB.mint);

    return Opacity(
      opacity: offer.expired ? 0.6 : 1,
      child: ClipPath(
        clipper: TicketClipper(notchY: 104),
        child: Material(
          color: DB.paper,
          child: InkWell(
            onTap: onOpen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 104,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showStore) ...[
                          NetLogo(url: offer.storeLogo, name: offer.storeName, size: 52),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                if (offer.verified && !offer.expired) ...[
                                  const Icon(Icons.verified, size: 13, color: DB.mint),
                                  const SizedBox(width: 4),
                                  Text('VERIFIED', style: DB.mono(10, color: DB.mint)),
                                  const SizedBox(width: 8),
                                ],
                                Text(isCode ? 'CODE' : 'DEAL', style: DB.mono(10, color: accent)),
                              ]),
                              const SizedBox(height: 4),
                              if (showStore)
                                Text(offer.storeName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: DB.body(12, color: DB.ink.withValues(alpha: 0.6), weight: FontWeight.w600)),
                              Text(offer.title,
                                  maxLines: showStore ? 2 : 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: DB.heading(15)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Stamp(top: top, bottom: bottom, color: accent, size: 56),
                      ],
                    ),
                  ),
                ),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 14), child: DashedLine()),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 8, 12),
                  child: Row(
                    children: [
                      Icon(Icons.schedule, size: 14, color: DB.ink.withValues(alpha: 0.55)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(isCode ? expiryText(offer) : '${expiryText(offer)} · No code needed',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: DB.body(12, color: DB.ink.withValues(alpha: 0.6))),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: saved.isSaved(offer) ? 'Remove from saved' : 'Save',
                        onPressed: () => saved.toggleOffer(offer),
                        icon: Icon(saved.isSaved(offer) ? Icons.bookmark : Icons.bookmark_border,
                            color: saved.isSaved(offer) ? DB.coral : DB.ink, size: 22),
                      ),
                      if (!offer.expired)
                        PillButton(isCode ? 'Get Code' : 'Get Deal',
                            onPressed: onOpen, style: isCode ? PillStyle.coral : PillStyle.ink, dense: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ store tile

class StoreTile extends StatelessWidget {
  const StoreTile({super.key, required this.store, required this.onTap});
  final Store store;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DB.paper,
      borderRadius: BorderRadius.circular(DB.radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(DB.radius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              NetLogo(url: store.logoUrl, name: store.name, size: 56),
              const SizedBox(height: 8),
              Text(store.name,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: DB.heading(13, weight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text('${store.offerCount} offer${store.offerCount == 1 ? '' : 's'}',
                  style: DB.mono(10, color: DB.coral)),
            ],
          ),
        ),
      ),
    );
  }
}

class StoreRow extends StatelessWidget {
  const StoreRow({super.key, required this.store, required this.onTap, this.trailing});
  final Store store;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: DB.gutter, vertical: 10),
        child: Row(
          children: [
            NetLogo(url: store.logoUrl, name: store.name, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(store.name, style: DB.heading(15, color: DB.paper)),
                  Text(
                    [
                      '${store.offerCount} offers',
                      if (store.categoryName != null) store.categoryName!,
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DB.body(12, color: DB.paper.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ),
            trailing ?? Icon(Icons.chevron_right, color: DB.paper.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ hot deal card

class HotDealCard extends StatelessWidget {
  const HotDealCard({super.key, required this.offer, required this.onOpen, this.width = 280});
  final Offer offer;
  final VoidCallback onOpen;
  final double width;

  @override
  Widget build(BuildContext context) {
    final (top, bottom) = offer.stampParts;
    return SizedBox(
      width: width,
      child: Material(
        color: DB.paperDim,
        borderRadius: BorderRadius.circular(DB.radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: offer.imageUrl == null
                        ? Container(color: DB.inkSoft)
                        : CachedNetworkImage(
                            imageUrl: offer.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(color: DB.inkSoft),
                            errorWidget: (_, __, ___) => Container(color: DB.inkSoft),
                          ),
                  ),
                  Positioned(top: 10, right: 10, child: Stamp(top: top, bottom: bottom, size: 54)),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Flexible(
                        child: Text(offer.storeName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: DB.body(12, color: DB.ink.withValues(alpha: 0.6), weight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.verified, size: 13, color: DB.mint),
                    ]),
                    const SizedBox(height: 2),
                    Text(offer.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: DB.heading(16)),
                    if (offer.description != null) ...[
                      const SizedBox(height: 4),
                      Text(offer.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: DB.body(12.5, color: DB.ink.withValues(alpha: 0.7))),
                    ],
                    const SizedBox(height: 10),
                    Text('Get Deal →', style: DB.body(13, color: DB.coral, weight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ async states

/// FutureBuilder with on-brand loading / error / empty states and retry.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({
    super.key,
    required this.future,
    required this.builder,
    this.onRetry,
    this.onInk = true,
    this.isEmpty,
    this.emptyText = 'Nothing here yet.',
    this.sliver = false,
  });

  final Future<T> future;
  final Widget Function(BuildContext, T) builder;
  final VoidCallback? onRetry;
  final bool onInk;
  final bool Function(T)? isEmpty;
  final String emptyText;
  final bool sliver;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snap) {
        Widget wrap(Widget w) => sliver ? SliverToBoxAdapter(child: w) : w;
        if (snap.connectionState != ConnectionState.done) {
          return wrap(Padding(
            padding: const EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator(color: onInk ? DB.mustard : DB.coral, strokeWidth: 2.5)),
          ));
        }
        if (snap.hasError) {
          return wrap(MessageState(
            icon: Icons.wifi_off_rounded,
            text: "Couldn't load this right now.",
            actionLabel: onRetry == null ? null : 'Try again',
            onAction: onRetry,
            onInk: onInk,
          ));
        }
        final data = snap.data as T;
        if (isEmpty?.call(data) ?? false) {
          return wrap(MessageState(icon: Icons.local_offer_outlined, text: emptyText, onInk: onInk));
        }
        return builder(context, data);
      },
    );
  }
}

class MessageState extends StatelessWidget {
  const MessageState({super.key, required this.icon, required this.text, this.actionLabel, this.onAction, this.onInk = true});
  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool onInk;

  @override
  Widget build(BuildContext context) {
    final fg = onInk ? DB.paper : DB.ink;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: fg.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center, style: DB.body(14, color: fg.withValues(alpha: 0.75))),
          if (actionLabel != null) ...[
            const SizedBox(height: 16),
            PillButton(actionLabel!, onPressed: onAction, dense: true),
          ],
        ],
      ),
    );
  }
}

/// Paper-coloured band used for alternating page sections.
class PaperBand extends StatelessWidget {
  const PaperBand({super.key, required this.child, this.color = DB.paper, this.perfTop = true, this.perfBottom = true});
  final Widget child;
  final Color color;
  final bool perfTop;
  final bool perfBottom;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (perfTop) Perforation(background: color),
        Container(color: color, width: double.infinity, child: child),
        if (perfBottom) Perforation(background: color),
      ],
    );
  }
}
