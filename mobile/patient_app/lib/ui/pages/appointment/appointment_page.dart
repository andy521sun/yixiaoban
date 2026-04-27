import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../main.dart';
import '../../../core/services/api_service.dart';


/// 预约陪诊页面
/// 三步流程：选择服务 → 填写信息 → 确认支付
class AppointmentPage extends StatefulWidget {
  const AppointmentPage({super.key});

  @override
  State<AppointmentPage> createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  final _api = ApiService();
  final _pageController = PageController();
  int _currentStep = 0;

  // 步骤1：选择服务
  String _serviceType = '普通陪诊';
  final _serviceTypes = [
    {'name': '普通陪诊', 'desc': '挂号、取药、缴费陪同', 'price': 199},
    {'name': '专业陪诊', 'desc': '检查、化验、报告解读', 'price': 299},
    {'name': '急诊陪诊', 'desc': '急诊全程陪同协助', 'price': 399},
    {'name': '长期陪护', 'desc': '多次陪诊+健康管理', 'price': 599},
  ];

  // 步骤2：填写信息
  final _dateController = TextEditingController();
  final _timeController = TextEditingController(text: '09:00');
  final _durationController = TextEditingController(text: '120');
  final _symptomController = TextEditingController();
  final _noteController = TextEditingController();
  String? _selectedHospital;
  String? _selectedHospitalId;

  // 步骤3：确认
  bool _loading = false;
  String? _orderResult;

  // 缓存
  List<dynamic> _hospitals = [];

  int get _price {
    final found = _serviceTypes.firstWhere(
      (s) => s['name'] == _serviceType,
      orElse: () => {'price': 199},
    );
    return found['price'] as int;
  }

  double get _hours => (int.tryParse(_durationController.text) ?? 120) / 60;

  @override
  void dispose() {
    _pageController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _durationController.dispose();
    _symptomController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadHospitals();
  }

