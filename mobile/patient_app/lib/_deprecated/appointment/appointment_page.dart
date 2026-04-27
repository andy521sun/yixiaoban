import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../main.dart';
import '../../../core/services/api_service.dart';

class AppointmentPage extends StatefulWidget {
  const AppointmentPage({super.key});

  @override
  State<AppointmentPage> createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  final _api = ApiService();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController(text: '09:00');
  final _durationController = TextEditingController(text: '120');
  bool _loading = false;
  String? _result;

  String _serviceType = '普通陪诊';
  final _serviceTypes = ['普通陪诊', '专业陪诊', '急诊陪诊', '长期陪护'];

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date != null) {
      _dateController.text = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _submit() async {
    final appState = context.read<AppState>();
    if (!appState.loggedIn) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请先登录再预约')),
        );
        Navigator.pushNamed(context, '/login');
      }
      return;
    }

    setState(() { _loading = true; _result = null; });

    final orderData = {
      'user_id': 'patient_001',
      'patient_id': 'patient_001',
      'service_type': _serviceType,
      'appointment_date': _dateController.text,
      'appointment_time': '${_timeController.text}:00',
      'hospital_id': 'hosp_001',
      'duration_minutes': int.tryParse(_durationController.text) ?? 120,
      'total_amount': _serviceType == '普通陪诊' ? 199.0 : _serviceType == '专业陪诊' ? 299.0 : 399.0,
      'status': 'pending',
      'payment_status': 'unpaid',
    };

    final result = await _api.createOrder(orderData, mock: 'true');

    if (!mounted) return;
    setState(() { _loading = false; _result = result['success'] == true ? '预约成功！订单号: ${result['order_id']}' : '预约失败: ${result['message']}'; });
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final hospitalName = args?['hospital_name'] ?? '未选择医院';

    return Scaffold(
      appBar: AppBar(title: const Text('预约陪诊')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 预约医院
            Card(
              child: ListTile(
                leading: const Icon(Icons.local_hospital, color: Color(0xFF1A73E8)),
                title: const Text('预约医院'),
                subtitle: Text(hospitalName),
              ),
            ),
            const SizedBox(height: 16),

            // 服务类型
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('服务类型', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _serviceTypes.map((t) {
                        final selected = t == _serviceType;
                        return ChoiceChip(
                          label: Text(t),
                          selected: selected,
                          onSelected: (v) => setState(() => _serviceType = t),
                          selectedColor: const Color(0xFF1A73E8).withOpacity(0.15),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 日期和时间
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('预约时间', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _dateController,
                      decoration: const InputDecoration(
                        labelText: '选择日期',
                        prefixIcon: Icon(Icons.calendar_today),
                        suffixIcon: Icon(Icons.arrow_drop_down),
                      ),
                      readOnly: true,
                      onTap: _pickDate,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _timeController,
                            decoration: const InputDecoration(
                              labelText: '时间',
                              prefixIcon: Icon(Icons.access_time),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _durationController,
                            decoration: const InputDecoration(
                              labelText: '时长(分钟)',
                              prefixIcon: Icon(Icons.timer),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 费用预览
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('费用预览', style: TextStyle(fontWeight: FontWeight.w600)),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_serviceType, style: TextStyle(color: Colors.grey[600])),
                        Text('¥$_serviceType' == '普通陪诊' ? '¥199' : _serviceType == '专业陪诊' ? '¥299' : '¥399'),
                      ],
                    ),
                    const Divider(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('合计', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                        Text('¥199', style: TextStyle(color: Color(0xFF1A73E8), fontWeight: FontWeight.w600, fontSize: 18)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            if (_result != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _result!.contains('成功') ? const Color(0xFF34A853).withOpacity(0.1) : const Color(0xFFDB4437).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _result!.contains('成功') ? Icons.check_circle : Icons.error,
                      color: _result!.contains('成功') ? const Color(0xFF34A853) : const Color(0xFFDB4437),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_result!, style: TextStyle(fontSize: 13, color: _result!.contains('成功') ? const Color(0xFF34A853) : const Color(0xFFDB4437)))),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('提交预约'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
