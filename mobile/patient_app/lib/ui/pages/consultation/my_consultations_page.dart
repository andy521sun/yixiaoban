import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../main.dart';


/// 我的问诊列表 — 患者查看所有在线问诊记录
class MyConsultationsPage extends StatefulWidget {
  const MyConsultationsPage({super.key});

  @override
  State<MyConsultationsPage> createState() => _MyConsultationsPageState();
}

class _MyConsultationsPageState extends State<MyConsultationsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<String, List<Map<String, dynamic>>> _data = {
    'all': [],
    'pending': [],
    'active': [],
    'completed': [],
  };
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final appState = context.read<AppState>();
    final all = await appState.api.getConsultations();
    if (!mounted) return;

    setState(() {
      _data['all'] = all.cast<Map<String, dynamic>>();
      _data['pending'] = all.where((c) => c['status'] == 'pending').toList().cast<Map<String, dynamic>>();
      _data['active'] = all
          .where((c) => c['status'] == 'active' || c['status'] == 'in_progress')
          .toList()
          .cast<Map<String, dynamic>>();
      _data['completed'] = all
          .where((c) => c['status'] == 'completed' || c['status'] == 'rated')
          .toList()
          .cast<Map<String, dynamic>>();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的问诊'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          labelColor: const Color(0xFF1A73E8),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF1A73E8),
          tabs: const [
            Tab(text: '全部'),
            Tab(text: '待接诊'),
            Tab(text: '进行中'),
            Tab(text: '已完成'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList('all'),
                _buildList('pending'),
                _buildList('active'),
                _buildList('completed'),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/consultation/type-select'),
        icon: const Icon(Icons.add),
        label: const Text('发起问诊'),
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildList(String key) {
    final items = _data[key] ?? [];
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('暂无${_emptyLabel(key)}', style: TextStyle(color: Colors.grey[500], fontSize: 15)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/consultation/type-select'),
              child: const Text('发起问诊'),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        itemBuilder: (_, i) => _buildCard(items[i]),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    final status = item['status'] as String? ?? '';
    final type = item['type'] as String? ?? 'text';
    final typeLabel = {'text': '图文', 'phone': '电话', 'video': '视频'}[type] ?? type;
    final doctorName = item['doctor_name'] as String? ?? '待分配医生';
    final complaint = item['main_complaint'] as String? ?? '';
    final createdAt = item['created_at'] as String? ?? '';
    final date = createdAt.length >= 16 ? createdAt.substring(0, 16) : createdAt;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.pushNamed(context, '/consultation/chat',
            arguments: {'consultation_id': item['id']?.toString() ?? ''},
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFFE8F0FE),
                    child: Text(doctorName.isNotEmpty ? doctorName[0] : '?',
                      style: const TextStyle(color: Color(0xFF1A73E8), fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(doctorName,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        Text('$typeLabel咨询 · $date',
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  _statusChip(status),
                ],
              ),
              if (complaint.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(complaint,
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    Color color;
    String label;
    switch (status) {
      case 'pending':
        color = const Color(0xFFE6A23C);
        label = '待接诊';
        break;
      case 'active':
      case 'in_progress':
        color = const Color(0xFF34A853);
        label = '进行中';
        break;
      case 'completed':
      case 'rated':
        color = Colors.grey;
        label = '已完成';
        break;
      case 'cancelled':
        color = const Color(0xFFDB4437);
        label = '已取消';
        break;
      default:
        color = Colors.grey;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500)),
    );
  }

  String _emptyLabel(String key) {
    switch (key) {
      case 'pending': return '待接诊的问诊';
      case 'active': return '进行中的问诊';
      case 'completed': return '已完成的问诊';
      default: return '问诊记录';
    }
  }
}
