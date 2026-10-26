import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../data/repository.dart';
import '../theme/tokens.dart';
import '../widgets/components.dart';
import '../widgets/decor.dart';
import '../widgets/offer_sheet.dart';
import 'store_screen.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key, required this.category});
  final StoreCategory category;

  static Route<void> route(StoreCategory c) => MaterialPageRoute(builder: (_) => CategoryScreen(category: c));

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  late final Repository _repo;
  late Future<List<Store>> _stores;
  late Future<List<Offer>> _offers;

  @override
  void initState() {
    super.initState();
    _repo = context.read<Repository>();
    _stores = _repo.categoryStores(widget.category.slug);
    _offers = _repo.categoryOffers(widget.category.slug);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.category;
    return Scaffold(
      appBar: AppBar(
        title: Text(c.name),
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: DashedLine(color: DB.lineOnInk)),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(DB.gutter, 22, DB.gutter, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Eyebrow('StoreCategory'),
                  const SizedBox(height: 6),
                  Text('${c.name} coupons'.toUpperCase(), style: DB.display(32)),
                  const SizedBox(height: 8),
                  Text('Verified codes and deals from top ${c.name.toLowerCase()} stores, checked daily.',
                      style: DB.body(14, color: DB.paper.withValues(alpha: 0.7))),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SectionHeader(title: 'Stores', onInk: true)),
          SliverToBoxAdapter(
            child: AsyncView<List<Store>>(
              future: _stores,
              onRetry: () => setState(() => _stores = _repo.categoryStores(c.slug)),
              isEmpty: (l) => l.isEmpty,
              emptyText: 'No stores in this category yet.',
              builder: (context, stores) => GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: DB.gutter),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.82,
                ),
                itemCount: stores.length,
                itemBuilder: (context, i) => StoreTile(
                  store: stores[i],
                  onTap: () => Navigator.of(context).push(StoreScreen.route(stores[i].slug)),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SectionHeader(title: 'Top offers', onInk: true)),
          AsyncView<List<Offer>>(
            future: _offers,
            sliver: true,
            onRetry: () => setState(() => _offers = _repo.categoryOffers(c.slug)),
            isEmpty: (l) => l.isEmpty,
            emptyText: 'Open a store above to see its offers.',
            builder: (context, offers) => SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: DB.gutter),
              sliver: SliverList.separated(
                itemCount: offers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) =>
                    OfferTicket(offer: offers[i], onOpen: () => showOfferSheet(context, offers[i])),
              ),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: MediaQuery.paddingOf(context).bottom + 28)),
        ],
      ),
    );
  }
}
