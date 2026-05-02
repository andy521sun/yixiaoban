import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/providers/doctor_state.dart';
import 'ui/pages/auth/login_page.dart';
import 'ui/pages/consultation/consultation_list_page.dart';
import 'ui/pages/consultation/doctor_cert_page.dart';
import 'ui/pages/profile/profile_page.dart';
import 'ui/pages/finance/finance_page.dart';
import 'ui/pages/consultation/consultation_chat_page_doctor.dart';

void main() {
  runApp(const DoctorApp());
}

class DoctorApp extends StatelessWidget {
  const DoctorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DoctorAppState()),
      ],
      child: MaterialApp(
        title: '医小伴医生端',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: const Color(0xFF1A73E8),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1A73E8),
            primary: const Color(0xFF1A73E8),
            secondary: const Color(0xFF34A853),
          ),
          scaffoldBackgroundColor: const Color(0xFFF5F7FA),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Color(0xFF202124),
            elevation: 0.5,
            centerTitle: true,
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFFE8EAED)),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A73E8),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFFF1F3F4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        initialRoute: '/',
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/login':
              return MaterialPageRoute(builder: (_) => const DoctorLoginPage());
            case '/certification':
              return MaterialPageRoute(builder: (_) => const DoctorCertPage());
            case '/finance':
              return MaterialPageRoute(builder: (_) => const FinancePage());
            case '/consultation/chat':
              final args = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(
                builder: (_) => DoctorConsultationChatPage(consultationId: args['consultation_id'] as String),
              );
            default:
              return MaterialPageRoute(builder: (_) => const DoctorMainScaffold());
          }
        },
      ),
    );
  }
}

/// 医生端主框架 — 底部导航
class DoctorMainScaffold extends StatefulWidget {
  const DoctorMainScaffold({super.key});

  @override
  State<DoctorMainScaffold> createState() => _DoctorMainScaffoldState();
}

class _DoctorMainScaffoldState extends State<DoctorMainScaffold> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DoctorAppState>();

    if (!state.loggedIn) {
      return const DoctorLoginPage();
    }

    final pages = [
      const DoctorConsultationListPage(),
      const FinancePage(),
      const ProfilePage(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: '问诊'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: '收入'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: '我的'),
        ],
      ),
    );
  }
}
