import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'data/api_config.dart';
import 'data/api_repository.dart';
import 'data/demo_repository.dart';
import 'data/repository.dart';
import 'screens/shell.dart';
import 'state/saved.dart';
import 'theme/tokens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light, // Android
    statusBarBrightness: Brightness.dark, // iOS
    systemNavigationBarColor: DB.ink,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final saved = SavedState();
  await saved.load();

  final Repository repo = ApiConfig.demo ? DemoRepository() : ApiRepository();

  runApp(MultiProvider(
    providers: [
      Provider<Repository>.value(value: repo),
      ChangeNotifierProvider<SavedState>.value(value: saved),
    ],
    child: const DiscountBayApp(),
  ));
}

class DiscountBayApp extends StatelessWidget {
  const DiscountBayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DiscountBay',
      debugShowCheckedModeBanner: false,
      theme: DB.theme(),
      home: const Shell(),
    );
  }
}
