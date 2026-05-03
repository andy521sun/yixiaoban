import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:doctor_app/core/providers/doctor_state.dart';

/// 医生端处方详情
class DoctorPrescriptionDetailPage extends StatefulWidget {
  const DoctorPrescriptionDetailPage({super.key});

  @override
  State<DoctorPrescriptionDetailPage> createState() => _DoctorPrescriptionDetailPageState();
}

class _DoctorPrescriptionDetailPageState extends State<DoctorPrescriptionDetailPage> {
  Map<String, dynamic>? _prescription;
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final id = args?['prescription_id'] as String? ?? '';
    _load(id);
  }

  Future<void> _load(String id) async {
    if (id.isEmpty) return;
    final state = context.read<DoctorAppState>();
    final res = await state.api.getPrescriptionDetail(id);
    if (!mounted) return;
    setState(() {
      _prescription = res?['prescription'] as Map<String, dynamic>?;
      _items = (res?['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('处方详情')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _prescription == null
              ? const Center(child: Text('处方不存在'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoCard(),
                      const SizedBox(height: 16),
                      if (_items.isNotEmpty) _buildItemsCard(),
                      const SizedBox(height: 16),
                      if (_prescription?['notes'] != null && (_prescription!['notes'] as String).isNotEmpty)
                        _buildNotesCard(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoCard() {
    final p = _prescription!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A73E8).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('处方信息', style: TextStyle(color: Color(0xFF1A73E8), fontWeight: FontWeight.w600, fontSize: 13)),
                ),
                const Spacer(),
                Text('#${p['id']}', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),
            _infoRow('患者', p['patient_name'] as String? ?? ''),
            _infoRow('诊断', p['diagnosis'] as String? ?? ''),
            _infoRow('开具时间', (p['created_at'] as String? ?? '').substring(0, 16).replaceFirst('T', ' ')),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF34A853).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('药品清单', style: TextStyle(color: Color(0xFF34A853), fontWeight: FontWeight.w600, fontSize: 13)),
            ),
            const SizedBox(height: 12),
            ..._items.map((item) => _buildDrugItem(item as Map<String, dynamic>)),
          ],
        ),
      ),
    );
  }

  Widget _buildDrugItem(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 8, height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF1A73E8),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['drug_name'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  '${item['specification'] ?? ''}  ${item['dosage'] ?? ''}  ${item['frequency'] ?? ''}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                Text(
                  '${item['duration_days'] ?? ''}天  共${item['total_quantity'] ?? ''}${item['unit'] ?? '份'}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('医生嘱咐', style: TextStyle(color: Color(0xFFE6A23C), fontWeight: FontWeight.w600, fontSize: 13)),
            ),
            const SizedBox(height: 12),
            Text(_prescription!['notes'] as String? ?? '', style: const TextStyle(fontSize: 14, height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
