import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../screens/store_screen.dart';
import '../state/saved.dart';
import '../theme/tokens.dart';
import 'components.dart';
import 'decor.dart';

/// Opens the coupon "ticket" bottom sheet. For codes: reveal → copy → open store.
/// For deals: one tap opens the store (deal applies automatically).
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Code ${o.code} copied — paste it at checkout')),
    );
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) await openExternal(context, o.url);
  }

  @override
  Widget build(BuildContext context) {
    final saved = context.watch<SavedState>();
    final isCode = o.kind == OfferKind.code;
    final (top, bottom) = o.stampParts;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ClipPath(
              clipper: TicketClipper(notchY: 150, notchRadius: 12),
              child: Container(
                color: DB.paper,
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(color: DB.line, borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 104,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          NetLogo(url: o.storeLogo, name: o.storeName, size: 56),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(o.storeName.toUpperCase(), style: DB.mono(11, color: DB.ink.withValues(alpha: 0.55))),
                                const SizedBox(height: 4),
                                Text(o.title,
                                    maxLines: 3, overflow: TextOverflow.ellipsis, style: DB.heading(18)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 60),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    const DashedLine(),
                    const SizedBox(height: 18),
                    if (o.description != null && o.description != o.title) ...[
                      Text(o.description!, style: DB.body(14, color: DB.ink.withValues(alpha: 0.8))),
                      const SizedBox(height: 16),
                    ],
                    if (isCode) ...[
                      _CodeBox(code: o.code!, copied: _copied, onCopy: _copyAndGo),
                      const SizedBox(height: 14),
                      PillButton(_copied ? 'Copied! Opening store…' : 'Copy code & open store',
                          icon: _copied ? Icons.check : Icons.content_copy,
                          style: PillStyle.coral,
                          expand: true,
                          onPressed: o.expired ? null : _copyAndGo),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: DB.mint.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(DB.radius),
                        ),
                        child: Row(children: [
                          const Icon(Icons.bolt, color: DB.mint),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text('No code needed — the discount applies automatically at the store.',
                                style: DB.body(13, weight: FontWeight.w500)),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 14),
                      PillButton('Get this deal',
                          icon: Icons.open_in_new,
                          style: PillStyle.ink,
                          expand: true,
                          onPressed: o.expired ? null : () => openExternal(context, o.url)),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: PillButton(saved.isSaved(o) ? 'Saved' : 'Save',
                              icon: saved.isSaved(o) ? Icons.bookmark : Icons.bookmark_border,
                              style: PillStyle.outlineInk,
                              dense: true,
                              expand: true,
                              onPressed: () => saved.toggleOffer(o)),
                        ),
                        if (!widget.fromStorePage && o.storeSlug.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: PillButton('All ${o.storeName} offers',
                                style: PillStyle.outlineInk,
                                dense: true,
                                expand: true,
                                onPressed: () {
                                  final nav = Navigator.of(context);
                                  nav.pop();
                                  nav.push(StoreScreen.route(o.storeSlug));
                                }),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(expiryText(o), style: DB.mono(11, color: DB.ink.withValues(alpha: 0.6))),
                        if (o.verified)
                          Text('VERIFIED BY DISCOUNTBAY', style: DB.mono(10, color: DB.mint)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Barcode(height: 30, seed: o.id.hashCode),
                    const SizedBox(height: 6),
                    Center(
                      child: Text('DB-${o.id.padLeft(6, '0')}',
                          style: DB.mono(10, color: DB.ink.withValues(alpha: 0.5))),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(top: 26, right: 18, child: Stamp(top: top, bottom: bottom, size: 64)),
          ],
        ),
      ),
    );
  }
}

class _CodeBox extends StatelessWidget {
  const _CodeBox({required this.code, required this.copied, required this.onCopy});
  final String code;
  final bool copied;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onCopy,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: copied ? DB.mint.withValues(alpha: 0.14) : DB.mustard.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(DB.radius),
          border: Border.all(color: copied ? DB.mint : DB.ink, width: 1.6),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(code,
                  textAlign: TextAlign.center, style: DB.mono(22, weight: FontWeight.w500, color: DB.ink)),
            ),
            Icon(copied ? Icons.check_circle : Icons.content_copy, color: copied ? DB.mint : DB.ink),
          ],
        ),
      ),
    );
  }
}
