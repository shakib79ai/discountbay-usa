import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/saved.dart';
import '../theme/tokens.dart';
import '../widgets/components.dart' show expiryText;
import '../widgets/offer_sheet.dart';
import '../widgets/shop.dart';
import 'shell.dart';
import 'store_screen.dart';

/// Saved tab: saved deals (photo cards) and followed stores (store cards), kept on the phone.
class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  bool _stores = false;

  @override
  Widget build(BuildContext context) {
    final saved = context.watch<SavedState>();
    final offers = saved.offers;
    final stores = saved.stores;
    final endingToday = offers.where((o) => expiryText(o) == 'Ends today').length;

    return CustomScrollView(slivers: [
      SliverToBoxAdapter(
        child: DarkHeader(
          title: 'Saved',
          trailing: 'Kept on this phone',
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              for (final (isStores, label) in [(false, 'Deals · ${offers.length}'), (true, 'Stores · ${stores.length}')])
                Expanded(
                  child: Material(
                    color: _stores == isStores ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(9),
                      onTap: () => setState(() => _stores = isStores),
                      child: SizedBox(
                        height: 40,
                        child: Center(
                          child: Text(label,
                              style: DB.body(13, color: _stores == isStores ? DB.ink : Colors.white, weight: FontWeight.w700)),
                        ),
                      ),
                    ),
                  ),
                ),
            ]),
          ),
        ),
      ),
      if (!_stores) ...[
        if (endingToday > 0)
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(DB.gutter, 12, DB.gutter, 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: DB.orangeSoft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFFB98A)),
              ),
              child: Row(children: [
                const Text('⏱', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text.rich(TextSpan(children: [
                    TextSpan(
                        text: '$endingToday saved ${endingToday == 1 ? 'deal ends' : 'deals end'} today. ',
                        style: DB.body(13, weight: FontWeight.w800)),
                    TextSpan(text: 'Use them before they’re gone.', style: DB.body(13)),
                  ])),
                ),
              ]),
            ),
          ),
        if (offers.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: EmptyNote('No saved deals yet. Tap ♡ on any deal to keep it here.',
                  action: 'Browse top deals', onAction: () => Shell.switchTab(context, 0)),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(DB.gutter, 12, DB.gutter, 24),
            sliver: SliverList.separated(
              itemCount: offers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => DealRow(offer: offers[i], onOpen: () => showOfferSheet(context, offers[i])),
            ),
          ),
      ] else ...[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(DB.gutter, 12, DB.gutter, 0),
            child: Text('You’ll see these stores’ newest deals first.', style: DB.body(12, color: DB.muted)),
          ),
        ),
        if (stores.isEmpty)
          SliverToBoxAdapter(
            child: EmptyNote('You’re not following any stores yet. Open a store and tap “Follow store”.',
                action: 'Find stores', onAction: () => Shell.switchTab(context, 1)),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(DB.gutter, 10, DB.gutter, 24),
            sliver: SliverList.separated(
              itemCount: stores.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => StoreListCard(
                store: stores[i],
                trailing: 'Following',
                onTap: () => Navigator.of(context).push(StoreScreen.route(stores[i].slug)),
              ),
            ),
          ),
      ],
    ]);
  }
}
