import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/services/api_service.dart';

class OrderDetailPage extends StatefulWidget {
  final Map<String, dynamic>? arguments;
  
  const OrderDetailPage({Key? key, this.arguments}) : super(key: key);
  
  @override
  _OrderDetailPageState createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  Map<String, dynamic>? _order;
  bool _isLoading = true;
  String? _error;
  
  // 订单状态时间线
  final List<Map<String, dynamic>> _orderTimeline = [];
  
  @override
  void initState() {
    super.initState();
    _loadOrderDetail();
  }
  
  Future<void> _loadOrderDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final orderId = widget.arguments?['order_id'] ?? 'order_001';
      
      // 调用API获取订单详情
      final order = await ApiService().getOrder(orderId);
      
      // 构建时间线
      _buildTimeline(order);
      
      setState(() {
        _order = order;
        _isLoading = false;
      });
    } catch (error) {
      print('加载订单详情失败: $error');
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }
  
  void _buildTimeline(Map<String, dynamic> order) {
    _orderTimeline.clear();
    
    final createdAt = DateTime.parse(order['created_at']);
    
    // 订单创建
    _orderTimeline.add({
      'status': 'created',
      'title': '订单创建',
      'description': '订单已成功创建',
      'time': createdAt,
      'completed': true,
    });
    
    // 支付状态
    if (order['payment_status'] == 'paid') {
      final paymentTime = createdAt.add(const Duration(minutes: 1));
      
      _orderTimeline.add({
        'status': 'paid',
        'title': '支付成功',
        'description': '订单支付已完成',
        'time': paymentTime,
        'completed': true,
      });
    }
    
    // 订单确认
    if (order['status'] == 'confirmed' || 
        order['status'] == 'in_progress' || 
        order['status'] == 'completed') {
      final confirmedTime = createdAt.add(const Duration(minutes: 5));
      
      _orderTimeline.add({
        'status': 'confirmed',
        'title': '订单确认',
        'description': '陪诊师已确认接单',
        'time': confirmedTime,
        'completed': true,
      });
    }
    
    // 服务开始
    if (order['status'] == 'in_progress' || order['status'] == 'completed') {
      final startTime = createdAt.add(const Duration(hours: 1));
      
      _orderTimeline.add({
        'status': 'in_progress',
        'title': '服务开始',
        'description': '陪诊师已开始服务',
        'time': startTime,
        'completed': true,
      });
    }
    
    // 服务完成
    if (order['status'] == 'completed') {
      final completedTime = createdAt.add(const Duration(hours: 3));
      
      _orderTimeline.add({
        'status': 'completed',
        'title': '服务完成',
        'description': '陪诊服务已完成',
        'time': completedTime,
        'completed': true,
      });
    }
    
    // 订单取消
    if (order['status'] == 'cancelled') {
      final cancelledTime = createdAt.add(const Duration(minutes: 30));
      
      _orderTimeline.add({
        'status': 'cancelled',
        'title': '订单取消',
        'description': order['cancellation_reason'] ?? '用户取消',
        'time': cancelledTime,
        'completed': true,
      });
    }
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'in_progress':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return '待支付';
      case 'confirmed':
        return '待服务';
      case 'in_progress':
        return '进行中';
      case 'completed':
        return '已完成';
      case 'cancelled':
        return '已取消';
      default:
        return '未知状态';
    }
  }
  
  void _contactCompanion() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('联系陪诊师'),
        content: const Text(
          '陪诊师: 张医生\n'
          '电话: 13800138000\n'
          '微信: doctor_zhang\n\n'
          '您可以通过电话或微信联系陪诊师。',
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
            child: const Text('拨打电话'),
          ),
        ],
      ),
    );
  }
  
  void _rateOrder() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('评价服务'),
        content: const Text('评价功能正在开发中，敬请期待！'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
  
  void _cancelOrder() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('取消订单'),
        content: const Text('确定要取消这个订单吗？取消后可能无法恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('再想想'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _processCancellation();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('确定取消'),
          ),
        ],
      ),
    );
  }
  
  void _processCancellation() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('订单取消请求已发送'),
        backgroundColor: Colors.orange,
      ),
    );
    
    // 重新加载订单详情
    _loadOrderDetail();
  }
  
  void _payOrder() {
    Navigator.pushNamed(
      context,
      '/payment',
      arguments: {
        'order_id': _order?['id'],
        'amount': _order?['price'],
      },
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildPriceRow(String label, String price, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          price,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? Colors.red : Colors.black,
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
    final time = step['time'] as DateTime;
    final formattedTime = DateFormat('MM-dd HH:mm').format(time);
    
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
                color: step['completed'] ? Colors.blue : Colors.grey[300],
                shape: BoxShape.circle,
                border: Border.all(
                  color: step['completed'] ? Colors.blue : Colors.grey[300],
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
                color: step['completed'] ? Colors.blue : Colors.grey[300],
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
                  formattedTime,
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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('订单详情'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? _buildLoadingIndicator()
          : _error != null
              ? _buildErrorView()
              : _order == null
                  ? _buildEmptyView()
                  : _buildOrderDetail(),
    );
  }
  
  Widget _buildLoadingIndicator() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('正在加载订单详情...'),
        ],
      ),
    );
  }
  
  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          const Text(
            '加载失败',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? '未知错误',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadOrderDetail,
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.receipt_long,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            '订单不存在',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '您访问的订单不存在或已被删除',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('返回订单列表'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildOrderDetail() {
    final order = _order!;
    final status = order['status'] ?? 'pending';
    final statusColor = _getStatusColor(status);
    final statusText = _getStatusText(status);
    
    final createdAt = DateTime.parse(order['created_at']);
    final formattedDate = DateFormat('yyyy年MM月dd日 HH:mm').format(createdAt);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 订单状态卡片
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '订单状态',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: statusColor),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '订单号: ${order['id']}',
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '创建时间: $formattedDate',
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // 订单信息
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '订单信息',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildInfoRow('医院', order['hospital_name'] ?? '上海市第一人民医院'),
                  const SizedBox(height: 12),
                  
                  _buildInfoRow('陪诊师', order['companion_name'] ?? '张医生'),
                  const SizedBox(height: 12),
                  
                  _buildInfoRow('预约时间', formattedDate),
                  const SizedBox(height: 12),
                  
                  _buildInfoRow('服务类型', order['service_type'] ?? '普通陪诊'),
                  const SizedBox(height: 12),
                  
                  _buildInfoRow('服务时长', '${order['duration_minutes'] ?? 120}分钟'),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // 费用明细
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '费用明细',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildPriceRow('基础服务费', '¥199.00'),
                  const SizedBox(height: 8),
                  
                  _buildPriceRow('服务时长费用', '¥30.00'),
                  const SizedBox(height: 8),
                  
                  _buildPriceRow('平台服务费', '¥30.00'),
                  
                  const Divider(height: 24),
                  
                  _buildPriceRow(
                    '总计',
                    '¥${(order['price'] ?? 229).toStringAsFixed(2)}',
                    isTotal: true,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    '支付状态: ${order['payment_status'] == 'paid' ? '已支付' : '未支付'}',
                    style: TextStyle(
                      color: order['payment_status'] == 'paid' ? Colors.green : Colors.orange,
                    ),
                  ),
                  
                  if (order['payment_method'] != null)
                    Text(
                      '支付方式: ${order['payment_method']}',
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // 订单进度
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '订单进度',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  ..._orderTimeline