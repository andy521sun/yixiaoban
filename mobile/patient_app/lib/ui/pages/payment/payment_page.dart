import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/appointment_provider.dart';
import '../../../core/services/api_service.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({Key? key}) : super(key: key);

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String _selectedPaymentMethod = 'wechat';
  bool _isPaying = false;
  bool _paymentSuccess = false;
  String _orderId = '';
  double _totalAmount = 0.0;
  
  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'wechat',
      'name': '微信支付',
      'icon': Icons.wechat,
      'color': Colors.green,
      'description': '推荐使用，安全快捷',
    },
    {
      'id': 'alipay',
      'name': '支付宝',
      'icon': Icons.account_balance_wallet,
      'color': Colors.blue,
      'description': '支付宝余额或银行卡支付',
    },
    {
      'id': 'bank_card',
      'name': '银行卡支付',
      'icon': Icons.credit_card,
      'color': Colors.orange,
      'description': '储蓄卡/信用卡支付',
    },
  ];
  
  @override
  void initState() {
    super.initState();
    _loadOrderData();
  }
  
  void _loadOrderData() {
    final appointmentProvider = Provider.of<AppointmentProvider>(context, listen: false);
    _totalAmount = appointmentProvider.calculateEstimatedPrice();
  }
  
  Future<void> _processPayment() async {
    if (_isPaying) return;
    
    setState(() {
      _isPaying = true;
    });
    
    try {
      // 获取预约数据
      final appointmentProvider = Provider.of<AppointmentProvider>(context, listen: false);
      final orderData = appointmentProvider.toMap();
      
      // 添加支付方式
      orderData['payment_method'] = _selectedPaymentMethod;
      orderData['payment_amount'] = _totalAmount;
      
      // 调用API创建订单
      final response = await ApiService().createOrder(orderData);
      
      // 模拟支付过程
      await Future.delayed(const Duration(seconds: 2));
      
      // 支付流程
      final amount = response['amount'] ?? response['total_amount'] ?? _totalAmount;
      final paymentResponse = await ApiService().createPayment(
        response['order_id'] ?? response['data']?['order_no'] ?? '',
        'wechat',
        (amount is int) ? amount.toDouble() : (amount as double),
      );
      if (paymentResponse['success'] == true) {
        // 模拟支付确认
        await ApiService().simulatePayment(
          paymentResponse['data']?['payment_id'] ?? '',
        );
      }
      
      setState(() {
        _isPaying = false;
        _paymentSuccess = true;
        _orderId = response['order_id'];
      });
      
      // 3秒后跳转到订单状态页面
      Future.delayed(const Duration(seconds: 3), () {
        Navigator.pushReplacementNamed(
          context,
          '/order/status',
          arguments: {
            'order_id': _orderId,
            'payment_success': true,
          },
        );
      });
      
    } catch (error) {
      setState(() {
        _isPaying = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('支付失败: $error'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
  
  void _showPaymentHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('支付帮助'),
        content: const Text(
          '1. 微信支付：请确保微信已安装并登录\n'
          '2. 支付宝：请确保支付宝已安装并登录\n'
          '3. 银行卡：支持大部分银行的储蓄卡和信用卡\n'
          '4. 支付成功后，订单将自动确认\n'
          '5. 如有问题，请联系客服：400-123-4567',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('支付订单'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showPaymentHelp,
            tooltip: '支付帮助',
          ),
        ],
      ),
      body: _paymentSuccess ? _buildSuccessView() : _buildPaymentView(),
    );
  }
  
  Widget _buildPaymentView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 订单金额卡片
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Text(
                    '支付金额',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '¥${_totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '医小伴陪诊服务',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 支付方式标题
          Text(
            '选择支付方式',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // 支付方式列表
          Column(
            children: _paymentMethods.map((method) {
              return _buildPaymentMethodCard(method);
            }).toList(),
          ),
          
          const SizedBox(height: 24),
          
          // 支付协议
          Row(
            children: [
              Checkbox(
                value: true,
                onChanged: (value) {
                  // 同意协议逻辑
                },
              ),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodySmall,
                    children: [
                      const TextSpan(text: '我已阅读并同意'),
                      TextSpan(
                        text: '《支付协议》',
                        style: const TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }
  
  Widget _buildPaymentMethodCard(Map<String, dynamic> method) {
    final isSelected = _selectedPaymentMethod == method['id'];
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Colors.blue : Colors.transparent,
          width: isSelected ? 2 : 0,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: method['color'].withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            method['icon'],
            color: method['color'],
            size: 24,
          ),
        ),
        title: Text(
          method['name'],
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(method['description']),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: Colors.blue)
            : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
        onTap: () {
          setState(() {
            _selectedPaymentMethod = method['id'];
          });
        },
      ),
    );
  }
  
  Widget _buildSuccessView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 80,
          ),
          const SizedBox(height: 24),
          const Text(
            '支付成功！',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '订单号: $_orderId',
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '金额: ¥${_totalAmount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          const Text('正在跳转到订单页面...'),
        ],
      ),
    );
  }
  
  Widget _buildBottomBar() {
    if (_paymentSuccess) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 价格显示
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '需支付',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                Text(
                  '¥${_totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
          
          // 支付按钮
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isPaying ? null : _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
              ),
              child: _isPaying
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Text(
                      '立即支付',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget buildWithBottomBar(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('支付订单'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showPaymentHelp,
            tooltip: '支付帮助',
          ),
        ],
      ),
      body: _paymentSuccess ? _buildSuccessView() : _buildPaymentView(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }
}