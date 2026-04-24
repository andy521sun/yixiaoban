import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/services/api_service.dart';
import '../../../core/providers/user_provider.dart';

class OrderListPage extends StatefulWidget {
  const OrderListPage({Key? key}) : super(key: key);

  @override
  _OrderListPageState createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _filteredOrders = [];
  bool _isLoading = true;
  
  // 筛选相关
  String _selectedStatus = 'all';
  String _selectedTimeRange = 'all';
  String _selectedSort = 'newest';
  
  final List<Map<String, dynamic>> _statusFilters = [
    {'value': 'all', 'label': '全部'},
    {'value': 'pending', 'label': '待支付'},
    {'value': 'confirmed', 'label': '待服务'},
    {'value': 'in_progress', 'label': '进行中'},
    {'value': 'completed', 'label': '已完成'},
    {'value': 'cancelled', 'label': '已取消'},
  ];
  
  @override
  void initState() {
    super.initState();
    _loadOrders();
  }
  
  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // 获取用户ID
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.userId ?? 'user_001';
      
      // 调用API获取订单
      final orders = await ApiService().getOrders(
        userId: userId,
        status: _selectedStatus == 'all' ? null : _selectedStatus,
      );
      
      setState(() {
        _orders = orders;
        _filteredOrders = _applyFilters(orders);
        _isLoading = false;
      });
    } catch (error) {
      print('加载订单失败: $error');
      setState(() {
        _isLoading = false;
      });
      
      // 显示错误提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('加载订单失败: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> orders) {
    List<Map<String, dynamic>> filtered = List.from(orders);
    
    // 状态过滤
    if (_selectedStatus != 'all') {
      filtered = filtered.where((order) => order['status'] == _selectedStatus).toList();
    }
    
    // 时间范围过滤
    filtered = _filterByTimeRange(filtered);
    
    // 排序
    filtered = _sortOrders(filtered);
    
    return filtered;
  }
  
  List<Map<String, dynamic>> _filterByTimeRange(List<Map<String, dynamic>> orders) {
    if (_selectedTimeRange == 'all') return orders;
    
    final now = DateTime.now();
    DateTime startDate;
    
    switch (_selectedTimeRange) {
      case 'today':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'week':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 'month':
        startDate = DateTime(now.year, now.month - 1, now.day);
        break;
      case 'year':
        startDate = DateTime(now.year - 1, now.month, now.day);
        break;
      default:
        return orders;
    }
    
    return orders.where((order) {
      final createdAt = DateTime.parse(order['created_at']);
      return createdAt.isAfter(startDate);
    }).toList();
  }
  
  List<Map<String, dynamic>> _sortOrders(List<Map<String, dynamic>> orders) {
    switch (_selectedSort) {
      case 'newest':
        orders.sort((a, b) => DateTime.parse(b['created_at']).compareTo(DateTime.parse(a['created_at'])));
        break;
      case 'oldest':
        orders.sort((a, b) => DateTime.parse(a['created_at']).compareTo(DateTime.parse(b['created_at'])));
        break;
      case 'price_high':
        orders.sort((a, b) => (b['price'] ?? 0).compareTo(a['price'] ?? 0));
        break;
      case 'price_low':
        orders.sort((a, b) => (a['price'] ?? 0).compareTo(b['price'] ?? 0));
        break;
    }
    return orders;
  }
  
  void _viewOrderDetail(Map<String, dynamic> order) {
    Navigator.pushNamed(
      context,
      '/order/detail',
      arguments: {'order_id': order['id']},
    );
  }
  
  void _createNewOrder() {
    Navigator.pushNamed(context, '/appointment/select');
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
  
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.payment;
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'in_progress':
        return Icons.access_time;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的订单'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 筛选栏
          _buildFilterBar(),
          
          // 订单列表
          Expanded(
            child: _isLoading
                ? _buildLoadingIndicator()
                : _filteredOrders.isEmpty
                    ? _buildEmptyState()
                    : _buildOrderList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewOrder,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        tooltip: '新建预约',
      ),
    );
  }
  
  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        children: [
          // 状态筛选
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _statusFilters.map((filter) {
                final isSelected = _selectedStatus == filter['value'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter['label']),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedStatus = filter['value'];
                        _filteredOrders = _applyFilters(_orders);
                      });
                    },
                    backgroundColor: Colors.grey[100],
                    selectedColor: Colors.blue[100],
                    checkmarkColor: Colors.blue,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.blue : Colors.grey[700],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // 其他筛选
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown(
                  value: _selectedTimeRange,
                  items: [
                    {'value': 'all', 'label': '全部时间'},
                    {'value': 'today', 'label': '今天'},
                    {'value': 'week', 'label': '本周'},
                    {'value': 'month', 'label': '本月'},
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedTimeRange = value!;
                      _filteredOrders = _applyFilters(_orders);
                    });
                  },
                  hint: '时间范围',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFilterDropdown(
                  value: _selectedSort,
                  items: [
                    {'value': 'newest', 'label': '最新订单'},
                    {'value': 'oldest', 'label': '最早订单'},
                    {'value': 'price_high', 'label': '价格最高'},
                    {'value': 'price_low', 'label': '价格最低'},
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedSort = value!;
                      _filteredOrders = _applyFilters(_orders);
                    });
                  },
                  hint: '排序方式',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterDropdown({
    required String value,
    required List<Map<String, dynamic>> items,
    required ValueChanged<String?> onChanged,
    required String hint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, size: 24),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
          ),
          onChanged: onChanged,
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item['value'],
              child: Text(item['label']),
            );
          }).toList(),
        ),
      ),
    );
  }
  
  Widget _buildLoadingIndicator() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('正在加载订单...'),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            '暂无订单',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedStatus == 'all'
                ? '您还没有任何订单'
                : '没有${_statusFilters.firstWhere((f) => f['value'] == _selectedStatus)['label']}的订单',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _createNewOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('立即预约'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildOrderList() {
    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _filteredOrders.length,
        itemBuilder: (context, index) {
          final order = _filteredOrders[index];
          return _buildOrderCard(order);
        },
      ),
    );
  }
  
  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] ?? 'pending';
    final statusColor = _getStatusColor(status);
    final statusText = _getStatusText(status);
    final statusIcon = _getStatusIcon(status);
    
    final createdAt = DateTime.parse(order['created_at']);
    final formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(createdAt);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _viewOrderDetail(order),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 订单头部
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '订单号: ${order['id']}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 12,
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // 订单信息
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 医院信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order['hospital_name'] ?? '未知医院',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order['companion_name'] ?? '未知陪诊师',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // 价格信息
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '¥${(order['price'] ?? 0).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // 操作按钮
              if (status == 'pending' || status == 'confirmed')
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          // 取消订单
                          _showCancelDialog(order);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('取消订单'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _viewOrderDetail(order),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('查看详情'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showCancelDialog(Map<String, dynamic> order) {
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
              _cancelOrder(order);
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
  
  void _cancelOrder(Map<String, dynamic> order) {
    // 这里应该调用API取消订单
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('订单取消请求已发送'),
        backgroundColor: Colors.orange,
      ),
    );
    
    // 重新加载订单
    _loadOrders();
  }
}