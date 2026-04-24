import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/services/auth_service.dart';
import 'core/services/storage_service.dart';
import 'ui/pages/auth/login_page.dart';
import 'ui/pages/home/home_page.dart';
import 'ui/pages/splash/splash_page.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // 初始化存储服务
    await _storageService.init();
    
    // 检查登录状态
    final isLoggedIn = await _authService.checkLoginStatus();
    
    // 这里可以添加其他初始化逻辑
    // 如：加载配置、初始化网络等
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => _authService),
        Provider(create: (_) => _storageService),
      ],
      child: Consumer<AuthService>(
        builder: (context, authService, child) {
          return FutureBuilder<bool>(
            future: authService.isInitialized,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SplashPage();
              }

              if (snapshot.hasError) {
                return const Scaffold(
                  body: Center(
                    child: Text('应用初始化失败'),
                  ),
                );
              }

              final isLoggedIn = snapshot.data ?? false;
              return isLoggedIn ? const HomePage() : const LoginPage();
            },
          );
        },
      ),
    );
  }
}