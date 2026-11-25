import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../data/repository.dart';
import '../theme/identity.dart';
import '../theme/tokens.dart';
import '../widgets/components.dart' show MessageState;
import '../widgets/offer_sheet.dart';
import '../widgets/shop.dart';
import 'store_screen.dart';

String filterLabel(OfferFilter f) => switch (f) {
      OfferFilter.all => 'All',
      OfferFilter.codes => 'Codes',
      OfferFilter.deals => 'Deals',
      OfferFilter.endingSoon => 'Ending soon',
    };

/// Top deals: search, type chips, a sort toggle and product cards in two columns (infinite scroll).
class TopOffersScreen extends StatefulWidget {
  const TopOffersScreen({super.key, this.initialFilter = OfferFilter.all});
  final OfferFilter initialFilter;

  static Route<void> route([OfferFilter f = OfferFilter.all]) =>
      MaterialPageRoute(builder: (_) => TopOffersScreen(initialFilter: f));

  @override
  State<TopOffersScreen> createState() => _TopOffersScreenState();
}

enum _Sort { top, savings }

class _TopOffersScreenState extends State<TopOffersScreen> {
  late final Repository _repo;
  final _scroll = ScrollController();
  late OfferFilter _filter = widget.initialFilter;
  _Sort _sort = _Sort.top;
  String _q = '';
  final List<Offer> _items = [];
  int _page = 1;
  bool _loading = false;
  bool _hasMore = true;
  Object? _error;
  int _gen = 0;

  @override
  void initState() {
    super.initState();
    _repo = context.read<Repository>(); // read in initState, never during build
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 500) _load();
    });
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _setFilter(OfferFilter f) {
    _gen++;
    setState(() {
      _filter = f;
      _items.clear();
      _page = 1;
      _hasMore = true;
      _loading = false;
      _error = null;
    });
    _load();
  }

  Future<void> _load() async {
    if (_loading || !_hasMore) return;
    final gen = _gen;
    setState(() => _loading = true);
    try {
      final res = await _repo.topOffers(filter: _filter, page: _page);
      if (!mounted || gen != _gen) return;
      setState(() {
        _items.addAll(res.items);
        _hasMore = res.hasMore;
        _page++;
      });
    } catch (e) {
      if (mounted && gen == _gen) setState(() => _error = e);
    } finally {
      if (mounted && gen == _gen) setState(() => _loading = false);
    }
  }

  List<Offer> get _visible {
    final q = _q.toLowerCase();
    final list = _items.where((o) => q.isEmpty || '${o.title} ${o.storeName}'.toLowerCase().contains(q)).toList();
    if (_sort == _Sort.savings) list.sort((a, b) => savePercent(b).compareTo(savePercent(a)));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final items = _visible;
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => _setFilter(_filter),
        child: CustomScrollView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: DarkHeader(
                title: 'Top deals',
                leading: const BackSquare(),
                child: SearchBox(hint: 'Search deals', onChanged: (v) => setState(() => _q = v.trim())),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: PillRow<OfferFilter>(values: OfferFilter.values, selected: _filter, label: filterLabel, onSelected: _setFilter),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(DB.gutter, 8, 6, 4),
                child: Row(children: [
                  Expanded(child: Text('${items.length} deals', style: DB.body(13, weight: FontWeight.w700))),
                  TextButton(
                    onPressed: () => setState(() => _sort = _sort == _Sort.top ? _Sort.savings : _Sort.top),
                    child: Text('Sort: ${_sort == _Sort.top ? 'Top picks' : 'Biggest savings'}',
                        style: DB.body(12.5, color: DB.orange, weight: FontWeight.w700)),
                  ),
                ]),
              ),
            ),
            if (_items.isEmpty && _error != null)
              SliverToBoxAdapter(
                child: MessageState(
                    icon: Icons.wifi_off_rounded, text: "Couldn't load offers.", actionLabel: 'Try again', onAction: () => _setFilter(_filter)),
              )
            else if (items.isEmpty && !_loading)
              const SliverToBoxAdapter(child: EmptyNote('No deals match right now.'))
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: DB.gutter),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, mainAxisExtent: 268),
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => DealCard(
                      offer: items[i],
                      onOpen: () => showOfferSheet(context, items[i]),
                      onStore: () => Navigator.of(context).push(StoreScreen.route(items[i].storeSlug)),
                    ),
                    childCount: items.length,
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: _loading ? const Loading() : SizedBox(height: MediaQuery.paddingOf(context).bottom + 24),
            ),
          ],
        ),
      ),
    );
  }
}
