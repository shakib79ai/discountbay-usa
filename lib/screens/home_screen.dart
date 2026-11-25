import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/content.dart';
import '../data/models.dart';
import '../data/repository.dart';
import '../theme/identity.dart';
import '../theme/tokens.dart';
import '../widgets/brand_logo.dart';
import '../widgets/offer_sheet.dart';
import '../widgets/shop.dart';
import 'account_screen.dart';
import 'category_screen.dart';
import 'search_screen.dart';
import 'shell.dart';
import 'store_screen.dart';
import 'top_offers_screen.dart';

/// Home: search, hero slider, category photos, featured stores, top deals, product deals, FAQ, alerts.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  OfferFilter _filter = OfferFilter.all;
  late Future<List<Store>> _stores;
  late Future<Paged<Offer>> _offers;
  late Future<List<StoreCategory>> _categories;
  late Future<List<Offer>> _hot;
  late Future<Paged<Offer>> _heroOffers;

  Repository get _repo => context.read<Repository>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _stores = _repo.popularStores();
    _offers = _repo.topOffers(filter: _filter);
    _categories = _repo.categories();
    _hot = _repo.hotProductDeals();
    _heroOffers = _repo.topOffers();
  }

  Future<void> _refresh() async {
    setState(_load);
    await Future.wait<Object>([_stores, _offers, _categories, _hot]).catchError((_) => <Object>[]);
  }

  void _openStore(String slug) => Navigator.of(context).push(StoreScreen.route(slug));

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _Header(onSearch: () => Navigator.of(context).push(SearchScreen.route()))),

          // Hero slider: the biggest current offers, each in its store's colours.
          SliverToBoxAdapter(
            child: FutureBuilder<Paged<Offer>>(
              future: _heroOffers,
              builder: (_, s) {
                final items = [...(s.data?.items ?? const <Offer>[])]..sort((a, b) => savePercent(b).compareTo(savePercent(a)));
                final seen = <String>{};
                final slides = items.where((o) => seen.add(o.storeSlug)).take(3).toList();
                if (slides.isEmpty) return const SizedBox(height: 8);
                return _HeroSlider(offers: slides, onOpen: (o) => _openStore(o.storeSlug));
              },
            ),
          ),

          SliverToBoxAdapter(
            child: SectionTitle('Shop by category', action: 'See all', onAction: () => Shell.switchTab(context, 2)),
          ),
          SliverToBoxAdapter(
            child: FutureBuilder<List<StoreCategory>>(
              future: _categories,
              builder: (_, s) {
                final cats = s.data ?? const <StoreCategory>[];
                if (cats.isEmpty) return const SizedBox(height: 96, child: Loading());
                return SizedBox(
                  height: 104,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: cats.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 4),
                    itemBuilder: (_, i) => CategoryCircle(
                      label: cats[i].name,
                      photo: SiteCategory.guess([cats[i].name]).photo,
                      url: cats[i].imageUrl,
                      onTap: () => Navigator.of(context).push(CategoryScreen.route(cats[i])),
                    ),
                  ),
                );
              },
            ),
          ),

          SliverToBoxAdapter(
            child: SectionTitle('Featured stores', action: 'All stores', onAction: () => Shell.switchTab(context, 1)),
          ),
          SliverToBoxAdapter(
            child: FutureBuilder<List<Store>>(
              future: _stores,
              builder: (_, s) {
                final stores = s.data ?? const <Store>[];
                if (stores.isEmpty) return const SizedBox(height: 140, child: Loading());
                return SizedBox(
                  height: 132,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: DB.gutter),
                    itemCount: stores.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) => StoreFeatureCard(store: stores[i], onTap: () => _openStore(stores[i].slug)),
                  ),
                );
              },
            ),
          ),

          SliverToBoxAdapter(
            child: SectionTitle('Today’s top deals',
                action: 'See all', onAction: () => Navigator.of(context).push(TopOffersScreen.route(_filter))),
          ),
          SliverToBoxAdapter(
            child: PillRow<OfferFilter>(
              values: OfferFilter.values,
              selected: _filter,
              label: (f) => switch (f) {
                OfferFilter.all => 'All',
                OfferFilter.codes => 'Codes',
                OfferFilter.deals => 'Deals',
                OfferFilter.endingSoon => 'Ending soon',
              },
              onSelected: (f) => setState(() {
                _filter = f;
                _offers = _repo.topOffers(filter: f);
              }),
            ),
          ),
          FutureBuilder<Paged<Offer>>(
            future: _offers,
            builder: (_, s) {
              if (s.connectionState != ConnectionState.done) return const SliverToBoxAdapter(child: Loading());
              final offers = (s.data?.items ?? const <Offer>[]).take(6).toList();
              if (offers.isEmpty) return const SliverToBoxAdapter(child: EmptyNote('No deals here right now.'));
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(DB.gutter, 12, DB.gutter, 0),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    mainAxisExtent: 268,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => DealCard(
                      offer: offers[i],
                      onOpen: () => showOfferSheet(context, offers[i]),
                      onStore: () => _openStore(offers[i].storeSlug),
                    ),
                    childCount: offers.length,
                  ),
                ),
              );
            },
          ),

          SliverToBoxAdapter(
            child: FutureBuilder<List<Offer>>(
              future: _hot,
              builder: (_, s) {
                final hot = s.data ?? const <Offer>[];
                if (hot.isEmpty) return const SizedBox.shrink();
                return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const SectionTitle('Hot product deals', subtitle: 'Picked from our store partners'),
                  SizedBox(
                    height: 210,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: DB.gutter),
                      itemCount: hot.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (_, i) => _ProductDeal(offer: hot[i], onOpen: () => showOfferSheet(context, hot[i])),
                    ),
                  ),
                ]);
              },
            ),
          ),

          const SliverToBoxAdapter(child: SectionTitle('Questions? We’ve got answers')),
          const SliverToBoxAdapter(child: FaqSection()),
          const SliverToBoxAdapter(child: _AlertsBanner()),
          SliverToBoxAdapter(child: SizedBox(height: MediaQuery.paddingOf(context).bottom + 24)),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onSearch});
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DB.ink,
      padding: EdgeInsets.fromLTRB(DB.gutter, MediaQuery.paddingOf(context).top + 10, 8, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const BrandLogo.horizontal(height: 30, onDark: true),
          const Spacer(),
          IconButton(
            tooltip: 'Account',
            onPressed: () => Navigator.of(context).push(AccountScreen.route()),
            icon: const Icon(Icons.account_circle_outlined, color: Colors.white, size: 28),
          ),
        ]),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: SearchBox(hint: 'Search stores, brands, products', readOnly: true, onTap: onSearch),
        ),
      ]),
    );
  }
}

