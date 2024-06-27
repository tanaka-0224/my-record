import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/map_controller.dart';
import 'screens/map_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MapController()),
      ],
      child: const MaterialApp(home: MyApp()),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: MapScreen(),
    );
  }
}
