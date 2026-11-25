import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../data/repository.dart';
import '../state/saved.dart';
import '../theme/identity.dart';
import '../theme/tokens.dart';
import '../widgets/components.dart' show openExternal, expiryText;
import '../widgets/offer_sheet.dart';
import '../widgets/shop.dart';

/// Store page — the store's own little shop: cover in its brand colour, logo tile, stats,
/// Follow / Visit, search inside the store, filter sheet, and offers as product cards.
class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key, required this.slug});
  final String slug;

  static Route<void> route(String slug) => MaterialPageRoute(builder: (_) => StoreScreen(slug: slug));

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

/// Filters chosen in the sheet.
class StoreFilters {
  const StoreFilters({this.kind, this.minSave = 0, this.endingSoon = false, this.sort = OfferSort.recommended});
  final OfferKind? kind; // null = all
  final int minSave;
  final bool endingSoon;
  final OfferSort sort;

  int get count => (kind != null ? 1 : 0) + (minSave > 0 ? 1 : 0) + (endingSoon ? 1 : 0);

  StoreFilters copyWith({OfferKind? kind, bool clearKind = false, int? minSave, bool? endingSoon, OfferSort? sort}) => StoreFilters(
        kind: clearKind ? null : (kind ?? this.kind),
        minSave: minSave ?? this.minSave,
        endingSoon: endingSoon ?? this.endingSoon,
        sort: sort ?? this.sort,
      );
}

class _StoreScreenState extends State<StoreScreen> {
  late final Repository _repo = context.read<Repository>();
  late Future<Store?> _store;
  late Future<List<Offer>> _offers;
  late Future<List<Store>> _similar;
  StoreFilters _f = const StoreFilters();
  String _q = '';
  int _visible = 10;

  @override
  void initState() {
    super.initState();
    _store = _repo.store(widget.slug);
    _offers = _repo.storeOffers(widget.slug, sort: _f.sort);
    _similar = _repo.similarStores(widget.slug);
  }

  void _reload() => setState(() {
        _store = _repo.store(widget.slug);
        _offers = _repo.storeOffers(widget.slug, sort: _f.sort);
      });

  void _apply(StoreFilters f) => setState(() {
        final resort = f.sort != _f.sort;
        _f = f;
        _visible = 10;
        if (resort) _offers = _repo.storeOffers(widget.slug, sort: f.sort);
      });