  Future<void> _loadHospitals() async {
    final hospitals = await _api.getHospitals();
    if (mounted) {
      setState(() => _hospitals = hospitals);
    }
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

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (time != null) {
      _timeController.text = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  bool get _canGoNext {
    if (_currentStep == 0) return true; // 服务类型始终可选
    if (_currentStep == 1) {
      return _dateController.text.isNotEmpty &&
          _timeController.text.isNotEmpty &&
          _selectedHospital != null;
    }
    return true;
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submitOrder() async {
    final appState = context.read<AppState>();
    if (!appState.loggedIn) {
      _showMsg('请先登录再预约');
      Navigator.pushNamed(context, '/login');
      return;
    }

    _api.setToken(appState.token);
    setState(() {
      _loading = true;
      _orderResult = null;
    });

    final orderData = {
      'hospital_id': _selectedHospitalId ?? 'hosp_001',
      'appointment_date': _dateController.text,
      'appointment_time': '${_timeController.text}:00',
      'service_type': _serviceType,
      'service_hours': _hours,
      'symptoms_description': _symptomController.text,
      'special_requirements': _noteController.text,
      'total_amount': _price.toDouble(),
    };

    final result = await _api.createOrder(orderData);

    if (!mounted) return;
    setState(() => _loading = false);

    if (result['success'] == true) {
      final orderId = result['data']?['order_no'] ?? result['order_no'] ?? '';
      _orderResult = '预约成功!';
      _showMsg('预约成功！准备跳转支付...');

      // 跳转到支付
      if (orderId.isNotEmpty) {
        Navigator.pushNamed(context, '/order/detail', arguments: {
          'id': orderId,
          'status': 'pending',
          'hospital_name': _selectedHospital ?? '',
          'service_type': _serviceType,
          'price': _price,
          'appointment_date': _dateController.text,
          'appointment_time': _timeController.text,
          'duration_minutes': int.tryParse(_durationController.text) ?? 120,
          'payment_status': 'unpaid',
        });
      }
    } else {
      _orderResult = '预约失败: ${result['message']}';
    }
  }

  void _showMsg(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('预约陪诊'),
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _prevStep,
              )
            : null,
      ),
      body: Column(
        children: [
          // 步骤指示器
          _buildStepIndicator(),
          // 页面内容
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildServiceSelection(),
                _buildFormPage(),
                _buildConfirmPage(),
              ],
            ),
          ),
          // 底部按钮
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    final steps = ['选择服务', '填写信息', '确认下单'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      color: Colors.white,
      child: Row(
        children: List.generate(steps.length, (i) {
          final active = i == _currentStep;
          final done = i < _currentStep;
          return Expanded(
            child: Row(
              children: [
                // 圆点
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done
                        ? const Color(0xFF34A853)
                        : active
                            ? const Color(0xFF1A73E8)
                            : Colors.grey[300],
                  ),
                  child: Center(
                    child: done
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : Text('${i + 1}',
                            style: TextStyle(
                              color: active ? Colors.white : Colors.grey[600],
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            )),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  steps[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                    color: active ? const Color(0xFF1A73E8) : Colors.grey[500],
                  ),
                ),
                if (i < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(left: 8),
                      color: done
                          ? const Color(0xFF34A853)
                          : Colors.grey[200],
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ==================== 步骤1：选择服务 ====================
  Widget _buildServiceSelection() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('选择服务类型',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text('根据需求选择合适的陪诊服务',
            style: TextStyle(color: Colors.grey[500], fontSize: 14)),
        const SizedBox(height: 16),
        ..._serviceTypes.map((s) {
          final selected = s['name'] == _serviceType;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: selected ? const Color(0xFF1A73E8) : const Color(0xFFE8EAED),
                width: selected ? 2 : 1,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() => _serviceType = s['name'] as String),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Radio<String>(
                      value: s['name'] as String,
                      groupValue: _serviceType,
                      onChanged: (v) => setState(() => _serviceType = v!),
                      activeColor: const Color(0xFF1A73E8),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s['name'] as String,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 16)),
                          const SizedBox(height: 2),
                          Text(s['desc'] as String,
                              style: TextStyle(
                                  color: Colors.grey[500], fontSize: 13)),
                        ],
                      ),
                    ),
                    Text(
                      '¥${s['price']}',
                      style: const TextStyle(
                        color: Color(0xFF1A73E8),
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ==================== 步骤2：填写信息 ====================
  Widget _buildFormPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('填写预约信息',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),

        // 选择医院
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('选择医院', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedHospital,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.local_hospital),
                  ),
                  hint: const Text('请选择医院'),
                  items: _hospitals.map<DropdownMenuItem<String>>((h) {
                    return DropdownMenuItem(
                      value: h['name'] as String?,
                      child: Text(h['name'] ?? ''),
                    );
                  }).toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedHospital = v;
                      _selectedHospitalId = _hospitals
                          .firstWhere((h) => h['name'] == v,
                              orElse: () => {'id': ''})['id']
                          as String?;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 日期时间
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
                        readOnly: true,
                        onTap: _pickTime,
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
        const SizedBox(height: 12),

        // 症状描述
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('症状描述（选填）',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: _symptomController,
                  decoration: const InputDecoration(
                    hintText: '简要描述不适症状...',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    hintText: '特殊需求或备注（选填）',
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ==================== 步骤3：确认 ====================
  Widget _buildConfirmPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('确认预约信息',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),

        // 服务汇总
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('服务信息', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const Divider(),
                _confirmRow('服务类型', _serviceType),
                _confirmRow('医　　院', _selectedHospital ?? ''),
                _confirmRow('预约日期', _dateController.text),
                _confirmRow('预约时间', _timeController.text),
                _confirmRow('服务时长', '${_durationController.text}分钟'),
                if (_symptomController.text.isNotEmpty)
                  _confirmRow('症状描述', _symptomController.text),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 费用汇总
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('费用明细', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const Divider(),
                _confirmRow('服务费', '¥$_price'),
                _confirmRow('平台服务费', '¥${(_price * 0.15).round()}'),
                const Divider(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('合计', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(
                      '¥${(_price * 1.15).round()}',
                      style: const TextStyle(
                        color: Color(0xFF1A73E8),
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        if (_orderResult != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _orderResult!.contains('成功')
                  ? const Color(0xFF34A853).withValues(alpha: 0.1)
                  : const Color(0xFFDB4437).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _orderResult!.contains('成功')
                      ? Icons.check_circle
                      : Icons.error,
                  color: _orderResult!.contains('成功')
                      ? const Color(0xFF34A853)
                      : const Color(0xFFDB4437),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(_orderResult!, style: TextStyle(fontSize: 13))),
              ],
            ),
          ),
        ],

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _confirmRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  // ==================== 底部按钮 ====================
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE8EAED))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _prevStep,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('上一步'),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),
            Expanded(
              flex: _currentStep > 0 ? 1 : 2,
              child: ElevatedButton(
                onPressed: (_loading || !_canGoNext)
                    ? null
                    : (_currentStep < 2 ? _nextStep : _submitOrder),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(_currentStep < 2 ? '下一步' : '提交预约'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
