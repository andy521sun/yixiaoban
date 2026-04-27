import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'core/config/theme_config.dart';
import 'ui/pages/auth/simple_login_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: '医小伴',
      debugShowCheckedModeBanner: false,
      theme: ThemeConfig.lightTheme,
      darkTheme: ThemeConfig.darkTheme,
      themeMode: ThemeMode.light,
      home: const SimpleLoginPage(),
    );
  }
}