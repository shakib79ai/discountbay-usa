import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/content.dart';
import '../data/models.dart';
import '../data/repository.dart';
import '../theme/tokens.dart';
import '../widgets/brand_logo.dart';
import '../widgets/components.dart';
import '../widgets/decor.dart';
import '../widgets/newsletter.dart';
import '../widgets/offer_sheet.dart';
import 'account_screen.dart';
import 'category_screen.dart';
import 'search_screen.dart';
import 'shell.dart';
import 'store_screen.dart';
import 'top_offers_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Repository _repo;
  late Future<List<Store>> _stores;
  late Future<Paged<Offer>> _offers;
  late Future<List<StoreCategory>> _categories;
  late Future<List<Offer>> _hot;
  OfferFilter _filter = OfferFilter.all;

  @override
  void initState() {
    super.initState();
    _repo = context.read<Repository>();
    _load();
  }

  void _load() {
    _stores = _repo.popularStores();
    _offers = _repo.topOffers(filter: _filter);
    _categories = _repo.categories();
    _hot = _repo.hotProductDeals();
  }

  Future<void> _refresh() async {
    setState(_load);
    await Future.wait([_stores, _offers, _categories, _hot]).catchError((_) => <Object>[]);
  }

  void _setFilter(OfferFilter f) => setState(() {
        _filter = f;
        _offers = _repo.topOffers(filter: f);
      });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: DB.ink,
      backgroundColor: DB.mustard,
      onRefresh: _refresh,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: DB.ink.withValues(alpha: 0.96),
            title: const BrandLogo.horizontal(height: 30, onDark: true),
            actions: [
              IconButton(
                tooltip: 'Search',
                icon: const Icon(Icons.search),
                onPressed: () => Navigator.of(context).push(SearchScreen.route()),
              ),
              IconButton(
                tooltip: 'Account',
                icon: const Icon(Icons.person_outline),
                onPressed: () => Navigator.of(context).push(AccountScreen.route()),
              ),
              const SizedBox(width: 4),
            ],
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: DashedLine(color: DB.lineOnInk),
            ),
          ),
          const SliverToBoxAdapter(child: _Hero()),

          // ---------- Popular stores (paper band)
          SliverToBoxAdapter(
            child: PaperBand(
              child: Column(
                children: [
                  SectionHeader(
                    title: 'Popular Stores',
                    eyebrow: 'Shop by brand',
                    actionLabel: 'All stores',
                    onAction: () => Shell.switchTab(context, 1),
                  ),
                  AsyncView<List<Store>>(
                    future: _stores,
                    onInk: false,
                    onRetry: () => setState(() => _stores = _repo.popularStores()),
                    builder: (context, stores) => GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(DB.gutter, 0, DB.gutter, 24),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 0.82,
                      ),
                      itemCount: stores.length,
                      itemBuilder: (_, i) => _StoreCardOnPaper(store: stores[i]),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ---------- Today's top verified deals (ink)
          const SliverToBoxAdapter(
            child: SectionHeader(title: "Today's Top Verified Deals", eyebrow: 'Checked today', onInk: true),
          ),
          SliverToBoxAdapter(
            child: ChipBar<OfferFilter>(
              values: OfferFilter.values,
              selected: _filter,
              onInk: true,
              label: filterLabel,
              onSelected: _setFilter,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 14)),
          AsyncView<Paged<Offer>>(
            future: _offers,
            sliver: true,
            onRetry: () => _setFilter(_filter),
            isEmpty: (p) => p.items.isEmpty,
            emptyText: 'No offers in this filter right now.',
            builder: (context, page) => SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: DB.gutter),
              sliver: SliverList.separated(
                itemCount: page.items.take(6).length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final o = page.items[i];
                  return OfferTicket(offer: o, onOpen: () => showOfferSheet(context, o));
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(DB.gutter, 18, DB.gutter, 30),
              child: PillButton('See all offers',
                  style: PillStyle.outlinePaper,
                  expand: true,
                  onPressed: () => Navigator.of(context).push(TopOffersScreen.route(_filter))),
            ),
          ),

          // ---------- Trending categories (paper)
          SliverToBoxAdapter(
            child: PaperBand(
              color: DB.paperDim,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: 'Trending Categories',
                    eyebrow: 'Browse',
                    actionLabel: 'All categories',
                    onAction: () => Shell.switchTab(context, 2),
                  ),
                  AsyncView<List<StoreCategory>>(
                    future: _categories,
                    onInk: false,
                    onRetry: () => setState(() => _categories = _repo.categories()),
                    builder: (context, cats) => Padding(
                      padding: const EdgeInsets.fromLTRB(DB.gutter, 0, DB.gutter, 26),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final c in cats.take(8))
                            ActionChip(
                              label: Text(c.name),
                              labelStyle: DB.body(13, weight: FontWeight.w600),
                              backgroundColor: DB.paper,
                              side: const BorderSide(color: DB.line),
                              shape: const StadiumBorder(),
                              onPressed: () => Navigator.of(context).push(CategoryScreen.route(c)),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ---------- Hot product deals (ink, horizontal)
          const SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Hot Product Deals',
              eyebrow: 'Top promotions from verified partners',
              onInk: true,
            ),
          ),
          SliverToBoxAdapter(
            child: AsyncView<List<Offer>>(
              future: _hot,
              onRetry: () => setState(() => _hot = _repo.hotProductDeals()),
              isEmpty: (l) => l.isEmpty,
              builder: (context, hot) => SizedBox(
                height: 318,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: DB.gutter),
                  itemCount: hot.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, i) =>
                      HotDealCard(offer: hot[i], onOpen: () => showOfferSheet(context, hot[i])),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),

          // ---------- How it works (paper)
          const SliverToBoxAdapter(child: PaperBand(child: _HowItWorks())),

          // ---------- FAQ (ink)
          const SliverToBoxAdapter(child: FaqSection()),

          // ---------- Newsletter + footer
          const SliverToBoxAdapter(child: NewsletterBand()),
          const SliverToBoxAdapter(child: _FooterNote()),
        ],
      ),
    );
  }
}

