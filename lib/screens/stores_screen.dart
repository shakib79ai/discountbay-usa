import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../data/repository.dart';
import '../theme/tokens.dart';
import '../widgets/components.dart';
import '../widgets/decor.dart';
import 'store_screen.dart';

/// All stores: search box, A–Z letter rail and an infinite list.
class StoresScreen extends StatefulWidget {
  const StoresScreen({super.key});

  @override
  State<StoresScreen> createState() => _StoresScreenState();
}

class _StoresScreenState extends State<StoresScreen> {
  static const _letters = ['All', '#', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'];

  late final Repository _repo = context.read<Repository>();
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

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 400) _loadMore();
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
      final res = await _repo.stores(
        query: _search.text.trim(),
        letter: _letter == 'All' ? null : _letter,
        page: _page,
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ALL STORES', style: DB.display(24)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(112),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(DB.gutter, 4, DB.gutter, 10),
                child: _SearchField(controller: _search, onChanged: _onSearchChanged, hint: 'Search 10,000+ stores'),
              ),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemCount: _letters.length,
                  itemBuilder: (_, i) {
                    final l = _letters[i];
                    final on = l == _letter;
                    return GestureDetector(
                      onTap: () {
                        if (on) return;
                        _letter = l;
                        _reset();
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: on ? DB.mustard : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(l, style: DB.mono(13, color: on ? DB.ink : DB.paper.withValues(alpha: 0.8))),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 6),
              const DashedLine(color: DB.lineOnInk),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        color: DB.ink,
        backgroundColor: DB.mustard,
        onRefresh: () async => _reset(),
        child: _body(),
      ),
    );
  }

  Widget _body() {
    if (_items.isEmpty && _error != null) {
      return ListView(children: [
        MessageState(icon: Icons.wifi_off_rounded, text: "Couldn't load stores.", actionLabel: 'Try again', onAction: _reset),
      ]);
    }
    if (_items.isEmpty && !_loading && !_hasMore) {
      return ListView(children: const [
        MessageState(icon: Icons.search_off, text: 'No stores match that search.'),
      ]);
    }
    return ListView.separated(
      controller: _scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 6, bottom: 24),
      itemCount: _items.length + 1,
      separatorBuilder: (_, __) =>
          const Padding(padding: EdgeInsets.symmetric(horizontal: DB.gutter), child: Divider(color: DB.lineOnInk, height: 1)),
      itemBuilder: (context, i) {
        if (i == _items.length) {
          return _loading
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator(color: DB.mustard, strokeWidth: 2.5)),
                )
              : const SizedBox(height: 8);
        }
        final s = _items[i];
        return StoreRow(store: s, onTap: () => Navigator.of(context).push(StoreScreen.route(s.slug)));
      },
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged, required this.hint});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return SearchInput(controller: controller, onChanged: onChanged, hint: hint);
  }
}

/// Paper pill search input, shared with the Search screen.
class SearchInput extends StatelessWidget {
  const SearchInput({
    super.key,
    required this.controller,
    this.onChanged,
    this.onSubmitted,
    this.hint = 'Search stores & deals',
    this.autofocus = false,
  });

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String hint;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: DB.paper, borderRadius: BorderRadius.circular(999)),
      child: Row(
        children: [
          Icon(Icons.search, color: DB.ink.withValues(alpha: 0.5), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: autofocus,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              textInputAction: TextInputAction.search,
              style: DB.body(15),
              cursorColor: DB.coral,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: DB.body(15, color: DB.ink.withValues(alpha: 0.45)),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          ListenableBuilder(
            listenable: controller,
            builder: (_, __) => controller.text.isEmpty
                ? const SizedBox.shrink()
                : GestureDetector(
                    onTap: () {
                      controller.clear();
                      onChanged?.call('');
                    },
                    child: Icon(Icons.close, size: 18, color: DB.ink.withValues(alpha: 0.6)),
                  ),
          ),
        ],
      ),
    );
  }
}
