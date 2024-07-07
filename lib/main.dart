import 'package:flutter/material.dart';
import 'package:my_record/controllers/map_controller.dart';
import 'package:provider/provider.dart';
import 'package:my_record/screens/map_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => MapController(context),
        ),
      ],
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: MapScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