String filterLabel(OfferFilter f) => switch (f) {
      OfferFilter.all => 'All',
      OfferFilter.codes => 'Codes',
      OfferFilter.deals => 'Deals',
      OfferFilter.endingSoon => 'Ending soon',
    };

// ------------------------------------------------------------------ hero

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(DB.gutter, 28, DB.gutter, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              border: Border.all(color: DB.mustard.withValues(alpha: 0.6)),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 7, height: 7, decoration: const BoxDecoration(color: DB.mint, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text('2,000+ CODES CHECKED TODAY', style: DB.mono(10.5, color: DB.mustard)),
            ]),
          ),
          const SizedBox(height: 16),
          Text.rich(
            TextSpan(children: [
              const TextSpan(text: 'STOP PAYING\nFULL PRICE'),
              TextSpan(text: '!', style: DB.display(54, color: DB.coral)),
            ]),
            style: DB.display(54),
          ),
          const SizedBox(height: 14),
          Text(
            'We track & re-verify coupon codes across 10,000+ stores daily, so the code you tap actually works at checkout.',
            style: DB.body(15, color: DB.paper.withValues(alpha: 0.78)),
          ),
          const SizedBox(height: 22),
          // Search "ticket"
          GestureDetector(
            onTap: () => Navigator.of(context).push(SearchScreen.route()),
            child: ClipPath(
              clipper: TicketClipper(notchRadius: 8),
              child: Container(
                color: DB.paper,
                padding: const EdgeInsets.fromLTRB(18, 6, 6, 6),
                child: Row(
                  children: [
                    Icon(Icons.search, color: DB.ink.withValues(alpha: 0.5)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Search a store, e.g. Amazon…',
                          style: DB.body(14, color: DB.ink.withValues(alpha: 0.5))),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(color: DB.mustard, borderRadius: BorderRadius.circular(DB.radius)),
                      child: Text('Find Codes', style: DB.body(13, weight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Trending:', style: DB.mono(11, color: DB.paper.withValues(alpha: 0.6))),
              for (final (slug, name) in const [
                ('amazon', 'Amazon'),
                ('ebay', 'eBay'),
                ('aliexpress-global', 'AliExpress'),
                ('macy-s', "Macy's"),
              ])
                GestureDetector(
                  onTap: () => Navigator.of(context).push(StoreScreen.route(slug)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: DB.lineOnInk),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(name, style: DB.body(12.5, color: DB.paper, weight: FontWeight.w600)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 26),
          const _StatTape(),
        ],
      ),
    );
  }
}

class _StatTape extends StatelessWidget {
  const _StatTape();

  @override
  Widget build(BuildContext context) {
    const stats = [('5+', 'Years verifying deals'), ('10K+', 'Stores tracked daily'), ('2,000+', 'Active codes now')];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border.symmetric(horizontal: BorderSide(color: DB.lineOnInk)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            if (i > 0) Container(width: 1, height: 40, color: DB.lineOnInk),
            Expanded(
              child: Column(
                children: [
                  Text(stats[i].$1, style: DB.display(26, color: i == 1 ? DB.mustard : DB.paper)),
                  const SizedBox(height: 4),
                  Text(stats[i].$2,
                      textAlign: TextAlign.center, style: DB.body(11, color: DB.paper.withValues(alpha: 0.6))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StoreCardOnPaper extends StatelessWidget {
  const _StoreCardOnPaper({required this.store});
  final Store store;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DB.radius),
        border: Border.all(color: DB.line),
      ),
      child: StoreTile(store: store, onTap: () => Navigator.of(context).push(StoreScreen.route(store.slug))),
    );
  }
}

// ------------------------------------------------------------------ how it works

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'How it works', eyebrow: '3 steps to save'),
          for (var i = 0; i < Content.steps.length; i++)
            Padding(
              padding: const EdgeInsets.fromLTRB(DB.gutter, 0, DB.gutter, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: [DB.coral, DB.mustard, DB.mint][i],
                      borderRadius: BorderRadius.circular(DB.radius),
                    ),
                    child: Text('${i + 1}', style: DB.display(22, color: DB.ink)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(Content.steps[i].$1, style: DB.heading(16)),
                        const SizedBox(height: 2),
                        Text(Content.steps[i].$2, style: DB.body(13.5, color: DB.ink.withValues(alpha: 0.7))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ FAQ

class FaqSection extends StatefulWidget {
  const FaqSection({super.key});

  @override
  State<FaqSection> createState() => _FaqSectionState();
}

class _FaqSectionState extends State<FaqSection> {
  int _open = 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Frequently asked', eyebrow: 'Questions', onInk: true),
          for (var i = 0; i < Content.faqs.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: DB.gutter),
              child: DecoratedBox(
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: DB.lineOnInk))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () => setState(() => _open = _open == i ? -1 : i),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          children: [
                            Text('Q${(i + 1).toString().padLeft(2, '0')}', style: DB.mono(11, color: DB.coral)),
                            const SizedBox(width: 12),
                            Expanded(child: Text(Content.faqs[i].$1, style: DB.heading(15, color: DB.paper))),
                            AnimatedRotation(
                              turns: _open == i ? 0.125 : 0,
                              duration: const Duration(milliseconds: 200),
                              child: const Icon(Icons.add, color: DB.mustard),
                            ),
                          ],
                        ),
                      ),
                    ),
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 200),
                      crossFadeState: _open == i ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                      firstChild: const SizedBox(width: double.infinity),
                      secondChild: Padding(
                        padding: const EdgeInsets.fromLTRB(36, 0, 8, 16),
                        child: Text(Content.faqs[i].$2, style: DB.body(14, color: DB.paper.withValues(alpha: 0.75))),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FooterNote extends StatelessWidget {
  const _FooterNote();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(DB.gutter, 24, DB.gutter, 32),
      child: Column(
        children: [
          const BrandLogo.full(height: 120, onDark: true),
          const SizedBox(height: 10),
          Text(
            'We may earn a commission when you shop through our links — at no extra cost to you.',
            textAlign: TextAlign.center,
            style: DB.body(12, color: DB.paper.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 6),
          Text('© ${DateTime.now().year} DiscountBay', style: DB.mono(10, color: DB.paper.withValues(alpha: 0.4))),
        ],
      ),
    );
  }
}
