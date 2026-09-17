import 'package:flutter/material.dart';
import 'ui/theme/emergixx_theme.dart';
import 'ui/screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EmergixxApp());
}

class EmergixxApp extends StatelessWidget {
  const EmergixxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Emergixx',
      debugShowCheckedModeBanner: false,
      theme: EmergixxTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
