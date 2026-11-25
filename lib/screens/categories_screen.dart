import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../data/repository.dart';
import '../theme/identity.dart';
import '../theme/tokens.dart';
import '../widgets/components.dart' show MessageState;
import '../widgets/shop.dart';
import 'category_screen.dart';

/// Categories tab: a photo tile per category, with search.
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late final Repository _repo;
  late Future<List<StoreCategory>> _future;
  String _q = '';

  @override
  void initState() {
    super.initState();
    _repo = context.read<Repository>(); // read in initState, never during build
    _future = _repo.categories();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _future = _repo.categories());
        await _future.catchError((_) => <StoreCategory>[]);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: FutureBuilder<List<StoreCategory>>(
              future: _future,
              builder: (_, s) => DarkHeader(
                title: 'Categories',
                trailing: s.hasData ? '${s.data!.length} categories' : null,
                child: SearchBox(hint: 'Search categories', onChanged: (v) => setState(() => _q = v.trim().toLowerCase())),
              ),
            ),
          ),
          FutureBuilder<List<StoreCategory>>(
            future: _future,
            builder: (context, s) {
              if (s.connectionState != ConnectionState.done) return const SliverToBoxAdapter(child: Loading());
              if (s.hasError) {
                return SliverToBoxAdapter(
                  child: MessageState(
                    icon: Icons.wifi_off_rounded,
                    text: "Couldn't load categories.",
                    actionLabel: 'Try again',
                    onAction: () => setState(() => _future = _repo.categories()),
                  ),
                );
              }
              final cats = (s.data ?? const <StoreCategory>[]).where((c) => _q.isEmpty || c.name.toLowerCase().contains(_q)).toList();
              if (cats.isEmpty) return const SliverToBoxAdapter(child: EmptyNote('No category matches — try another word.'));
              return SliverPadding(
                padding: EdgeInsets.fromLTRB(DB.gutter, 14, DB.gutter, MediaQuery.paddingOf(context).bottom + 24),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, mainAxisExtent: 150),
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      final c = cats[i];
                      return CategoryPhotoTile(
                        label: c.name,
                        meta: c.storeCount > 0 ? '${c.storeCount} stores' : 'Explore stores',
                        photo: SiteCategory.guess([c.name]).photo,
                        onTap: () => Navigator.of(context).push(CategoryScreen.route(c)),
                      );
                    },
                    childCount: cats.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
