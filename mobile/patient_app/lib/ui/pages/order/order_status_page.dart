import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderStatusPage extends StatefulWidget {
  final Map<String, dynamic>? arguments;
  
  const OrderStatusPage({Key? key, this.arguments}) : super(key: key);
  
  @override
  _OrderStatusPageState createState() => _OrderStatusPageState();
}

class _OrderStatusPageState extends State<OrderStatusPage> {
  late bool _paymentSuccess;
  late String _orderId;
  late DateTime _orderTime;
  double _orderAmount = 229.0;
  
  // 订单状态时间线
  final List<Map<String, dynamic>> _orderTimeline = [
    {
      'status': 'created',
      'title': '订单创建',
      'description': '订单已成功创建',
      'time': '刚刚',
      'completed': true,
    },
    {
      'status': 'paid',
      'title': '支付成功',
      'description': '订单支付已完成',
      'time': '刚刚',
      'completed': true,
    },
    {
      'status': 'confirmed',
      'title': '订单确认',
      'description': '陪诊师已确认接单',
      'time': '预计5分钟内',
      'completed': false,
    },
    {
      'status': 'in_progress',
      'title': '服务开始',
      'description': '陪诊师已开始服务',
      'time': '按预约时间',
      'completed': false,
    },
    {
      'status': 'completed',
      'title': '服务完成',
      'description': '陪诊服务已完成',
      'time': '服务结束后',
      'completed': false,
    },
  ];
  
  @override
  void initState() {
    super.initState();
    
    // 从参数或模拟数据初始化
    _paymentSuccess = widget.arguments?['payment_success'] ?? true;
    _orderId = widget.arguments?['order_id'] ?? 'ORD${DateTime.now().millisecondsSinceEpoch}';
    _orderTime = DateTime.now();
    
    if (_paymentSuccess) {
      // 支付成功，更新时间线
      _orderTimeline[1]['completed'] = true;
      _orderTimeline[1]['time'] = '刚刚';
    }
  }
  
  void _contactCustomerService() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('联系客服'),
        content: const Text(
          '客服电话: 400-123-4567\n'
          '服务时间: 每天 8:00-22:00\n'
          '微信客服: yixiaoban_kefu\n'
          '邮箱: service@yixiaoban.com',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // 这里可以跳转到电话拨打或微信
            },
            child: const Text('拨打客服电话'),
          ),
        ],
      ),
    );
  }
  
  void _viewOrderDetails() {
    Navigator.pushNamed(
      context,
      '/order/detail',
      arguments: {'order_id': _orderId},
    );
  }
  
  void _goToHomePage() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/home',
      (route) => false,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('订单状态'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 支付状态卡片
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Icon(
                      _paymentSuccess ? Icons.check_circle : Icons.error,
                      color: _paymentSuccess ? Colors.green : Colors.orange,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _paymentSuccess ? '支付成功！' : '支付处理中',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _paymentSuccess
                          ? '您的订单已支付成功，陪诊师将尽快确认'
                          : '支付正在处理中，请稍候...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // 订单信息
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          _buildOrderInfoRow('订单号', _orderId),
                          const SizedBox(height: 8),
                          _buildOrderInfoRow(
                            '下单时间',
                            DateFormat('yyyy-MM-dd HH:mm:ss').format(_orderTime),
                          ),
                          const SizedBox(height: 8),
                          _buildOrderInfoRow(
                            '支付金额',
                            '¥${_orderAmount.toStringAsFixed(2)}',
                            isAmount: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 订单状态时间线
            Text(
              '订单进度',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Column(
              children: _orderTimeline.asMap().entries.map((entry) {
                final index = entry.key;
                final step = entry.value;
                final isLast = index == _orderTimeline.length - 1;
                
                return _buildTimelineStep(
                  step: step,
                  isLast: isLast,
                  index: index,
                );
              }).toList(),
            ),
            
            const SizedBox(height: 24),
            
            // 下一步提示
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '下一步',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '1. 陪诊师将在5分钟内确认接单\n'
                      '2. 确认后您会收到短信通知\n'
                      '3. 服务开始前1小时会再次提醒\n'
                      '4. 服务过程中可通过APP实时联系陪诊师',
                      style: TextStyle(
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 温馨提示
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: Colors.orange[700]),
                        const SizedBox(width: 8),
                        Text(
                          '温馨提示',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '• 请提前准备好就诊所需证件和资料\n'
                      '• 建议提前15分钟到达医院\n'
                      '• 如有特殊需求，请提前联系陪诊师\n'
                      '• 服务完成后请及时评价，帮助其他用户选择\n'
                      '• 如需取消或改期，请至少提前2小时联系',
                      style: TextStyle(
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
      
      // 底部操作栏
      bottomNavigationBar: _buildBottomBar(),
    );
  }
  
  Widget _buildOrderInfoRow(String label, String value, {bool isAmount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isAmount ? FontWeight.bold : FontWeight.normal,
            color: isAmount ? Colors.red : Colors.black,
            fontSize: isAmount ? 16 : 14,
          ),
        ),
      ],
    );
  }
  
  Widget _buildTimelineStep({
    required Map<String, dynamic> step,
    required bool isLast,
    required int index,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 时间线连接线
        Column(
          children: [
            // 上方的点
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: step['completed'] ? Colors.blue : Colors.grey.shade300,
                shape: BoxShape.circle,
                border: Border.all(
                  color: step['completed'] ? Colors.blue : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: step['completed']
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            
            // 连接线（如果不是最后一项）
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                color: step['completed'] ? Colors.blue : Colors.grey.shade300,
              ),
          ],
        ),
        
        const SizedBox(width: 16),
        
        // 步骤内容
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step['title'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: step['completed'] ? Colors.blue : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  step['description'],
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  step['time'],
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildBottomBar() {
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
          // 查看订单详情按钮
          Expanded(
            child: OutlinedButton(
              onPressed: _viewOrderDetails,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                side: const BorderSide(color: Colors.blue),
              ),
              child: const Text(
                '查看订单详情',
                style: TextStyle(
                  color: Colors.blue,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // 联系客服按钮
          Expanded(
            child: OutlinedButton(
              onPressed: _contactCustomerService,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                side: BorderSide(color: Colors.grey.shade300!),
              ),
              child: Text(
                '联系客服',
                style: TextStyle(
                  color: Colors.grey[700],
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // 返回首页按钮
          Expanded(
            child: ElevatedButton(
              onPressed: _goToHomePage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('返回首页'),
            ),
          ),
        ],
      ),
    );
  }
}