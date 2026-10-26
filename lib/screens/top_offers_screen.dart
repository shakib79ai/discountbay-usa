import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../data/repository.dart';
import '../theme/tokens.dart';
import '../widgets/components.dart';
import '../widgets/decor.dart';
import '../widgets/offer_sheet.dart';
import 'home_screen.dart' show filterLabel;

/// "Top offers" — every verified offer with All / Codes / Deals / Ending soon and infinite scroll.
class TopOffersScreen extends StatefulWidget {
  const TopOffersScreen({super.key, this.initialFilter = OfferFilter.all});
  final OfferFilter initialFilter;

  static Route<void> route([OfferFilter f = OfferFilter.all]) =>
      MaterialPageRoute(builder: (_) => TopOffersScreen(initialFilter: f));

  @override
  State<TopOffersScreen> createState() => _TopOffersScreenState();
}

class _TopOffersScreenState extends State<TopOffersScreen> {
  late final Repository _repo;
  final _scroll = ScrollController();
  late OfferFilter _filter;
  final List<Offer> _items = [];
  int _page = 1;
  bool _loading = false;
  bool _hasMore = true;
  Object? _error;
  int _gen = 0;

  @override
  void initState() {
    super.initState();
    _repo = context.read<Repository>();
    _filter = widget.initialFilter;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TOP OFFERS', style: DB.display(24)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Column(
            children: [
              ChipBar<OfferFilter>(
                values: OfferFilter.values,
                selected: _filter,
                onInk: true,
                label: filterLabel,
                onSelected: _setFilter,
              ),
              const SizedBox(height: 10),
              const DashedLine(color: DB.lineOnInk),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        color: DB.ink,
        backgroundColor: DB.mustard,
        onRefresh: () async => _setFilter(_filter),
        child: _items.isEmpty && _error != null
            ? ListView(children: [
                MessageState(
                  icon: Icons.wifi_off_rounded,
                  text: "Couldn't load offers.",
                  actionLabel: 'Try again',
                  onAction: () => _setFilter(_filter),
                ),
              ])
            : _items.isEmpty && !_loading && !_hasMore
                ? ListView(children: const [
                    MessageState(icon: Icons.local_offer_outlined, text: 'No offers in this filter right now.'),
                  ])
                : ListView.separated(
                    controller: _scroll,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(DB.gutter, 16, DB.gutter, MediaQuery.paddingOf(context).bottom + 24),
                    itemCount: _items.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      if (i == _items.length) {
                        return _loading
                            ? const Padding(
                                padding: EdgeInsets.all(24),
                                child: Center(child: CircularProgressIndicator(color: DB.mustard, strokeWidth: 2.5)),
                              )
                            : const SizedBox.shrink();
                      }
                      final o = _items[i];
                      return OfferTicket(offer: o, onOpen: () => showOfferSheet(context, o));
                    },
                  ),
      ),
    );
  }
}
