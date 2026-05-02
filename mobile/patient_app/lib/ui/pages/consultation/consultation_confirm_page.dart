import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../main.dart';

/// 确认问诊页 — 确认医生和信息后发起问诊
class ConsultationConfirmPage extends StatefulWidget {
  const ConsultationConfirmPage({super.key});

  @override
  State<ConsultationConfirmPage> createState() => _ConsultationConfirmPageState();
}

class _ConsultationConfirmPageState extends State<ConsultationConfirmPage> {
  Map<String, dynamic>? _data;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        setState(() => _data = args);
      }
    });
  }

  String get _typeLabel {
    final t = _data?['type'] as String? ?? 'text';
    switch (t) {
      case 'phone': return '电话咨询';
      case 'video': return '视频咨询';
      default: return '图文咨询';
    }
  }

  Future<void> _submitConsultation() async {
    final appState = context.read<AppState>();
    if (!appState.loggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先登录')),
      );
      Navigator.pushNamed(context, '/login');
      return;
    }

    setState(() => _submitting = true);

    final doctor = _data?['doctor'] as Map<String, dynamic>?;
    final symptomData = _data?['symptomData'] as Map<String, dynamic>?;

    // 调用后端 API 发起问诊
    final res = await appState.api.createConsultation({
      'type': _data?['type'] ?? 'text',
      'doctor_id': doctor?['id'] ?? '',
      'main_complaint': symptomData?['main_complaint'] ?? '',
      'symptoms': symptomData?['symptoms'] ?? '',
      'present_illness': symptomData?['present_illness'] ?? '',
      'past_history': symptomData?['past_history'] ?? '',
    });

    if (!mounted) return;
    setState(() => _submitting = false);

    if (res['success'] == true) {
      final consultationId = res['data']?['id'] ?? '';
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/consultation/chat',
        arguments: {'consultation_id': consultationId, 'doctor': doctor},
        (route) => route.settings.name == '/',
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] as String? ?? '提交失败，请重试')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final doctor = _data?['doctor'] as Map<String, dynamic>?;
    final symptomData = _data?['symptomData'] as Map<String, dynamic>?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('确认问诊'),
      ),
      body: _data == null
          ? const Center(child: Text('数据加载中...'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 咨询方式
                _buildSection('问诊方式', [
                  _buildInfoRow(Icons.videocam_rounded, _typeLabel, ''),
                ]),
                const SizedBox(height: 16),

                // 医生信息
                _buildSection('医生信息', [
                  _buildInfoRow(Icons.person, doctor?['name'] ?? '', '${doctor?['title'] ?? ''} · ${doctor?['department'] ?? ''}'),
                  _buildInfoRow(Icons.local_hospital, doctor?['hospital'] ?? '', ''),
                ]),
                const SizedBox(height: 16),

                // 病情描述
                _buildSection('病情描述', [
                  _buildInfoRow(Icons.healing, '主要症状', symptomData?['main_complaint'] ?? ''),
                  if ((symptomData?['symptoms'] as String?)?.isNotEmpty == true)
                    _buildInfoRow(Icons.list_alt, '症状标签', symptomData?['symptoms'] ?? ''),
                  if ((symptomData?['present_illness'] as String?)?.isNotEmpty == true)
                    _buildInfoRow(Icons.medical_information, '现病史', symptomData?['present_illness']),
                  if ((symptomData?['past_history'] as String?)?.isNotEmpty == true)
                    _buildInfoRow(Icons.history, '既往史', symptomData?['past_history']),
                ]),
                const SizedBox(height: 16),

                // 费用预估
                _buildSection('费用预估', [
                  _buildInfoRow(Icons.payments_outlined, _typeLabel, '¥${_getPrice(doctor, _data?['type'] as String? ?? 'text')}'),
                ]),
                const SizedBox(height: 32),

                // 提交按钮
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submitConsultation,
                    child: _submitting
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('确认并支付', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    '支付完成后方可发起问诊',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ),
              ],
            ),
    );
  }

  String _getPrice(Map<String, dynamic>? doctor, String type) {
    if (doctor == null) return '—';
    switch (type) {
      case 'phone': return '${doctor['phone_price'] ?? '—'}';
      case 'video': return '${doctor['video_price'] ?? '—'}';
      default: return '${doctor['text_price'] ?? '—'}';
    }
  }

  Widget _buildSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Column(children: items),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[500]),
          const SizedBox(width: 10),
          SizedBox(
            width: 60,
            child: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
