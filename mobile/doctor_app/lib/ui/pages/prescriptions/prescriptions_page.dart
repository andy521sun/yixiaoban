import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:doctor_app/core/providers/doctor_state.dart';

/// 医生端处方列表
class DoctorPrescriptionsPage extends StatefulWidget {
  const DoctorPrescriptionsPage({super.key});

  @override
  State<DoctorPrescriptionsPage> createState() => _DoctorPrescriptionsPageState();
}

class _DoctorPrescriptionsPageState extends State<DoctorPrescriptionsPage> {
  List<dynamic> _prescriptions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final state = context.read<DoctorAppState>();
    final res = await state.api.getMyPrescriptions(pageSize: 50);
    if (!mounted) return;
    if (res['success'] == true) {
      setState(() {
        _prescriptions = res['data'] ?? [];
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('处方记录'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _prescriptions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.description_outlined, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text('暂无处方记录', style: TextStyle(color: Colors.grey[500], fontSize: 15)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _prescriptions.length,
                    itemBuilder: (_, i) => _buildCard(_prescriptions[i]),
                  ),
                ),
    );
  }

  Widget _buildCard(dynamic item) {
    final p = item as Map<String, dynamic>;
    final patientName = p['patient_name'] as String? ?? '未知';
    final diagnosis = p['diagnosis'] as String? ?? '';
    final createdAt = p['created_at'] as String? ?? '';
    final date = createdAt.length >= 16 ? createdAt.substring(0, 16).replaceFirst('T', ' ') : createdAt;
    final drugCount = p['drug_count'] ?? p['items'] != null ? (p['items'] as List?)?.length ?? 0 : 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.pushNamed(context, '/prescription/detail',
            arguments: {'prescription_id': p['id']?.toString() ?? ''},
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F0FE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.description, color: Color(0xFF1A73E8), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('患者: $patientName',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        Text(date, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('$drugCount 种药品',
                      style: const TextStyle(color: Color(0xFF34A853), fontSize: 11),
                    ),
                  ),
                ],
              ),
              if (diagnosis.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(diagnosis,
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
