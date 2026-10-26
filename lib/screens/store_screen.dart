import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../data/repository.dart';
import '../state/saved.dart';
import '../theme/tokens.dart';
import '../widgets/components.dart';
import '../widgets/decor.dart';
import '../widgets/newsletter.dart';
import '../widgets/offer_sheet.dart';

/// Store page: header (logo, "X coupons & deals", stats, Follow / Visit),
/// tabs All · Codes · Deals, sort, offer tickets, expired "Missed these?",
/// how-to-redeem, about, similar stores, store newsletter.
class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key, required this.slug});
  final String slug;

  static Route<void> route(String slug) => MaterialPageRoute(builder: (_) => StoreScreen(slug: slug));

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

enum _Tab { all, codes, deals }

class _StoreScreenState extends State<StoreScreen> {
  late final Repository _repo = context.read<Repository>();
  late Future<Store?> _store;
  late Future<List<Offer>> _offers;
  late Future<List<Store>> _similar;
  _Tab _tab = _Tab.all;
  OfferSort _sort = OfferSort.recommended;
  int _visible = 10;

  @override
  void initState() {
    super.initState();
    _store = _repo.store(widget.slug);
    _offers = _repo.storeOffers(widget.slug, sort: _sort);
    _similar = _repo.similarStores(widget.slug);
  }

  void _reload() => setState(() {
        _store = _repo.store(widget.slug);
        _offers = _repo.storeOffers(widget.slug, sort: _sort);
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<Store?>(future: _store, builder: (_, s) => Text(s.data?.name ?? '')),
        actions: [
          FutureBuilder<Store?>(
            future: _store,
            builder: (_, s) => s.data == null ? const SizedBox.shrink() : _FollowButton(store: s.data!),
          ),
        ],
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: DashedLine(color: DB.lineOnInk)),
      ),
      body: AsyncView<Store?>(
        future: _store,
        onRetry: _reload,
        builder: (context, store) {
          if (store == null) {
            return const MessageState(icon: Icons.storefront, text: "We couldn't find this store.");
          }
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _StoreHeader(store: store, offers: _offers)),
              SliverToBoxAdapter(
                child: FutureBuilder<List<Offer>>(
                  future: _offers,
                  builder: (context, snap) {
                    final live = (snap.data ?? const <Offer>[]).where((o) => !o.expired);
                    final codes = live.where((o) => o.kind == OfferKind.code).length;
                    return Padding(
                      padding: const EdgeInsets.only(top: 18, bottom: 6),
                      child: ChipBar<_Tab>(
                        values: _Tab.values,
                        selected: _tab,
                        onInk: true,
                        label: (t) => switch (t) {
                          _Tab.all => 'All (${live.length})',
                          _Tab.codes => 'Codes ($codes)',
                          _Tab.deals => 'Deals (${live.length - codes})',
                        },
                        onSelected: (t) => setState(() {
                          _tab = t;
                          _visible = 10;
                        }),
                      ),
                    );
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(DB.gutter, 4, 8, 8),
                  child: Row(
                    children: [
                      Text('SORT', style: DB.mono(10.5, color: DB.paper.withValues(alpha: 0.5))),
                      const SizedBox(width: 8),
                      DropdownButton<OfferSort>(
                        value: _sort,
                        dropdownColor: DB.inkSoft,
                        underline: const SizedBox.shrink(),
                        iconEnabledColor: DB.mustard,
                        style: DB.body(13, color: DB.paper, weight: FontWeight.w600),
                        items: const [
                          DropdownMenuItem(value: OfferSort.recommended, child: Text('Recommended')),
                          DropdownMenuItem(value: OfferSort.biggestSavings, child: Text('Biggest savings')),
                          DropdownMenuItem(value: OfferSort.newest, child: Text('Newest')),
                          DropdownMenuItem(value: OfferSort.endingSoon, child: Text('Ending soon')),
                        ],
                        onChanged: (s) {
                          if (s == null) return;
                          setState(() {
                            _sort = s;
                            _offers = _repo.storeOffers(widget.slug, sort: s);
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              AsyncView<List<Offer>>(
                future: _offers,
                sliver: true,
                onRetry: _reload,
                builder: (context, all) {
                  final live = all.where((o) => !o.expired).where((o) => switch (_tab) {
                        _Tab.all => true,
                        _Tab.codes => o.kind == OfferKind.code,
                        _Tab.deals => o.kind == OfferKind.deal,
                      }).toList();
                  final expired = all.where((o) => o.expired).take(6).toList();
                  final shown = live.take(_visible).toList();
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: DB.gutter),
                    sliver: SliverList.list(children: [
                      if (live.isEmpty)
                        MessageState(
                          icon: Icons.local_offer_outlined,
                          text: _tab == _Tab.codes
                              ? 'No codes right now — the deals tab still has savings.'
                              : 'No active offers right now. Follow the store to hear about new ones.',
                        ),
                      for (final o in shown) ...[
                        OfferTicket(
                          offer: o,
                          showStore: false,
                          onOpen: () => showOfferSheet(context, o, fromStorePage: true),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (live.length > shown.length)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 8),
                          child: PillButton('Show ${live.length - shown.length} more offers',
                              style: PillStyle.outlinePaper,
                              expand: true,
                              onPressed: () => setState(() => _visible += 20)),
                        ),
                      if (expired.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        Text('MISSED THESE?', style: DB.display(22)),
                        const SizedBox(height: 4),
                        Text('Recently expired — shown for reference.',
                            style: DB.body(13, color: DB.paper.withValues(alpha: 0.6))),
                        const SizedBox(height: 12),
                        for (final o in expired) ...[
                          OfferTicket(offer: o, showStore: false, onOpen: () {}),
                          const SizedBox(height: 12),
                        ],
                      ],
                    ]),
                  );
                },
              ),
              SliverToBoxAdapter(child: PaperBand(child: _RedeemSteps(storeName: store.name))),
              if ((store.about ?? '').isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(DB.gutter, 6, DB.gutter, 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 22),
                        const Eyebrow('About'),
                        const SizedBox(height: 6),
                        Text(store.name.toUpperCase(), style: DB.display(24)),
                        const SizedBox(height: 10),
                        Text(store.about!, style: DB.body(14.5, color: DB.paper.withValues(alpha: 0.8))),
                      ],
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SectionHeader(title: 'You might also like', onInk: true)),
              SliverToBoxAdapter(
                child: AsyncView<List<Store>>(
                  future: _similar,
                  isEmpty: (l) => l.isEmpty,
                  emptyText: 'More stores coming soon.',
                  builder: (context, list) => SizedBox(
                    height: 150,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: DB.gutter),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, i) => SizedBox(
                        width: 118,
                        child: StoreTile(
                          store: list[i],
                          onTap: () => Navigator.of(context).pushReplacement(StoreScreen.route(list[i].slug)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 28)),
              SliverToBoxAdapter(child: NewsletterBand(storeName: store.name)),
              SliverToBoxAdapter(child: SizedBox(height: MediaQuery.paddingOf(context).bottom + 16)),
            ],
          );
        },
      ),
    );
  }
}

class _StoreHeader extends StatelessWidget {
  const _StoreHeader({required this.store, required this.offers});
  final Store store;
  final Future<List<Offer>> offers;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(DB.gutter, 16, DB.gutter, 0),
      child: ClipPath(
        clipper: TicketClipper(notchY: 115, scallopEdges: true),
        child: Container(
          color: DB.paper,
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 76,
                child: Row(
                  children: [
                    NetLogo(url: store.logoUrl, name: store.name, size: 72, padding: 8),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (store.categoryName != null)
                            Text(store.categoryName!.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: DB.mono(10, color: DB.ink.withValues(alpha: 0.5))),
                          Text('${store.name} coupons & deals',
                              maxLines: 2, overflow: TextOverflow.ellipsis, style: DB.heading(19)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const DashedLine(),
              const SizedBox(height: 14),
              FutureBuilder<List<Offer>>(
                future: offers,
                builder: (context, snap) {
                  final live = (snap.data ?? const <Offer>[]).where((o) => !o.expired).toList();
                  final best = _bestDeal(live);
                  return Row(
                    children: [
                      _Stat(value: snap.hasData ? '${live.length}' : '—', label: 'Active offers'),
                      _Stat(value: best ?? '—', label: 'Best deal'),
                      const _Stat(value: 'Today', label: 'Verified', color: DB.mint),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              PillButton('Visit ${store.name}',
                  icon: Icons.open_in_new,
                  style: PillStyle.ink,
                  expand: true,
                  onPressed: store.websiteUrl == null ? null : () => openExternal(context, store.websiteUrl)),
            ],
          ),
        ),
      ),
    );
  }

  static String? _bestDeal(List<Offer> offers) {
    int bestPct = 0;
    String? label;
    for (final o in offers) {
      final m = RegExp(r'(\d+)\s*%').firstMatch(o.discountLabel ?? '');
      final pct = m == null ? 0 : int.parse(m.group(1)!);
      if (pct > bestPct) {
        bestPct = pct;
        label = '$pct%';
      }
    }
    return label;
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.color = DB.ink});
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: DB.display(22, color: color)),
          const SizedBox(height: 2),
          Text(label.toUpperCase(), style: DB.mono(9.5, color: DB.ink.withValues(alpha: 0.55))),
        ],
      ),
    );
  }
}

