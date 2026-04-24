import 'package:go_router/go_router.dart';
import 'package:yixiaoban_app/features/auth/pages/login_page.dart';
import 'package:yixiaoban_app/features/auth/pages/register_page.dart';
import 'package:yixiaoban_app/features/auth/pages/verify_page.dart';
import 'package:yixiaoban_app/features/home/pages/home_page.dart';
import 'package:yixiaoban_app/features/order/pages/order_create_page.dart';
import 'package:yixiaoban_app/features/order/pages/order_detail_page.dart';
import 'package:yixiaoban_app/features/order/pages/order_list_page.dart';
import 'package:yixiaoban_app/features/chat/pages/chat_page.dart';
import 'package:yixiaoban_app/features/profile/pages/profile_page.dart';
import 'package:yixiaoban_app/features/profile/pages/settings_page.dart';
import 'package:yixiaoban_app/features/ai/pages/ai_consult_page.dart';
import 'package:yixiaoban_app/features/companion/pages/companion_home.dart';
import 'package:yixiaoban_app/features/companion/pages/companion_profile.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    routes: [
      // 认证路由
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/verify',
        name: 'verify',
        builder: (context, state) => const VerifyPage(),
      ),
      
      // 用户端主路由
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/order/create',
        name: 'order_create',
        builder: (context, state) => const OrderCreatePage(),
      ),
      GoRoute(
        path: '/order/detail/:id',
        name: 'order_detail',
        builder: (context, state) => OrderDetailPage(
          orderId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/orders',
        name: 'orders',
        builder: (context, state) => const OrderListPage(),
      ),
      GoRoute(
        path: '/chat/:roomId',
        name: 'chat',
        builder: (context, state) => ChatPage(
          roomId: state.pathParameters['roomId']!,
        ),
      ),
      GoRoute(
        path: '/ai/consult',
        name: 'ai_consult',
        builder: (context, state) => const AiConsultPage(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),
      
      // 陪诊师端路由
      GoRoute(
        path: '/companion/home',
        name: 'companion_home',
        builder: (context, state) => const CompanionHomePage(),
      ),
      GoRoute(
        path: '/companion/profile',
        name: 'companion_profile',
        builder: (context, state) => const CompanionProfilePage(),
      ),
    ],
    
    // 路由守卫
    redirect: (context, state) {
      final authService = context.read<AuthService>();
      final isLoggedIn = authService.isLoggedIn;
      final isCompanion = authService.user?.role == 'companion';
      
      // 未登录且不在登录/注册页面
      if (!isLoggedIn && 
          state.location != '/login' && 
          state.location != '/register' &&
          state.location != '/verify') {
        return '/login';
      }
      
      // 已登录且是陪诊师，访问用户端页面
      if (isLoggedIn && isCompanion && 
          !state.location.startsWith('/companion') &&
          state.location != '/login' &&
          state.location != '/register' &&
          state.location != '/verify') {
        return '/companion/home';
      }
      
      // 已登录且是用户，访问陪诊师端页面
      if (isLoggedIn && !isCompanion && 
          state.location.startsWith('/companion')) {
        return '/home';
      }
      
      return null;
    },
  );
}