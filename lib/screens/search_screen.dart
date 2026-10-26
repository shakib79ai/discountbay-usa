import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../data/repository.dart';
import '../theme/tokens.dart';
import '../widgets/components.dart';
import '../widgets/offer_sheet.dart';
import 'store_screen.dart';
import 'stores_screen.dart' show SearchInput;

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
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: DB.gutter),
          child: SearchInput(controller: _ctrl, onChanged: _run, onSubmitted: _run, autofocus: true),
        ),
      ),
      body: _future == null ? _idle() : _results(),
    );
  }

  Widget _idle() {
    return ListView(
      padding: const EdgeInsets.all(DB.gutter),
      children: [
        Text('POPULAR SEARCHES', style: DB.mono(11, color: DB.paper.withValues(alpha: 0.55))),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in _suggestions)
              ActionChip(
                label: Text(s),
                labelStyle: DB.body(13, color: DB.paper, weight: FontWeight.w600),
                backgroundColor: DB.inkSoft,
                side: const BorderSide(color: DB.lineOnInk),
                shape: const StadiumBorder(),
                onPressed: () {
                  _ctrl.text = s;
                  _run(s);
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _results() {
    return AsyncView<({List<Store> stores, List<Offer> offers})>(
      future: _future!,
      onRetry: () => _run(_ctrl.text),
      isEmpty: (r) => r.stores.isEmpty && r.offers.isEmpty,
      emptyText: 'No stores or deals match “${_ctrl.text.trim()}”.',
      builder: (context, r) => ListView(
        padding: EdgeInsets.only(top: 8, bottom: MediaQuery.paddingOf(context).bottom + 24),
        children: [
          if (r.stores.isNotEmpty) ...[
            _label('Stores'),
            for (final s in r.stores)
              StoreRow(store: s, onTap: () => Navigator.of(context).push(StoreScreen.route(s.slug))),
          ],
          if (r.offers.isNotEmpty) ...[
            _label('Offers'),
            for (final o in r.offers)
              Padding(
                padding: const EdgeInsets.fromLTRB(DB.gutter, 0, DB.gutter, 12),
                child: OfferTicket(offer: o, onOpen: () => showOfferSheet(context, o)),
              ),
          ],
        ],
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(DB.gutter, 16, DB.gutter, 8),
        child: Text(t.toUpperCase(), style: DB.mono(11, color: DB.mustard)),
      );
}
