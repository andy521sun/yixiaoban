import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/providers/companion_state.dart';
import 'core/config/theme_config.dart';
import 'ui/pages/auth/login_page.dart';
import 'ui/pages/home/companion_home_page.dart';
import 'ui/pages/order/order_detail_page.dart';
import 'ui/pages/notifications/notifications_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final state = CompanionState();
        // 可在这里恢复 token 自动登录
        return state;
      },
      child: MaterialApp(
        title: '医小伴 - 陪诊师端',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/login',
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/home':
              return MaterialPageRoute(
                builder: (_) => const CompanionHomePage(),
              );
            case '/order/detail':
              final args = settings.arguments as Map<String, dynamic>?;
              if (args != null) {
                return MaterialPageRoute(
                  builder: (_) => OrderDetailPage(
                    order: args['order'] as Map<String, dynamic>? ?? {},
                    orderId: args['order_id'] as String? ?? '',
                  ),
                );
              }
              return MaterialPageRoute(
                builder: (_) => const CompanionHomePage(),
              );
            case '/notifications':
              return MaterialPageRoute(
                builder: (_) => const CompanionNotificationsPage(),
              );
            case '/login':
            default:
              return MaterialPageRoute(
                builder: (_) => const LoginPage(),
              );
          }
        },
      ),
    );
  }
}
