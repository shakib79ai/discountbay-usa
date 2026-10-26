import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../data/repository.dart';
import '../theme/tokens.dart';
import '../widgets/components.dart';
import '../widgets/decor.dart';
import 'category_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late final Repository _repo;
  late Future<List<StoreCategory>> _future;

  @override
  void initState() {
    super.initState();
    _repo = context.read<Repository>();
    _future = _repo.categories();
  }

  // Rotating accent colours for the tiles, like the website's category tiles.
  static const _accents = [DB.coral, DB.mustard, DB.mint, DB.paper];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('CATEGORIES', style: DB.display(24)),
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: DashedLine(color: DB.lineOnInk)),
      ),
      body: RefreshIndicator(
        color: DB.ink,
        backgroundColor: DB.mustard,
        onRefresh: () async {
          setState(() => _future = _repo.categories());
          await _future.catchError((_) => <StoreCategory>[]);
        },
        child: AsyncView<List<StoreCategory>>(
          future: _future,
          onRetry: () => setState(() => _future = _repo.categories()),
          isEmpty: (l) => l.isEmpty,
          builder: (context, cats) => GridView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(DB.gutter),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.35,
            ),
            itemCount: cats.length,
            itemBuilder: (context, i) => _CategoryTile(
              category: cats[i],
              accent: _accents[i % _accents.length],
              index: i,
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.accent, required this.index});
  final StoreCategory category;
  final Color accent;
  final int index;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: TicketClipper(notchRadius: 8),
      child: Material(
        color: accent,
        child: InkWell(
          onTap: () => Navigator.of(context).push(CategoryScreen.route(category)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text((index + 1).toString().padLeft(2, '0'), style: DB.mono(11, color: DB.ink.withValues(alpha: 0.6))),
                const Spacer(),
                Text(category.name,
                    maxLines: 2, overflow: TextOverflow.ellipsis, style: DB.heading(16, color: DB.ink)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (category.storeCount > 0)
                      Text('${category.storeCount} stores', style: DB.body(12, color: DB.ink.withValues(alpha: 0.7))),
                    const Spacer(),
                    const Icon(Icons.arrow_forward, size: 18, color: DB.ink),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
