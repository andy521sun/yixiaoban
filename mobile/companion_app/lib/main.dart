import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

const String _baseUrl = 'https://andysun521.online/api/companion';
const String _authUrl = 'http://122.51.179.136/api/auth';
const String _wsUrl = 'ws://122.51.179.136/ws';

void main() {
  runApp(const CompanionApp());
}

class CompanionApp extends StatelessWidget {
  const CompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '医小伴 - 陪诊师端',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        primaryColor: const Color(0xFF34A853),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF34A853),
          primary: const Color(0xFF34A853),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF202124),
          elevation: 1,
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
            backgroundColor: const Color(0xFF34A853),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 44),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
      home: const CompanionLoginPage(),
    );
  }
}

// ==================== 登录页 ====================
class CompanionLoginPage extends StatefulWidget {
  const CompanionLoginPage({super.key});

  @override
  State<CompanionLoginPage> createState() => _CompanionLoginPageState();
}

class _CompanionLoginPageState extends State<CompanionLoginPage> {
  final _phoneController = TextEditingController(text: '13900139001');
  final _passwordController = TextEditingController(text: '123456');
  bool _loading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      final res = await http.post(
        Uri.parse('$_authUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': _phoneController.text.trim(), 'password': _passwordController.text}),
      );
      final data = jsonDecode(res.body);
      if (data['success'] == true && mounted) {
        final token = data['data']['token'];
        final user = data['data']['user'];
        Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (_) => CompanionHome(token: token, userName: user?['name'] ?? '陪诊师'),
        ));
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? '登录失败'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('网络错误: $e'), backgroundColor: Colors.red),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('陪诊师登录'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF202124),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF34A853).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.medical_services_outlined, size: 48, color: Color(0xFF34A853)),
              ),
              const SizedBox(height: 20),
              const Text('医小伴', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF202124))),
              const SizedBox(height: 4),
              Text('陪诊师端', style: TextStyle(color: Colors.grey[500], fontSize: 15)),
              const SizedBox(height: 48),
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: '手机号',
                  prefixIcon: const Icon(Icons.phone_android, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: const Color(0xFFF5F7FA),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: '密码',
                  prefixIcon: const Icon(Icons.lock_outline, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: const Color(0xFFF5F7FA),
                ),
                obscureText: true,
                onSubmitted: (_) => _login(),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('登 录', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== 主页面 ====================
class CompanionHome extends StatefulWidget {
  final String token;
  final String userName;
  const CompanionHome({super.key, required this.token, required this.userName});

  @override
  State<CompanionHome> createState() => _CompanionHomeState();
}

class _CompanionHomeState extends State<CompanionHome> {
  int _tab = 0;
  List<dynamic> _availableOrders = [];
  List<dynamic> _myOrders = [];
  Map<String, dynamic>? _stats;
  Map<String, dynamic>? _profile;
  bool _loading = true;
  String _connectionStatus = '未连接';
  WebSocketChannel? _channel;
  int _notificationCount = 0;

  @override
  void initState() {
    super.initState();
    _loadAll();
    _connectWebSocket();
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }

  void _connectWebSocket() {
    try {
      _channel = WebSocketChannel.connect(Uri.parse('$_wsUrl?token=${widget.token}'));
      _channel!.stream.listen(
        (data) {
          final msg = jsonDecode(data);
          if (msg['type'] == 'connection_established') {
            setState(() => _connectionStatus = '已连接');
          } else if (msg['type'] == 'system_notification') {
            setState(() => _notificationCount++);
            final title = msg['data']?['title'] ?? '新通知';
            final content = msg['data']?['content'] ?? '';
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(children: [
                    const Icon(Icons.notifications_active, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(child: Text('$title: $content')),
                  ]),
                  backgroundColor: const Color(0xFF34A853),
                  duration: const Duration(seconds: 4),
                  action: SnackBarAction(
                    label: '查看',
                    textColor: Colors.white,
                    onPressed: () => setState(() => _tab = 1),
                  ),
                ),
              );
            }
            _loadAll();
          }
        },
        onError: (e) => setState(() => _connectionStatus = '连接失败'),
        onDone: () {
          setState(() => _connectionStatus = '已断开');
          Future.delayed(const Duration(seconds: 5), _connectWebSocket);
        },
      );
      setState(() => _connectionStatus = '连接中...');
    } catch (e) {
      setState(() => _connectionStatus = '连接失败');
    }
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final r = await Future.wait([
        http.get(Uri.parse('$_baseUrl/orders/available'), headers: {'Authorization': 'Bearer ${widget.token}'}),
        http.get(Uri.parse('$_baseUrl/orders/mine'), headers: {'Authorization': 'Bearer ${widget.token}'}),
        http.get(Uri.parse('$_baseUrl/stats'), headers: {'Authorization': 'Bearer ${widget.token}'}),
        http.get(Uri.parse('$_baseUrl/profile'), headers: {'Authorization': 'Bearer ${widget.token}'}),
      ]);
      if (!mounted) return;
      setState(() {
        _availableOrders = jsonDecode(r[0].body)['data'] ?? [];
        _myOrders = jsonDecode(r[1].body)['data'] ?? [];
        _stats = jsonDecode(r[2].body)['data'] ?? {};
        _profile = jsonDecode(r[3].body)['data'] ?? {};
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _acceptOrder(String orderId) async {
    try {
      final r = await http.post(
        Uri.parse('$_baseUrl/orders/$orderId/accept'),
        headers: {'Authorization': 'Bearer ${widget.token}', 'Content-Type': 'application/json'},
      );
      final data = jsonDecode(r.body);
      if (data['success'] == true) {
        _loadAll();
      }
    } catch (_) {}
  }

  Future<void> _startService(String orderId) async {
    final r = await http.post(
      Uri.parse('$_baseUrl/orders/$orderId/start'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    if (jsonDecode(r.body)['success'] == true) _loadAll();
  }

  Future<void> _completeService(String orderId) async {
    final r = await http.post(
      Uri.parse('$_baseUrl/orders/$orderId/complete'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    if (jsonDecode(r.body)['success'] == true) _loadAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _tab == 0 ? '待接订单' : _tab == 1 ? '我的任务' : '个人中心',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          if (_connectionStatus == '已连接')
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF34A853).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF34A853), shape: BoxShape.circle)),
                const SizedBox(width: 4),
                const Text('在线', style: TextStyle(color: Color(0xFF34A853), fontSize: 11)),
              ]),
            ),
          if (_notificationCount > 0)
            Stack(
              children: [
                IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
                Positioned(right: 6, top: 6, child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  child: Text('$_notificationCount', style: const TextStyle(color: Colors.white, fontSize: 10)),
                )),
              ],
            ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF34A853),
              child: Text(
                widget.userName.isNotEmpty ? widget.userName[0] : '?',
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: _tab,
              children: [
                _buildAvailableOrders(),
                _buildMyOrders(),
                _buildProfile(),
              ],
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: <Widget>[
          NavigationDestination(
            icon: const Icon(Icons.assignment_outlined),
            selectedIcon: Stack(children: [
              const Icon(Icons.assignment),
              if (_availableOrders.isNotEmpty)
                Positioned(
                  right: 0, top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Text('${_availableOrders.length}', style: const TextStyle(color: Colors.white, fontSize: 9)),
                  ),
                ),
            ]),
            label: '待接',
          ),
          const NavigationDestination(icon: Icon(Icons.task_alt_outlined), selectedIcon: Icon(Icons.task_alt), label: '任务'),
          const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: '我的'),
        ],
      ),
    );
  }

  // 待接订单页
  Widget _buildAvailableOrders() {
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: _availableOrders.isEmpty
          ? ListView(children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.5,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('暂无待接订单', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('有新订单时会实时通知你', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ])
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _availableOrders.length,
              itemBuilder: (context, i) {
                final o = _availableOrders[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: const Color(0xFF1A73E8).withOpacity(0.1),
                              child: Text(
                                (o['patient_name'] ?? '?')[0],
                                style: const TextStyle(color: Color(0xFF1A73E8), fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(o['patient_name'] ?? '未知', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A73E8).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(o['service_type'] ?? '', style: const TextStyle(color: Color(0xFF1A73E8), fontSize: 12)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _infoRow(Icons.local_hospital, o['hospital_name'] ?? '', Colors.grey[700]!),
                        _infoRow(Icons.access_time, '${o['appointment_date'] ?? ''} ${o['appointment_time'] ?? ''}', Colors.grey[700]!),
                        _infoRow(Icons.timer_outlined, '${o['duration_minutes'] ?? 120}分钟', Colors.grey[700]!),
                        if (o['symptoms']?.toString().isNotEmpty == true)
                          _infoRow(Icons.healing, '症状: ${o['symptoms']}', Colors.grey[600]!),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text('¥${o['price'] ?? 0}', style: const TextStyle(color: Color(0xFF1A73E8), fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Text('/单', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                            const Spacer(),
                            ElevatedButton(
                              onPressed: () => _acceptOrder(o['id']),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(100, 38),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('接单', style: TextStyle(fontSize: 15)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  // 我的任务页
  Widget _buildMyOrders() {
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: _myOrders.isEmpty
          ? ListView(children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.5,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.task_alt_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('暂无任务', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ])
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _myOrders.length,
              itemBuilder: (context, i) {
                final o = _myOrders[i];
                final status = o['status'] ?? '';

                Color statusColor;
                Color btnColor;
                String statusText;
                String? actionLabel;
                VoidCallback? actionFn;

                switch (status) {
                  case 'confirmed':
                    statusColor = const Color(0xFF1A73E8);
                    btnColor = const Color(0xFF1A73E8);
                    statusText = '已确认';
                    actionLabel = '开始服务';
                    actionFn = () => _startService(o['id']);
                    break;
                  case 'in_progress':
                    statusColor = const Color(0xFF34A853);
                    btnColor = const Color(0xFF34A853);
                    statusText = '服务中';
                    actionLabel = '完成服务';
                    actionFn = () => _completeService(o['id']);
                    break;
                  case 'completed':
                    statusColor = Colors.grey;
                    btnColor = Colors.grey;
                    statusText = '已完成';
                    break;
                  default:
                    statusColor = const Color(0xFFF4B400);
                    btnColor = const Color(0xFFF4B400);
                    statusText = status;
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(o['patient_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                              child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w500)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        _infoRow(Icons.local_hospital, o['hospital_name'] ?? '', Colors.grey[600]!),
                        _infoRow(Icons.access_time, '${o['appointment_date'] ?? ''} ${o['appointment_time'] ?? ''}', Colors.grey[600]!),
                        if (actionLabel != null) ...[
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              onPressed: actionFn,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: btnColor,
                                minimumSize: const Size(120, 38),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: Text(actionLabel, style: const TextStyle(fontSize: 14)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  // 个人中心页
  Widget _buildProfile() {
    final name = _profile?['real_name'] ?? _profile?['name'] ?? '陪诊师';
    final exp = _profile?['experience_years'] ?? '-';
    final rating = _profile?['average_rating'] ?? _profile?['rating'] ?? '-';
    final rate = _profile?['hourly_rate'] ?? 0;
    final total = _stats?['total_orders'] ?? '0';
    final today = _stats?['today_orders'] ?? '0';
    final active = _stats?['in_progress'] ?? '0';
    final earnings = _stats?['today_earnings'] ?? '0';
    final spec = _profile?['specialty'] ?? '';

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 头像信息
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: const Color(0xFF34A853),
                    child: Text(name[0], style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('${exp}年经验 · ¥$rate/时 · $rating评分',
                            style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                        if (spec.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text('擅长: $spec', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 数据统计
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _statItem(total.toString(), '累计订单'),
                  _statItem(today.toString(), '今日任务'),
                  _statItem(active.toString(), '服务中'),
                  _statItem('¥$earnings', '今日营收'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // WebSocket 连接状态
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      color: _connectionStatus == '已连接' ? const Color(0xFF34A853) : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('通知服务: $_connectionStatus', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  const Spacer(),
                  if (_notificationCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('$_notificationCount 条新通知', style: const TextStyle(color: Colors.red, fontSize: 11)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 功能菜单
          Card(
            child: Column(
              children: [
                _menuItem(Icons.calendar_today, '我的日程', ''),
                const Divider(height: 1, indent: 56),
                _menuItem(Icons.star_outline, '服务评价', ''),
                const Divider(height: 1, indent: 56),
                _menuItem(Icons.monetization_on_outlined, '收入明细', ''),
                const Divider(height: 1, indent: 56),
                _menuItem(Icons.settings_outlined, '设置', ''),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CompanionLoginPage())),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFDB4437),
                side: const BorderSide(color: Color(0xFFDB4437)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('退出登录'),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[500]),
          const SizedBox(width: 6),
          Flexible(child: Text(text, style: TextStyle(color: color, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _statItem(String count, String label) {
    return Column(
      children: [
        Text(count, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF34A853))),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  Widget _menuItem(IconData icon, String label, String route) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(label, style: const TextStyle(fontSize: 15)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
    );
  }
}
