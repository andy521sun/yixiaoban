import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/config/theme_config.dart';
import 'core/services/auth_provider.dart';
import 'features/auth/pages/login_page.dart';
import 'features/dashboard/pages/dashboard_page.dart';
import 'features/users/pages/users_page.dart';
import 'features/orders/pages/orders_page.dart';
import 'features/hospitals/pages/hospitals_page.dart';
import 'features/companions/pages/companions_page.dart';
import 'features/settings/pages/settings_page.dart';
import 'features/finance/pages/finance_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        title: '医小伴管理后台',
        debugShowCheckedModeBanner: false,
        theme: AdminTheme.lightTheme,
        home: const AdminShell(),
      ),
    );
  }
}

/// 管理后台外壳 - 负责登录守卫和布局
class AdminShell extends StatelessWidget {
  const AdminShell({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isLoggedIn) return const LoginPage();
    return const AdminLayout();
  }
}

/// 管理后台布局（侧边栏 + 主内容区）
class AdminLayout extends StatefulWidget {
  const AdminLayout({super.key});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  int _selectedIndex = 0;

  final _pages = <Widget>[
    const DashboardPage(),
    const UsersPage(),
    const OrdersPage(),
    const HospitalsPage(),
    const CompanionsPage(),
    const FinancePage(),
    const SettingsPage(),
  ];

  final _titles = [
    '数据概览',
    '用户管理',
    '订单管理',
    '医院管理',
    '陪诊师管理',
    '财务管理',
    '系统设置',
  ];

  final _icons = <IconData>[
    Icons.dashboard_outlined,
    Icons.people_outline,
    Icons.receipt_outlined,
    Icons.local_hospital_outlined,
    Icons.medical_services_outlined,
    Icons.account_balance_wallet_outlined,
    Icons.settings_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;

    if (isWide) {
      return _buildWideLayout();
    }
    return _buildNarrowLayout();
  }

  Widget _buildWideLayout() {
    return Scaffold(
      body: Row(
        children: [
          // 侧边栏
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (i) => setState(() => _selectedIndex = i),
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF34A853),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.medical_services,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(height: 4),
                  const Text('医小伴', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            destinations: List.generate(
              _titles.length,
              (i) => NavigationRailDestination(
                icon: Icon(_icons[i]),
                selectedIcon: Icon(_icons[i]),
                label: Text(_titles[i], style: const TextStyle(fontSize: 12)),
              ),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: IconButton(
                    icon: const Icon(Icons.logout, color: Colors.red),
                    onPressed: () {
                      context.read<AuthProvider>().logout();
                      setState(() {});
                    },
                    tooltip: '退出登录',
                  ),
                ),
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          // 主内容
          Expanded(
            child: Scaffold(
              appBar: AppBar(
                title: Text(_titles[_selectedIndex]),
                actions: [
                  _buildAdminInfo(),
                ],
              ),
              body: _pages[_selectedIndex],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNarrowLayout() {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: [_buildAdminInfo()],
      ),
      body: _pages[_selectedIndex],
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF34A853)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.medical_services, color: Colors.white, size: 40),
                  const SizedBox(height: 8),
                  const Text('医小伴管理后台',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('v1.0.0', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                ],
              ),
            ),
            ...List.generate(_titles.length, (i) => ListTile(
              leading: Icon(_icons[i]),
              title: Text(_titles[i]),
              selected: _selectedIndex == i,
              onTap: () {
                setState(() => _selectedIndex = i);
                Navigator.pop(context);
              },
            )),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('退出登录', style: TextStyle(color: Colors.red)),
              onTap: () {
                context.read<AuthProvider>().logout();
                setState(() {});
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminInfo() {
    final auth = context.watch<AuthProvider>();
    final name = auth.adminName;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const Text('管理员', style: TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFF34A853),
            child: Text(
              name.isNotEmpty ? name[0] : 'A',
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