  List<Offer> _filter(List<Offer> all) {
    final q = _q.trim().toLowerCase();
    return all.where((o) {
      if (o.expired) return false;
      if (_f.kind != null && o.kind != _f.kind) return false;
      if (_f.minSave > 0 && savePercent(o) < _f.minSave) return false;
      if (_f.endingSoon && (o.expiresAt == null || o.expiresAt!.difference(DateTime.now()).inDays > 7)) return false;
      if (q.isNotEmpty && !'${o.title} ${o.description ?? ''}'.toLowerCase().contains(q)) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Store?>(
        future: _store,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const Center(child: Loading());
          final store = snap.data;
          if (snap.hasError || store == null) {
            return SafeArea(
              child: Column(children: [
                const Align(alignment: Alignment.centerLeft, child: Padding(padding: EdgeInsets.all(12), child: BackSquare(onDark: false))),
                EmptyNote(snap.hasError ? "Couldn't load this store." : "We couldn't find this store.",
                    action: snap.hasError ? 'Try again' : null, onAction: _reload),
              ]),
            );
          }
          final look = StoreLook.of(store);
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _StoreHeader(store: store, look: look, offers: _offers)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(DB.gutter, 14, DB.gutter, 0),
                  child: Row(children: [
                    Expanded(child: SearchBox(hint: 'Search ${store.name} offers', onChanged: (v) => setState(() => _q = v))),
                    const SizedBox(width: 8),
                    _FilterButton(
                      count: _f.count,
                      onTap: () async {
                        final f = await showStoreFilters(context, _f, accent: look.button, accentText: look.buttonText);
                        if (f != null) _apply(f);
                      },
                    ),
                  ]),
                ),
              ),
              FutureBuilder<List<Offer>>(
                future: _offers,
                builder: (context, s) {
                  if (s.connectionState != ConnectionState.done) return const SliverToBoxAdapter(child: Loading());
                  if (s.hasError) {
                    return SliverToBoxAdapter(child: EmptyNote("Couldn't load offers.", action: 'Try again', onAction: _reload));
                  }
                  final all = s.data ?? const <Offer>[];
                  final live = _filter(all);
                  final shown = live.take(_visible).toList();
                  final expired = all.where((o) => o.expired).take(4).toList();
                  return SliverMainAxisGroup(slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(DB.gutter, 14, DB.gutter, 8),
                        child: Row(children: [
                          Expanded(
                            child: Text(_f.count > 0 || _q.isNotEmpty ? 'Matching offers' : 'All offers',
                                style: DB.heading(17)),
                          ),
                          Text('${live.length} ${live.length == 1 ? 'offer' : 'offers'}', style: DB.body(12, color: DB.muted)),
                        ]),
                      ),
                    ),
                    if (live.isEmpty)
                      SliverToBoxAdapter(
                        child: EmptyNote(
                          all.isEmpty ? 'No active offers right now. Follow ${store.name} to hear about new ones.' : 'No offers match these filters.',
                          action: _f.count > 0 ? 'Clear filters' : null,
                          onAction: () => _apply(StoreFilters(sort: _f.sort)),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: DB.gutter),
                        sliver: SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, mainAxisExtent: 268),
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => DealCard(offer: shown[i], onOpen: () => showOfferSheet(context, shown[i], fromStorePage: true)),
                            childCount: shown.length,
                          ),
                        ),
                      ),
                    if (live.length > shown.length)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(DB.gutter, 12, DB.gutter, 0),
                          child: SolidButton('Load more · ${shown.length} of ${live.length} shown',
                              outline: true, onPressed: () => setState(() => _visible += 20)),
                        ),
                      ),
                    if (expired.isNotEmpty) ...[
                      const SliverToBoxAdapter(child: SectionTitle('Missed these?', subtitle: 'Recently expired — shown for reference')),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: DB.gutter),
                        sliver: SliverList.separated(
                          itemCount: expired.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) => Opacity(opacity: 0.55, child: DealRow(offer: expired[i], onOpen: () {})),
                        ),
                      ),
                    ],
                  ]);
                },
              ),
              SliverToBoxAdapter(child: _HowItWorks(storeName: store.name, accent: look.brand)),
              if ((store.about ?? '').isNotEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(DB.gutter, 12, DB.gutter, 0),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: DB.border)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('About ${store.name}', style: DB.heading(16)),
                      const SizedBox(height: 6),
                      Text(store.about!, style: DB.body(13.5, color: DB.body2)),
                      const SizedBox(height: 10),
                      Text('DiscountBay may earn a commission when you buy through these links. Your price stays the same.',
                          style: DB.body(11, color: DB.muted)),
                    ]),
                  ),
                ),
              const SliverToBoxAdapter(child: SectionTitle('More stores like this')),
              SliverToBoxAdapter(
                child: FutureBuilder<List<Store>>(
                  future: _similar,
                  builder: (_, s) {
                    final list = s.data ?? const <Store>[];
                    if (list.isEmpty) return const SizedBox(height: 4);
                    return SizedBox(
                      height: 132,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: DB.gutter),
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (_, i) => StoreFeatureCard(
                          store: list[i],
                          onTap: () => Navigator.of(context).pushReplacement(StoreScreen.route(list[i].slug)),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: MediaQuery.paddingOf(context).bottom + 24)),
            ],
          );
        },
      ),
    );
  }
}

class _StoreHeader extends StatelessWidget {
  const _StoreHeader({required this.store, required this.look, required this.offers});
  final Store store;
  final StoreLook look;
  final Future<List<Offer>> offers;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
          height: 170 + top,
          child: FadedCover(
            gradient: look.gradient,
            photo: look.cover,
            url: store.coverUrl,
            widthFactor: 0.8,
            child: Padding(
              padding: EdgeInsets.fromLTRB(12, top + 8, 12, 34),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const BackSquare(onDark: false),
                const Spacer(),
                FutureBuilder<List<Offer>>(
                  future: offers,
                  builder: (_, s) {
                    final best = (s.data ?? const <Offer>[]).fold<int>(0, (m, o) => savePercent(o) > m ? savePercent(o) : m);
                    return Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(best > 0 ? 'Save up to $best%' : look.category.label,
                          style: DB.headline(22, color: Colors.white)),
                    );
                  },
                ),
              ]),
            ),
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -26),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: DB.gutter),
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              StoreBadge(look: look, logoUrl: store.logoUrl, size: 64),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(store.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: DB.heading(19)),
                  Text('✓ ${store.offerCount} offers · verified today',
                      style: DB.body(11.5, color: DB.verified, weight: FontWeight.w700)),
                ]),
              ),
            ]),
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: DB.gutter),
            child: Row(children: [
              Expanded(child: _FollowButton(store: store)),
              const SizedBox(width: 8),
              Expanded(
                child: SolidButton('Visit store',
                    icon: Icons.open_in_new_rounded,
                    bg: look.button,
                    fg: look.buttonText,
                    onPressed: store.websiteUrl == null ? null : () => openExternal(context, store.websiteUrl)),
              ),
            ]),
          ),
        ),
      ]),
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
    return SolidButton(
      on ? 'Following' : 'Follow store',
      icon: on ? Icons.check_rounded : Icons.notifications_none_rounded,
      outline: !on,
      onPressed: () {
        saved.toggleStore(store);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(on ? 'Unfollowed ${store.name}' : 'Following ${store.name} — find it under Saved'),
          duration: const Duration(seconds: 2),
        ));
      },
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(clipBehavior: Clip.none, children: [
      Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: DB.borderStrong)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: const SizedBox(width: 48, height: 48, child: Icon(Icons.tune_rounded, color: DB.ink)),
        ),
      ),
      if (count > 0)
        Positioned(
          right: -4,
          top: -4,
          child: Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: DB.sale, shape: BoxShape.circle),
            child: Text('$count', style: DB.body(11, color: Colors.white, weight: FontWeight.w800)),
          ),
        ),
    ]);
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks({required this.storeName, required this.accent});
  final String storeName;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final steps = [
      ('Pick a deal', 'Open any offer above.'),
      ('Shop at $storeName', 'Deals apply from the link; codes are copied for you.'),
      ('Check out', 'Pay as usual and keep the savings.'),
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(DB.gutter, 20, DB.gutter, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: DB.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('How it works', style: DB.heading(16)),
        const SizedBox(height: 10),
        for (var i = 0; i < steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(8)),
                child: Text('${i + 1}', style: DB.heading(13, color: Colors.white)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(steps[i].$1, style: DB.body(13.5, weight: FontWeight.w700)),
                  Text(steps[i].$2, style: DB.body(12.5, color: DB.body2)),
                ]),
              ),
            ]),
          ),
      ]),
    );
  }
}

