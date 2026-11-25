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
    (Icons.favorite_border_rounded, Icons.favorite_rounded, 'Saved'),
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
            color: Colors.white,
            border: Border(top: BorderSide(color: DB.border)),
            boxShadow: [BoxShadow(color: Color(0x0F12203A), blurRadius: 18, offset: Offset(0, -6))],
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 64,
              child: Row(
                children: [
                  for (var i = 0; i < _tabs.length; i++)
                    Expanded(
                      child: Semantics(
                        selected: i == _index,
                        button: true,
                        label: _tabs[i].$3,
                        child: InkWell(
                          onTap: () => goTo(i),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(i == _index ? _tabs[i].$2 : _tabs[i].$1,
                                  size: 25, color: i == _index ? DB.ink : const Color(0xFF6B7486)),
                              const SizedBox(height: 3),
                              Text(_tabs[i].$3,
                                  style: DB.body(11.5,
                                      color: i == _index ? DB.ink : const Color(0xFF6B7486),
                                      weight: i == _index ? FontWeight.w700 : FontWeight.w500)),
                            ],
                          ),
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
