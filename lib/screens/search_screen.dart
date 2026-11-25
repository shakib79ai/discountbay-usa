import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../data/repository.dart';
import '../theme/tokens.dart';
import '../widgets/offer_sheet.dart';
import '../widgets/shop.dart';
import 'store_screen.dart';

/// Search stores and deals as you type.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  static Route<void> route() => MaterialPageRoute(builder: (_) => const SearchScreen());

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final Repository _repo;
  final _ctrl = TextEditingController();
  Timer? _debounce;
  Future<({List<Store> stores, List<Offer> offers})>? _future;

  static const _suggestions = ['Amazon', 'Macy\'s', 'GoDaddy', 'HP', 'Temu', 'Booking.com'];

  @override
  void initState() {
    super.initState();
    _repo = context.read<Repository>();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _run(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _future = q.trim().length < 2 ? null : _repo.search(q.trim()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        DarkHeader(
          title: 'Search',
          leading: const BackSquare(),
          child: SearchBox(controller: _ctrl, onChanged: _run, hint: 'Stores, brands or products', autofocus: true),
        ),
        Expanded(child: _future == null ? _idle() : _results()),
      ]),
    );
  }

  Widget _idle() {
    return ListView(padding: const EdgeInsets.all(DB.gutter), children: [
      Text('POPULAR SEARCHES', style: DB.label(10.5)),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final s in _suggestions)
          ActionChip(
            label: Text(s),
            labelStyle: DB.body(13, weight: FontWeight.w700),
            backgroundColor: Colors.white,
            side: const BorderSide(color: DB.border, width: 1.4),
            shape: const StadiumBorder(),
            onPressed: () {
              _ctrl.text = s;
              _run(s);
            },
          ),
      ]),
    ]);
  }

  Widget _results() {
    return FutureBuilder<({List<Store> stores, List<Offer> offers})>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return const Loading();
        if (snap.hasError) return EmptyNote("Couldn't search right now.", action: 'Try again', onAction: () => _run(_ctrl.text));
        final r = snap.data!;
        if (r.stores.isEmpty && r.offers.isEmpty) return EmptyNote('No stores or deals match “${_ctrl.text.trim()}”.');
        return ListView(
          padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + 24),
          children: [
            if (r.stores.isNotEmpty) ...[
              SectionTitle('Stores', subtitle: '${r.stores.length} found', top: 14),
              for (final s in r.stores)
                Padding(
                  padding: const EdgeInsets.fromLTRB(DB.gutter, 0, DB.gutter, 10),
                  child: StoreListCard(store: s, onTap: () => Navigator.of(context).push(StoreScreen.route(s.slug))),
                ),
            ],
            if (r.offers.isNotEmpty) ...[
              SectionTitle('Deals', subtitle: '${r.offers.length} found', top: 10),
              for (final o in r.offers)
                Padding(
                  padding: const EdgeInsets.fromLTRB(DB.gutter, 0, DB.gutter, 10),
                  child: DealRow(offer: o, onOpen: () => showOfferSheet(context, o)),
                ),
            ],
          ],
        );
      },
    );
  }
}