// ------------------------------------------------------------------ filter sheet

/// Bottom sheet with offer type, discount, ending soon and sort. Returns the new filters, or null.
Future<StoreFilters?> showStoreFilters(BuildContext context, StoreFilters current,
    {Color accent = DB.ink, Color accentText = Colors.white}) {
  return showModalBottomSheet<StoreFilters>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => _FilterSheet(current: current, accent: accent, accentText: accentText),
  );
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.current, required this.accent, required this.accentText});
  final StoreFilters current;
  final Color accent;
  final Color accentText;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late StoreFilters _f = widget.current;

  Widget _pills<T>(String title, List<(T, String)> options, T selected, ValueChanged<T> onPick) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: DB.heading(14)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final (v, label) in options)
          ChoiceChip(
            label: Text(label),
            selected: v == selected,
            onSelected: (_) => onPick(v),
            showCheckmark: false,
            labelStyle: DB.body(13, color: v == selected ? widget.accentText : DB.ink, weight: FontWeight.w700),
            selectedColor: widget.accent,
            backgroundColor: Colors.white,
            side: BorderSide(color: v == selected ? widget.accent : DB.border, width: 1.4),
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          ),
      ]),
      const SizedBox(height: 16),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(DB.gutter, 10, DB.gutter, 12),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: DB.borderStrong, borderRadius: BorderRadius.circular(3)))),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: Text('Filters', style: DB.heading(18))),
            TextButton(
              onPressed: () => setState(() => _f = StoreFilters(sort: _f.sort)),
              child: Text('Clear all', style: DB.body(13, color: DB.orange, weight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 4),
          _pills<OfferKind?>('Offer type', const [(null, 'All'), (OfferKind.deal, 'Deals'), (OfferKind.code, 'Codes')], _f.kind,
              (v) => setState(() => _f = v == null ? _f.copyWith(clearKind: true) : _f.copyWith(kind: v))),
          _pills<int>('Discount', const [(0, 'Any'), (30, '30%+'), (50, '50%+'), (70, '70%+')], _f.minSave,
              (v) => setState(() => _f = _f.copyWith(minSave: v))),
          _pills<bool>('Ends', const [(false, 'Any time'), (true, 'Within 7 days')], _f.endingSoon,
              (v) => setState(() => _f = _f.copyWith(endingSoon: v))),
          _pills<OfferSort>(
              'Sort by',
              const [
                (OfferSort.recommended, 'Top offers'),
                (OfferSort.biggestSavings, 'Biggest savings'),
                (OfferSort.newest, 'Newest'),
                (OfferSort.endingSoon, 'Ending soon'),
              ],
              _f.sort,
              (v) => setState(() => _f = _f.copyWith(sort: v))),
          SolidButton('Show offers', bg: widget.accent, fg: widget.accentText, height: 52, onPressed: () => Navigator.of(context).pop(_f)),
        ]),
      ),
    );
  }
}

/// Used by the offer sheet and lists to say how long an offer runs.
String offerEnds(Offer o) => expiryText(o);
