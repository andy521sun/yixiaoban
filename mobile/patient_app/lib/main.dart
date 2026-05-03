import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/services/api_service.dart';
import 'core/services/websocket_service.dart';
import 'ui/pages/main_scaffold.dart';

import 'ui/pages/auth/login_page.dart';
import 'ui/pages/hospital/hospital_detail_page.dart';
import 'ui/pages/companion/companion_detail_page.dart';
import 'ui/pages/order/order_list_page.dart';
import 'ui/pages/order/order_detail_page.dart';
import 'ui/pages/appointment/appointment_page.dart';
import 'ui/pages/ai/ai_consult_page.dart';
import 'ui/pages/consultation/consultation_type_page.dart';
import 'ui/pages/consultation/symptom_input_page.dart';
import 'ui/pages/consultation/doctor_select_page.dart';
import 'ui/pages/consultation/consultation_confirm_page.dart';
import 'ui/pages/consultation/consultation_chat_page.dart';
import 'ui/pages/consultation/prescription_view_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: MaterialApp(
        title: '医小伴 - 温暖就医',
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
        onGenerateRoute: _onGenerateRoute,
      ),
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const MainScaffold());
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case '/hospital/detail':
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(builder: (_) => HospitalDetailPage(data: args));
      case '/companion/detail':
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(builder: (_) => CompanionDetailPage(data: args));
      case '/order/list':
        return MaterialPageRoute(builder: (_) => const OrderListPage());
      case '/order/detail':
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(builder: (_) => OrderDetailPage(data: args));
      case '/appointment':
        return MaterialPageRoute(builder: (_) => const AppointmentPage());
      case '/ai/consult':
        return MaterialPageRoute(builder: (_) => const AiConsultPage());
      case '/consultation/type-select':
        return MaterialPageRoute(builder: (_) => const ConsultationTypePage());
      case '/consultation/symptom':
        return MaterialPageRoute(builder: (_) => const SymptomInputPage());
      case '/consultation/doctor-select':
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(builder: (_) => const DoctorSelectPage());
      case '/consultation/confirm':
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(builder: (_) => const ConsultationConfirmPage());
      case '/consultation/chat':
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(builder: (_) => const ConsultationChatPage());
      case '/consultation/prescription':
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(builder: (_) => const PrescriptionViewPage());
      default:
        return MaterialPageRoute(builder: (_) => const MainScaffold());
    }
  }
}

class AppState extends ChangeNotifier {
  final ApiService api = ApiService();
  final WebSocketService ws = WebSocketService();
  bool _loggedIn = false;
  String _token = '';
  String _userName = '';
  String _userPhone = '';

  bool get loggedIn => _loggedIn;
  String get token => _token;
  String get userName => _userName;
  String get userPhone => _userPhone;

  void setLoggedIn(bool v) {
    _loggedIn = v;
    notifyListeners();
  }

  void setToken(String t) {
    _token = t;
    api.setToken(t);
    ws.connect(t);
  }

  void setUserName(String n) { _userName = n; notifyListeners(); }
  void setUserPhone(String p) => _userPhone = p;

  void logout() {
    ws.disconnect();
    _loggedIn = false;
    _token = '';
    api.setToken(null);
    notifyListeners();
  }

  @override
  void dispose() {
    ws.dispose();
    super.dispose();
  }
}
