import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';

import 'core/config/app_config.dart';
import 'core/config/theme_config.dart';
import 'core/providers/appointment_provider.dart';
import 'core/providers/user_provider.dart';

// 认证页面
import 'ui/pages/auth/simple_login_page.dart';
import 'ui/pages/auth/register_page.dart';

// 主页面
import 'ui/pages/home/home_page.dart';
import 'ui/pages/order/order_list_page.dart';
import 'ui/pages/chat/chat_list_page.dart';
import 'ui/pages/profile/profile_page.dart';

// 医院相关
import 'ui/pages/hospital/hospital_detail_page.dart';

// 陪诊师相关
import 'ui/pages/companion/companion_detail_page.dart';

// 预约相关
import 'ui/pages/appointment/appointment_select_page.dart';
import 'ui/pages/appointment/appointment_confirm_page.dart';

// 支付相关
import 'ui/pages/payment/payment_page.dart';

// 订单相关
import 'ui/pages/order/order_status_page.dart';
import 'ui/pages/order/order_detail_page.dart';

class AppRoutes {
  static final List<GetPage> routes = [
    // 认证页面
    GetPage(
      name: '/login',
      page: () => SimpleLoginPage(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: '/register',
      page: () => RegisterPage(),
      transition: Transition.fadeIn,
    ),
    
    // 主页面
    GetPage(
      name: '/',
      page: () => HomePage(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: '/home',
      page: () => HomePage(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: '/orders',
      page: () => OrderListPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: '/chat',
      page: () => ChatListPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: '/profile',
      page: () => ProfilePage(),
      transition: Transition.rightToLeft,
    ),
    
    // 医院相关
    GetPage(
      name: '/hospital/detail',
      page: () => HospitalDetailPage(),
      transition: Transition.rightToLeft,
    ),
    
    // 陪诊师相关
    GetPage(
      name: '/companion/detail',
      page: () => CompanionDetailPage(),
      transition: Transition.rightToLeft,
    ),
    
    // 预约相关
    GetPage(
      name: '/appointment/select',
      page: () => AppointmentSelectPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: '/appointment/confirm',
      page: () => AppointmentConfirmPage(),
      transition: Transition.rightToLeft,
    ),
    
    // 支付相关
    GetPage(
      name: '/payment',
      page: () => PaymentPage(),
      transition: Transition.rightToLeft,
    ),
    
    // 订单相关
    GetPage(
      name: '/order/status',
      page: () => OrderStatusPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: '/order/detail',
      page: () => OrderDetailPage(),
      transition: Transition.rightToLeft,
    ),
  ];
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => AppointmentProvider()),
      ],
      child: GetMaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeConfig.lightTheme,
        darkTheme: ThemeConfig.darkTheme,
        themeMode: ThemeMode.light,
        initialRoute: '/login',
        getPages: AppRoutes.routes,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
            child: child!,
          );
        },
      ),
    );
  }
}