import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'categories_screen.dart';
import 'home_screen.dart';
import 'saved_screen.dart';
import 'stores_screen.dart';

/// Bottom tab bar: Home · Stores · Categories · Saved — same as the website's mobile bar.
class Shell extends StatefulWidget {
  const Shell({super.key});

  /// Switch bottom tab from anywhere below the shell (0 Home, 1 Stores, 2 Categories, 3 Saved).
  static void switchTab(BuildContext context, int index) =>
      context.findAncestorStateOfType<_ShellState>()?.goTo(index);

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _index = 0;

  void goTo(int i) => setState(() => _index = i);

  static const _tabs = [
    (Icons.home_outlined, Icons.home_rounded, 'Home'),
    (Icons.storefront_outlined, Icons.storefront_rounded, 'Stores'),
    (Icons.grid_view_outlined, Icons.grid_view_rounded, 'Categories'),
    (Icons.bookmark_border_rounded, Icons.bookmark_rounded, 'Saved'),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) goTo(0);
      },
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: const [HomeScreen(), StoresScreen(), CategoriesScreen(), SavedScreen()],
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: DB.ink,
            border: Border(top: BorderSide(color: DB.lineOnInk)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 62,
              child: Row(
                children: [
                  for (var i = 0; i < _tabs.length; i++)
                    Expanded(
                      child: InkWell(
                        onTap: () => goTo(i),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              decoration: BoxDecoration(
                                color: i == _index ? DB.mustard : Colors.transparent,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Icon(i == _index ? _tabs[i].$2 : _tabs[i].$1,
                                  size: 22, color: i == _index ? DB.ink : DB.paper.withValues(alpha: 0.7)),
                            ),
                            const SizedBox(height: 4),
                            Text(_tabs[i].$3,
                                style: DB.body(11,
                                    color: i == _index ? DB.paper : DB.paper.withValues(alpha: 0.6),
                                    weight: i == _index ? FontWeight.w700 : FontWeight.w500)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
