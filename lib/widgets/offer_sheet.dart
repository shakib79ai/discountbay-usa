import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../screens/store_screen.dart';
import '../state/saved.dart';
import '../theme/identity.dart';
import '../theme/tokens.dart';
import 'components.dart';
import 'shop.dart';

/// Opens the deal sheet: photo, store, title, value, details and the action.
/// Codes: copy → open store. Deals: one tap opens the store (the price applies from the link).
Future<void> showOfferSheet(BuildContext context, Offer offer, {bool fromStorePage = false}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (_) => _OfferSheet(offer: offer, fromStorePage: fromStorePage),
  );
}

class _OfferSheet extends StatefulWidget {
  const _OfferSheet({required this.offer, required this.fromStorePage});
  final Offer offer;
  final bool fromStorePage;

  @override
  State<_OfferSheet> createState() => _OfferSheetState();
}

class _OfferSheetState extends State<_OfferSheet> {
  bool _copied = false;

  Offer get o => widget.offer;

  Future<void> _copyAndGo() async {
    await Clipboard.setData(ClipboardData(text: o.code!));
    HapticFeedback.mediumImpact();
    if (!mounted) return;
    setState(() => _copied = true);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Code ${o.code} copied — paste it at checkout')));
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) await openExternal(context, o.url);
  }

  @override
  Widget build(BuildContext context) {
    final saved = context.watch<SavedState>();
    final look = StoreLook.forOffer(o);
    final isCode = o.kind == OfferKind.code;
    final maxH = MediaQuery.sizeOf(context).height * 0.9;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxH),
      child: Container(
        decoration: const BoxDecoration(color: DB.bg, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SizedBox(
              height: 200,
              child: Stack(fit: StackFit.expand, children: [
                Photo(url: o.imageUrl, fallback: offerPhoto(o)),
                Positioned(
                  top: 8,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.white70, borderRadius: BorderRadius.circular(3))),
                  ),
                ),
                Positioned(left: 14, bottom: 14, child: SaleBadge(offerBadge(o), size: 11)),
                Positioned(right: 12, top: 16, child: SaveHeart(offer: o)),
              ]),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(18, 16, 18, MediaQuery.paddingOf(context).bottom + 18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                StoreChip(name: o.storeName, look: look, size: 22),
                const SizedBox(height: 8),
                Text(o.title, style: DB.heading(19)),
                const SizedBox(height: 6),
                Text(offerValue(o), style: DB.headline(26, color: DB.price)),
                if (o.description != null && o.description != o.title) ...[
                  const SizedBox(height: 8),
                  Text(o.description!, style: DB.body(14, color: DB.body2)),
                ],
                const SizedBox(height: 14),
                Row(children: [
                  _Fact(o.verified ? 'Verified' : 'Unverified', 'by DiscountBay', color: o.verified ? DB.verified : DB.muted),
                  const SizedBox(width: 8),
                  _Fact(isCode ? 'Code' : 'Deal', isCode ? 'copy at checkout' : 'no code needed'),
                  const SizedBox(width: 8),
                  _Fact(expiryText(o), o.expiresAt == null ? 'no end date' : 'end date'),
                ]),
                const SizedBox(height: 16),
                if (isCode) ...[
                  GestureDetector(
                    onTap: o.expired ? null : _copyAndGo,
                    child: Container(
                      height: 62,
                      decoration: BoxDecoration(
                        color: _copied ? const Color(0xFFE3F6E8) : const Color(0xFFFFF7F0),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _copied ? DB.verified : look.brand, width: 2),
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(o.code!, style: DB.mono(24)),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(color: _copied ? DB.verified : DB.ink, borderRadius: BorderRadius.circular(6)),
                          child: Text(_copied ? 'COPIED' : 'COPY', style: DB.body(11, color: Colors.white, weight: FontWeight.w800)),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SolidButton(_copied ? 'Copied! Opening store…' : 'Copy code & open ${o.storeName}',
                      bg: look.button, fg: look.buttonText, height: 52, onPressed: o.expired ? null : _copyAndGo),
                ] else
                  SolidButton('Get deal at ${o.storeName}',
                      icon: Icons.open_in_new_rounded,
                      bg: look.button,
                      fg: look.buttonText,
                      height: 52,
                      onPressed: o.expired ? null : () => openExternal(context, o.url)),
                if (!widget.fromStorePage && o.storeSlug.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  SolidButton('See all ${o.storeName} offers', outline: true, onPressed: () {
                    final nav = Navigator.of(context);
                    nav.pop();
                    nav.push(StoreScreen.route(o.storeSlug));
                  }),
                ],
                const SizedBox(height: 12),
                Text(
                  saved.isSaved(o) ? 'Saved — find it under the Saved tab.' : 'DiscountBay may earn a commission; your price stays the same.',
                  textAlign: TextAlign.center,
                  style: DB.body(11, color: DB.muted),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.value, this.label, {this.color = DB.ink});
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: DB.border)),
          child: Column(children: [
            Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: DB.heading(12.5, color: color)),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: DB.body(10.5, color: DB.muted)),
          ]),
        ),
      );
}
