import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:doctor_app/core/providers/doctor_state.dart';

/// 医生端问诊列表 — 待接诊/进行中/已完成 Tab
class DoctorConsultationListPage extends StatefulWidget {
  const DoctorConsultationListPage({super.key});

  @override
  State<DoctorConsultationListPage> createState() => _DoctorConsultationListPageState();
}

class _DoctorConsultationListPageState extends State<DoctorConsultationListPage> {
  int _tabIndex = 0;
  List<Map<String, dynamic>> _consultations = [];
  bool _loading = true;

  final _tabs = ['待接诊', '进行中', '已完成'];

  @override
  void initState() {
    super.initState();
    _loadConsultations();
  }

  Future<void> _loadConsultations() async {
    setState(() => _loading = true);
    final state = context.read<DoctorAppState>();

    if (!state.isCertified) {
      setState(() => _loading = false);
      return;
    }

    List<String> statusParams;
    switch (_tabIndex) {
      case 0: statusParams = ['pending'];
      case 1: statusParams = ['active', 'in_progress'];
      case 2: statusParams = ['completed', 'cancelled', 'rated'];
      default: statusParams = [];
    }

    List<dynamic> all = [];
    for (final s in statusParams) {
      final items = await state.api.getConsultations(status: s);
      all.addAll(items);
    }

    if (!mounted) return;
    setState(() {
      _consultations = all.cast<Map<String, dynamic>>();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DoctorAppState>();

    return Scaffold(
      appBar: AppBar(
        title: Text('${state.doctorName}医生', style: const TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          if (!state.isCertified)
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/certification'),
              child: Text('认证入驻', style: TextStyle(color: state.certStatus == 'pending' ? Colors.orange : const Color(0xFF1A73E8))),
            ),
        ],
      ),
      body: !state.isCertified
          ? _buildNotCertified(state)
          : Column(
              children: [
                // Tab
                Container(
                  color: Colors.white,
                  child: Row(
                    children: _tabs.asMap().entries.map((entry) {
                      final i = entry.key;
                      final label = entry.value;
                      final selected = _tabIndex == i;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _tabIndex = i);
                            _loadConsultations();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: selected ? const Color(0xFF1A73E8) : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Text(
                              label,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: selected ? const Color(0xFF1A73E8) : Colors.grey[600],
                                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                // 列表
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _consultations.isEmpty
                          ? _buildEmpty()
                          : RefreshIndicator(
                              onRefresh: _loadConsultations,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _consultations.length,
                                itemBuilder: (_, i) => _buildConsultationCard(_consultations[i]),
                              ),
                            ),
                ),
              ],
            ),
    );
  }

  Widget _buildNotCertified(DoctorAppState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified_user_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            state.certStatus == 'pending' ? '认证审核中...' : '请先完成医生认证',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            state.certStatus == 'pending' ? '您的入驻资料正在审核中' : '认证后方可接诊',
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
          const SizedBox(height: 24),
          if (state.certStatus == 'unsubmitted' || state.certStatus == 'rejected')
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/certification'),
              child: const Text('立即认证'),
            ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('暂无${_tabs[_tabIndex]}问诊', style: TextStyle(color: Colors.grey[500], fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildConsultationCard(Map<String, dynamic> item) {
    final patientName = item['patient_name'] as String? ?? '患者';
    final type = item['type'] as String? ?? 'text';
    final status = item['status'] as String? ?? '';
    final mainComplaint = item['main_complaint'] as String? ?? '';
    final createdAt = item['created_at'] as String? ?? '';

    String typeLabel, typeIcon;
    switch (type) {
      case 'phone': typeLabel = '电话'; typeIcon = '📞';
      case 'video': typeLabel = '视频'; typeIcon = '📹';
      default: typeLabel = '图文'; typeIcon = '💬';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.pushNamed(context, '/consultation/chat', arguments: {'consultation_id': item['id']});
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFF1A73E8).withValues(alpha: 0.1),
                    child: Text(patientName[0], style: const TextStyle(color: Color(0xFF1A73E8), fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(patientName, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(createdAt.isNotEmpty ? createdAt.substring(0, 16) : '',
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F0FE),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('$typeIcon $typeLabel', style: const TextStyle(fontSize: 11, color: Color(0xFF1A73E8))),
                  ),
                ],
              ),
              if (mainComplaint.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(mainComplaint, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
              ],
              if (status == 'pending') ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      ),
                      child: const Text('拒绝', style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () async {
                        final state = context.read<DoctorAppState>();
                        final res = await state.api.acceptConsultation(item['id'] as String);
                        if (res['success'] == true) _loadConsultations();
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                      child: const Text('接诊'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
