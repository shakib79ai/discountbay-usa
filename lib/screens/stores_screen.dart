import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../data/repository.dart';
import '../theme/tokens.dart';
import '../widgets/components.dart' show MessageState;
import '../widgets/shop.dart';
import 'store_screen.dart';

/// Stores tab: search, A–Z letters, featured stores, then every store as a store card (infinite list).
class StoresScreen extends StatefulWidget {
  const StoresScreen({super.key});

  @override
  State<StoresScreen> createState() => _StoresScreenState();
}

class _StoresScreenState extends State<StoresScreen> {
  static const _letters = ['All', '#', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'];

  late final Repository _repo;
  late final Future<List<Store>> _featured;
  final _search = TextEditingController();
  final _scroll = ScrollController();
  Timer? _debounce;

  String _letter = 'All';
  final List<Store> _items = [];
  int _page = 1;
  bool _loading = false;
  bool _hasMore = true;
  Object? _error;
  int _generation = 0; // ignores stale responses after filters change

  bool get _filtered => _letter != 'All' || _search.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _repo = context.read<Repository>(); // read in initState, never during build
    _featured = _repo.popularStores();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 500) _loadMore();
    });
    Future.microtask(_loadMore); // after first build — no setState inside initState
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _reset() {
    _generation++;
    setState(() {
      _items.clear();
      _page = 1;
      _hasMore = true;
      _error = null;
      _loading = false;
    });
    _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    final gen = _generation;
    setState(() => _loading = true);
    try {
      final res = await _repo.stores(query: _search.text.trim(), letter: _letter == 'All' ? null : _letter, page: _page);
      if (!mounted || gen != _generation) return;
      setState(() {
        _items.addAll(res.items);
        _hasMore = res.hasMore;
        _page++;
      });
    } catch (e) {
      if (mounted && gen == _generation) setState(() => _error = e);
    } finally {
      if (mounted && gen == _generation) setState(() => _loading = false);
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _reset);
  }

  void _open(Store s) => Navigator.of(context).push(StoreScreen.route(s.slug));

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => _reset(),
      child: CustomScrollView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: DarkHeader(
              title: 'Stores',
              trailing: '10,000+ stores',
              child: SearchBox(controller: _search, onChanged: _onSearchChanged, hint: 'Search stores or brands'),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: PillRow<String>(
                values: _letters,
                selected: _letter,
                label: (l) => l,
                onSelected: (l) {
                  if (l == _letter) return;
                  _letter = l;
                  _reset();
                },
              ),
            ),
          ),
          if (!_filtered) ...[
            const SliverToBoxAdapter(child: SectionTitle('Featured', top: 16)),
            SliverToBoxAdapter(
              child: FutureBuilder<List<Store>>(
                future: _featured,
                builder: (_, s) {
                  final list = s.data ?? const <Store>[];
                  if (list.isEmpty) return const SizedBox(height: 8);
                  return SizedBox(
                    height: 132,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: DB.gutter),
                      itemCount: list.length > 8 ? 8 : list.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (_, i) => StoreFeatureCard(store: list[i], onTap: () => _open(list[i])),
                    ),
                  );
                },
              ),
            ),
          ],
          SliverToBoxAdapter(
            child: SectionTitle(
              _letter != 'All' ? 'Stores starting with $_letter' : (_search.text.trim().isNotEmpty ? 'Matching stores' : 'All stores'),
              top: _filtered ? 14 : 6,
            ),
          ),
          if (_items.isEmpty && _error != null)
            SliverToBoxAdapter(
              child: MessageState(icon: Icons.wifi_off_rounded, text: "Couldn't load stores.", actionLabel: 'Try again', onAction: _reset),
            )
          else if (_items.isEmpty && !_loading && !_hasMore)
            const SliverToBoxAdapter(child: EmptyNote('No stores match that search.'))
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: DB.gutter),
              sliver: SliverList.separated(
                itemCount: _items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => StoreListCard(store: _items[i], onTap: () => _open(_items[i])),
              ),
            ),
          SliverToBoxAdapter(child: _loading ? const Loading() : const SizedBox(height: 24)),
        ],
      ),
    );
  }
}
