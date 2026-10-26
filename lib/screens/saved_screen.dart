import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/saved.dart';
import '../theme/tokens.dart';
import '../widgets/components.dart';
import '../widgets/decor.dart';
import '../widgets/offer_sheet.dart';
import 'shell.dart';
import 'store_screen.dart';

/// Saved offers and followed stores (kept on the device).
class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final saved = context.watch<SavedState>();
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('SAVED', style: DB.display(24)),
          bottom: TabBar(
            indicatorColor: DB.mustard,
            indicatorWeight: 3,
            labelColor: DB.paper,
            unselectedLabelColor: DB.paper.withValues(alpha: 0.55),
            labelStyle: DB.body(14, color: DB.paper, weight: FontWeight.w700),
            dividerColor: DB.lineOnInk,
            tabs: [
              Tab(text: 'Offers (${saved.offers.length})'),
              Tab(text: 'Stores (${saved.stores.length})'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            saved.offers.isEmpty
                ? _Empty(
                    icon: Icons.bookmark_border,
                    text: 'Tap the bookmark on any code or deal to keep it here.',
                    cta: 'Browse top deals',
                    onTap: () => Shell.switchTab(context, 0),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(DB.gutter),
                    itemCount: saved.offers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final o = saved.offers[i];
                      return Dismissible(
                        key: ValueKey('offer-${o.id}-${o.title}'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          child: const Icon(Icons.delete_outline, color: DB.coral),
                        ),
                        onDismissed: (_) => saved.toggleOffer(o),
                        child: OfferTicket(offer: o, onOpen: () => showOfferSheet(context, o)),
                      );
                    },
                  ),
            saved.stores.isEmpty
                ? _Empty(
                    icon: Icons.storefront_outlined,
                    text: 'Follow stores to find their latest codes fast.',
                    cta: 'Browse stores',
                    onTap: () => Shell.switchTab(context, 1),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: saved.stores.length,
                    separatorBuilder: (_, __) => const Padding(
                      padding: EdgeInsets.symmetric(horizontal: DB.gutter),
                      child: DashedLine(color: DB.lineOnInk),
                    ),
                    itemBuilder: (context, i) {
                      final s = saved.stores[i];
                      return StoreRow(
                        store: s,
                        onTap: () => Navigator.of(context).push(StoreScreen.route(s.slug)),
                        trailing: IconButton(
                          tooltip: 'Unfollow',
                          icon: const Icon(Icons.close, color: DB.paper),
                          onPressed: () => saved.toggleStore(s),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.icon, required this.text, required this.cta, required this.onTap});
  final IconData icon;
  final String text;
  final String cta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(child: MessageState(icon: icon, text: text, actionLabel: cta, onAction: onTap));
  }
}
