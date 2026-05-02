import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/doctor_state.dart';

/// 医生端服务价格设置页 — 图文/电话/视频咨询价格配置
class ServicePricingPage extends StatefulWidget {
  const ServicePricingPage({super.key});

  @override
  State<ServicePricingPage> createState() => _ServicePricingPageState();
}

class _ServicePricingPageState extends State<ServicePricingPage> {
  final _textPriceCtrl = TextEditingController();
  final _phonePriceCtrl = TextEditingController();
  final _videoPriceCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadPricing();
  }

  @override
  void dispose() {
    _textPriceCtrl.dispose();
    _phonePriceCtrl.dispose();
    _videoPriceCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPricing() async {
    final state = context.read<DoctorAppState>();
    final res = await state.api.getServicePricing();
    if (!mounted) return;
    if (res['success'] == true && res['data'] != null) {
      final data = res['data'] as Map<String, dynamic>;
      _textPriceCtrl.text = (data['text_price'] as num?)?.toStringAsFixed(1) ?? '19.9';
      _phonePriceCtrl.text = (data['phone_price'] as num?)?.toStringAsFixed(1) ?? '39.9';
      _videoPriceCtrl.text = (data['video_price'] as num?)?.toStringAsFixed(1) ?? '59.9';
    } else {
      _textPriceCtrl.text = '19.9';
      _phonePriceCtrl.text = '39.9';
      _videoPriceCtrl.text = '59.9';
    }
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    final textPrice = double.tryParse(_textPriceCtrl.text.trim());
    final phonePrice = double.tryParse(_phonePriceCtrl.text.trim());
    final videoPrice = double.tryParse(_videoPriceCtrl.text.trim());

    if (textPrice == null || phonePrice == null || videoPrice == null) {
      _showSnack('请输入有效的价格');
      return;
    }

    setState(() => _saving = true);
    final state = context.read<DoctorAppState>();
    final res = await state.api.setServicePricing({
      'text_price': textPrice,
      'phone_price': phonePrice,
      'video_price': videoPrice,
    });

    if (!mounted) return;
    setState(() => _saving = false);

    if (res['success'] == true) {
      _showSnack('价格已保存');
      Navigator.pop(context);
    } else {
      _showSnack(res['message'] as String? ?? '保存失败');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('服务价格设置')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('咨询类型', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 16),
                        _buildPriceField('💬  图文咨询', '图文咨询价格（元）', _textPriceCtrl),
                        const Divider(height: 24),
                        _buildPriceField('📞  电话咨询', '电话咨询价格（元/15分钟）', _phonePriceCtrl),
                        const Divider(height: 24),
                        _buildPriceField('📹  视频咨询', '视频咨询价格（元/20分钟）', _videoPriceCtrl),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F0FE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: Color(0xFF1A73E8)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '设置的价格将在医生列表中展示给患者，合理定价有助于获得更多问诊机会',
                          style: TextStyle(color: Colors.grey[700], fontSize: 12, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('保存价格', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPriceField(String label, String hint, TextEditingController ctrl) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: ctrl,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: hint,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              prefixText: '¥ ',
            ),
          ),
        ),
      ],
    );
  }
}
