import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../data/repository.dart';
import '../theme/identity.dart';
import '../theme/tokens.dart';
import '../widgets/offer_sheet.dart';
import '../widgets/shop.dart';
import 'store_screen.dart';

/// Category page: photo hero in the category's colour, top deals, then every store in it.
class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key, required this.category});
  final StoreCategory category;

  static Route<void> route(StoreCategory c) => MaterialPageRoute(builder: (_) => CategoryScreen(category: c));

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  late final Future<List<Store>> _stores;
  late final Future<List<Offer>> _offers;
  String _q = '';

  @override
  void initState() {
    super.initState();
    final repo = context.read<Repository>(); // read in initState, never during build
    _stores = repo.categoryStores(widget.category.slug);
    _offers = repo.categoryOffers(widget.category.slug);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.category;
    final site = SiteCategory.guess([c.name]);
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(
              height: 200 + top,
              child: FadedCover(
                gradient: LinearGradient(colors: [shade(site.color, 0.45), site.color]),
                photo: site.photo,
                widthFactor: 0.8,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(14, top + 8, 14, 18),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const BackSquare(onDark: false),
                    const Spacer(),
                    Text('CATEGORY', style: DB.label(9.5, color: Colors.white.withValues(alpha: 0.85))),
                    const SizedBox(height: 4),
                    FractionallySizedBox(
                      widthFactor: 0.65,
                      child: Text(c.name, maxLines: 2, style: DB.headline(24, color: Colors.white)),
                    ),
                    FutureBuilder<List<Store>>(
                      future: _stores,
                      builder: (_, s) => Text(
                        s.hasData ? '${s.data!.length} stores · ${s.data!.fold<int>(0, (a, x) => a + x.offerCount)} offers' : ' ',
                        style: DB.body(12, color: Colors.white.withValues(alpha: 0.9), weight: FontWeight.w600),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ),
          FutureBuilder<List<Offer>>(
            future: _offers,
            builder: (context, s) {
              final offers = (s.data ?? const <Offer>[]).where((o) => !o.expired).take(4).toList();
              if (offers.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
              return SliverMainAxisGroup(slivers: [
                SliverToBoxAdapter(child: SectionTitle('Top ${c.name} deals', top: 16)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: DB.gutter),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, mainAxisExtent: 268),
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => DealCard(
                        offer: offers[i],
                        onOpen: () => showOfferSheet(context, offers[i]),
                        onStore: () => Navigator.of(context).push(StoreScreen.route(offers[i].storeSlug)),
                      ),
                      childCount: offers.length,
                    ),
                  ),
                ),
              ]);
            },
          ),
          SliverToBoxAdapter(
            child: FutureBuilder<List<Store>>(
              future: _stores,
              builder: (_, s) => SectionTitle('Stores', subtitle: s.hasData ? '${s.data!.length} stores' : null),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(DB.gutter, 0, DB.gutter, 10),
              child: SearchBox(hint: 'Search ${c.name} stores', onChanged: (v) => setState(() => _q = v.trim().toLowerCase())),
            ),
          ),
          FutureBuilder<List<Store>>(
            future: _stores,
            builder: (context, s) {
              if (s.connectionState != ConnectionState.done) return const SliverToBoxAdapter(child: Loading());
              final stores = [...(s.data ?? const <Store>[])]
                ..sort((a, b) => b.offerCount.compareTo(a.offerCount))
                ..retainWhere((x) => _q.isEmpty || x.name.toLowerCase().contains(_q));
              if (stores.isEmpty) return const SliverToBoxAdapter(child: EmptyNote('No stores here yet.'));
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: DB.gutter),
                sliver: SliverList.separated(
                  itemCount: stores.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) =>
                      StoreListCard(store: stores[i], onTap: () => Navigator.of(context).push(StoreScreen.route(stores[i].slug))),
                ),
              );
            },
          ),
          SliverToBoxAdapter(child: SizedBox(height: MediaQuery.paddingOf(context).bottom + 24)),
        ],
      ),
    );
  }
}