class _HeroSlider extends StatefulWidget {
  const _HeroSlider({required this.offers, required this.onOpen});
  final List<Offer> offers;
  final ValueChanged<Offer> onOpen;

  @override
  State<_HeroSlider> createState() => _HeroSliderState();
}

class _HeroSliderState extends State<_HeroSlider> {
  final _page = PageController();
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_page.hasClients || widget.offers.length < 2) return;
      _page.animateToPage((_index + 1) % widget.offers.length,
          duration: const Duration(milliseconds: 450), curve: Curves.easeOut);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SizedBox(
        height: 186,
        child: PageView.builder(
          controller: _page,
          itemCount: widget.offers.length,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (_, i) {
            final o = widget.offers[i];
            final look = StoreLook.forOffer(o);
            return Padding(
              padding: const EdgeInsets.fromLTRB(DB.gutter, 14, DB.gutter, 0),
              child: Material(
                borderRadius: BorderRadius.circular(20),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => widget.onOpen(o),
                  child: FadedCover(
                    gradient: look.gradient,
                    photo: offerPhoto(o),
                    url: o.imageUrl,
                    widthFactor: 0.72,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: FractionallySizedBox(
                        widthFactor: 0.62,
                        alignment: Alignment.centerLeft,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(5)),
                            child: Text(o.storeName.toUpperCase(), maxLines: 1, style: DB.label(9, color: DB.ink)),
                          ),
                          const SizedBox(height: 8),
                          Text(offerValue(o) == 'Deal' ? 'Top deal' : 'Save ${offerValue(o)}',
                              maxLines: 1, overflow: TextOverflow.ellipsis, style: DB.headline(22, color: Colors.white)),
                          const SizedBox(height: 4),
                          Text(o.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: DB.body(11.5, color: Colors.white.withValues(alpha: 0.88), weight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                            child: Text('Shop now →', style: DB.body(11.5, weight: FontWeight.w800)),
                          ),
                        ]),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (var i = 0; i < widget.offers.length; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == _index ? 22 : 7,
            height: 7,
            decoration: BoxDecoration(color: i == _index ? DB.ink : const Color(0xFFC5D1DF), borderRadius: BorderRadius.circular(4)),
          ),
      ]),
    ]);
  }
}

