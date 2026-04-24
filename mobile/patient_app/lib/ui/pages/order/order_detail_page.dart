import 'package:flutter/material.dart';

class OrderDetailPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const OrderDetailPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final id = data['id'] ?? '';
    final status = data['status'] ?? 'pending';
    final hName = data['hospital_name'] ?? '未知医院';
    final cName = data['companion_name'] ?? '待分配';
    final price = data['price'] ?? data['total_amount'] ?? 0;
    final time = data['appointment_time'] ?? data['appointment_date'] ?? '';
    final sType = data['service_type'] ?? '普通陪诊';
    final duration = data['duration_minutes'] ?? 120;
    final payStatus = data['payment_status'] ?? 'unpaid';

    return Scaffold(
      appBar: AppBar(title: Text('订单详情')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 状态卡片
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    _statusIcon(status),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_statusText(status), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                          Text('订单编号: $id', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 服务信息
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('服务信息', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    const Divider(),
                    _infoRow('服务类型', sType),
                    _infoRow('医院', hName),
                    _infoRow('陪诊师', cName),
                    _infoRow('预约时间', time.toString()),
                    _infoRow('服务时长', '${duration}分钟'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 支付信息
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('支付信息', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    const Divider(),
                    _infoRow('订单金额', '¥$price'),
                    _infoRow('支付状态', _payText(payStatus)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            // 操作按钮
            if (status == 'pending')
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.payment),
                  label: const Text('立即支付'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statusIcon(String status) {
    IconData icon;
    Color color;
    switch (status) {
      case 'confirmed':
        icon = Icons.check_circle;
        color = const Color(0xFF34A853);
        break;
      case 'in_progress':
        icon = Icons.sync;
        color = const Color(0xFF1A73E8);
        break;
      case 'completed':
        icon = Icons.check_circle_outline;
        color = Colors.grey;
        break;
      case 'cancelled':
        icon = Icons.cancel;
        color = const Color(0xFFDB4437);
        break;
      default:
        icon = Icons.schedule;
        color = const Color(0xFFF4B400);
    }
    return Icon(icon, size: 40, color: color);
  }

  String _statusText(String status) {
    switch (status) {
      case 'pending': return '待确认';
      case 'confirmed': return '已确认';
      case 'in_progress': return '服务中';
      case 'completed': return '已完成';
      case 'cancelled': return '已取消';
      default: return status;
    }
  }

  String _payText(String s) {
    switch (s) {
      case 'unpaid': return '未支付';
      case 'paid': return '已支付';
      case 'refunding': return '退款中';
      case 'refunded': return '已退款';
      default: return s;
    }
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(label, style: TextStyle(color: Colors.grey[600]))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