class _FollowButton extends StatelessWidget {
  const _FollowButton({required this.store});
  final Store store;

  @override
  Widget build(BuildContext context) {
    final saved = context.watch<SavedState>();
    final on = saved.isFollowing(store.slug);
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: PillButton(
        on ? 'Following' : 'Follow',
        icon: on ? Icons.check : Icons.add,
        dense: true,
        style: on ? PillStyle.outlinePaper : PillStyle.mustard,
        onPressed: () {
          saved.toggleStore(store);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(on ? 'Unfollowed ${store.name}' : 'Following ${store.name} — find it under Saved'),
            duration: const Duration(seconds: 2),
          ));
        },
      ),
    );
  }
}

class _RedeemSteps extends StatelessWidget {
  const _RedeemSteps({required this.storeName});
  final String storeName;

  @override
  Widget build(BuildContext context) {
    final steps = [
      'Pick a code or deal above and tap it.',
      'Codes are copied automatically — $storeName opens in your browser.',
      'Add items to your cart and go to checkout.',
      'Paste the code in the promo box. Deals apply on their own.',
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(DB.gutter, 0, DB.gutter, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 24, bottom: 14),
            child: Text('HOW TO REDEEM YOUR $storeName DEAL'.toUpperCase(), style: DB.display(22, color: DB.ink)),
          ),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('0${i + 1}', style: DB.mono(13, color: DB.coral)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(steps[i], style: DB.body(14))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