class _ProductDeal extends StatelessWidget {
  const _ProductDeal({required this.offer, required this.onOpen});
  final Offer offer;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Material(
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: Stack(fit: StackFit.expand, children: [
            Photo(url: offer.imageUrl, fallback: offerPhoto(offer)),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xCC12203A), Color(0x0012203A)],
                  stops: [0, 0.7],
                ),
              ),
            ),
            Positioned(left: 10, top: 10, child: SaleBadge(offerBadge(offer))),
            Positioned(
              left: 14,
              right: 14,
              bottom: 12,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(offer.storeName, style: DB.body(11, color: Colors.white.withValues(alpha: 0.85), weight: FontWeight.w700)),
                Text(offer.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: DB.heading(15, color: Colors.white)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Frequently asked questions — also shown on the Account screen.
class FaqSection extends StatefulWidget {
  const FaqSection({super.key, this.onInk = false});

  /// Kept for older callers; the new design always draws on white.
  final bool onInk;

  @override
  State<FaqSection> createState() => _FaqSectionState();
}

class _FaqSectionState extends State<FaqSection> {
  int _open = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: DB.gutter),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: DB.border)),
      child: Column(children: [
        for (var i = 0; i < Content.faqs.length; i++)
          InkWell(
            onTap: () => setState(() => _open = _open == i ? -1 : i),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                border: i < Content.faqs.length - 1 ? const Border(bottom: BorderSide(color: Color(0xFFEEF2F6))) : null,
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(Content.faqs[i].$1, style: DB.body(13.5, weight: FontWeight.w700))),
                  Text(_open == i ? '−' : '+', style: DB.heading(18, color: DB.muted)),
                ]),
                if (_open == i) ...[
                  const SizedBox(height: 6),
                  Text(Content.faqs[i].$2, style: DB.body(12.5, color: DB.body2)),
                ],
              ]),
            ),
          ),
      ]),
    );
  }
}

class _AlertsBanner extends StatefulWidget {
  const _AlertsBanner();
  @override
  State<_AlertsBanner> createState() => _AlertsBannerState();
}

class _AlertsBannerState extends State<_AlertsBanner> {
  final _email = TextEditingController();
  bool _busy = false;
  bool _done = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final e = _email.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid email address')));
      return;
    }
    setState(() => _busy = true);
    try {
      await context.read<Repository>().subscribeNewsletter(e);
      if (mounted) setState(() => _done = true);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Couldn’t subscribe — try again')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(DB.gutter, 20, DB.gutter, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(colors: [Color(0xFFFFF1E6), Color(0xFFFFE0C7)]),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Never miss a deal', style: DB.headline(20)),
        const SizedBox(height: 4),
        Text('Get an email when new deals from top stores are verified.', style: DB.body(13, color: DB.body2)),
        const SizedBox(height: 12),
        if (_done)
          Text('You’re subscribed — check your inbox.', style: DB.body(14, color: DB.verified, weight: FontWeight.w700))
        else
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  style: DB.body(14),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    hintText: 'you@email.com',
                    hintStyle: DB.body(14, color: DB.muted),
                  ),
                ),
              ),
              SolidButton(_busy ? 'Sending…' : 'Get alerts', onPressed: _busy ? null : _submit, bg: DB.orange, height: 42),
            ]),
          ),
      ]),
    );
  }
}
