import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../../main.dart';

/// 处方查看页 — 患者端查看医生开具的电子处方
class PrescriptionViewPage extends StatefulWidget {
  const PrescriptionViewPage({super.key});

  @override
  State<PrescriptionViewPage> createState() => _PrescriptionViewPageState();
}

class _PrescriptionViewPageState extends State<PrescriptionViewPage> {
  String _consultationId = '';
  Map<String, dynamic>? _prescription;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        _consultationId = args['consultation_id'] as String? ?? '';
        _loadPrescription();
      }
    });
  }

  Future<void> _loadPrescription() async {
    if (_consultationId.isEmpty) return;
    
    final appState = context.read<AppState>();
    final token = appState.token;
    
    try {
      final res = await http.get(
        Uri.parse('/api/consultations/$_consultationId/prescription'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));
      
      final data = jsonDecode(res.body);
      
      if (!mounted) return;
      if (data['success'] == true && data['data'] != null) {
        final p = data['data'] as Map<String, dynamic>;
        setState(() {
          _prescription = p;
          // 处方明细可能在 prescription_items 或 items 字段
          _items = ((p['items'] ?? p['prescription_items'] ?? []) as List)
              .cast<Map<String, dynamic>>();
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint('加载处方失败: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return '—';
    return date.toString().substring(0, 10);
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'active': return '有效';
      case 'dispensed': return '已取药';
      case 'cancelled': return '已作废';
      default: return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active': return const Color(0xFF34A853);
      case 'dispensed': return const Color(0xFF1A73E8);
      case 'cancelled': return Colors.grey;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('电子处方'),
        actions: [
          if (_prescription != null)
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: '分享处方',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('处方分享功能开发中')),
                );
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _prescription == null
              ? _buildNoPrescription()
              : _buildPrescriptionContent(),
    );
  }

  Widget _buildNoPrescription() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('暂无处方', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
          const SizedBox(height: 8),
          Text('医生完成问诊后如有需要会开具处方',
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionContent() {
    final p = _prescription!;
    final status = p['status'] as String? ?? 'active';
    final doctorName = p['doctor_name'] as String? ?? '医生';
    final diagnosis = p['diagnosis'] as String? ?? '';
    final notes = p['notes'] as String? ?? p['doctor_notes'] as String? ?? '';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 头部
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('处方笺', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor(status).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _statusLabel(status),
                        style: TextStyle(color: _statusColor(status), fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _buildInfoRow('处方编号', p['prescription_no'] ?? p['id'] ?? ''),
                _buildInfoRow('开具医生', doctorName),
                _buildInfoRow('开具日期', _formatDate(p['created_at'] ?? p['prescribed_at'])),
                if (p['hospital'] != null)
                  _buildInfoRow('医院', p['hospital']),
              ],
            ),
          ),
        ),
        if (diagnosis.isNotEmpty) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('诊断结果', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(diagnosis, style: const TextStyle(fontSize: 14, height: 1.5)),
                ],
              ),
            ),
          ),
        ],
        // 处方明细
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('药品明细', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    Text('共 ${_items.length} 项',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text('暂无药品信息', style: TextStyle(color: Colors.grey[400])),
                    ),
                  )
                else
                  ..._items.asMap().entries.map((entry) {
                    final i = entry.key;
                    final item = entry.value;
                    return _buildMedicineItem(item, i + 1);
                  }),
              ],
            ),
          ),
        ),
        // 医生备注
        if (notes.isNotEmpty) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('医生嘱咐', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(notes, style: TextStyle(color: Colors.grey[700], fontSize: 14, height: 1.5)),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        // 底部提示
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFE37400)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '本处方仅作为医生建议，请凭处方到药店或医院购买药品。\n用药请遵医嘱，如有不适请及时就医。',
                  style: TextStyle(color: Colors.grey[700], fontSize: 12, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineItem(Map<String, dynamic> item, int index) {
    final name = item['drug_name'] as String? ?? item['name'] as String? ?? '药品$index';
    final spec = item['specification'] as String? ?? '';
    final dosage = item['dosage'] as String? ?? item['usage'] as String? ?? '';
    final frequency = item['frequency'] as String? ?? '';
    final days = item['days'] as int? ?? item['duration_days'] as int?;
    final quantity = item['quantity'] as int? ?? item['total_quantity'] as int?;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF1A73E8).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text('$index', style: const TextStyle(color: Color(0xFF1A73E8), fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                if (spec.isNotEmpty)
                  Text(spec, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                if (dosage.isNotEmpty || frequency.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      [
                        if (dosage.isNotEmpty) '每次 $dosage',
                        if (frequency.isNotEmpty) frequency,
                        if (days != null) '服用 $days 天',
                        if (quantity != null) '共 $quantity',
                      ].join('，'),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
