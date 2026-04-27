import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/companion_state.dart';
import '../../../core/config/app_config.dart';
import '../chat/chat_detail_page.dart';

/// 订单详情页 - 查看订单完整信息
class OrderDetailPage extends StatelessWidget {
  final Map<String, dynamic> order;
  final String orderId;

  const OrderDetailPage({
    super.key,
    required this.order,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.read<CompanionState>();
    // 从state的myOrders中找最新数据
    final fullOrder = state.myOrders.firstWhere(
      (o) => o['id'] == orderId,
      orElse: () => order,
    ) as Map<String, dynamic>;

    final status = fullOrder['status'] ?? '';
    final statusInfo = _getStatusInfo(status);

    return Scaffold(
      appBar: AppBar(
        title: const Text('订单详情'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusInfo.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              statusInfo.label,
              style: TextStyle(
                color: statusInfo.color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 患者信息
          _sectionCard('患者信息', [
            _detailRow('姓名', fullOrder['patient_name'] ?? ''),
            _detailRow('手机号', fullOrder['patient_phone'] ?? ''),
            _detailRow('备注', fullOrder['notes'] ?? '无'),
          ]),
          const SizedBox(height: 12),

          // 服务信息
          _sectionCard('服务信息', [
            _detailRow('服务类型', fullOrder['service_type'] ?? '普通陪诊'),
            _detailRow('医院', fullOrder['hospital_name'] ?? ''),
            _detailRow('科室', fullOrder['department'] ?? ''),
            _detailRow('预约日期', fullOrder['appointment_date'] ?? ''),
            _detailRow('预约时间', fullOrder['appointment_time'] ?? ''),
            _detailRow('预计时长', '${fullOrder['duration_minutes'] ?? 120}分钟'),
            if ((fullOrder['symptoms'] ?? '').toString().isNotEmpty)
              _detailRow('症状描述', fullOrder['symptoms']),
          ]),
          const SizedBox(height: 12),

          // 费用信息
          _sectionCard('费用信息', [
            _detailRow('服务费用', '¥${fullOrder['price'] ?? fullOrder['total_amount'] ?? 0}'),
            _detailRow('支付状态', _payStatus(fullOrder['payment_status'] ?? 'pending')),
            _detailRow('订单编号', fullOrder['id'] ?? ''),
            _detailRow('创建时间', fullOrder['created_at'] ?? ''),
          ]),
          const SizedBox(height: 12),

          // 操作按钮
          if (status == 'confirmed')
            _actionButton(
              context,
              '开始服务',
              AppConfig.accentColor,
              () => state.startService(orderId),
            ),
          if (status == 'in_progress')
            _actionButton(
              context,
              '完成服务',
              AppConfig.primaryColor,
              () => state.completeService(orderId),
            ),

          const SizedBox(height: 8),

          // 联系患者按钮
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatDetailPage(
                    sessionId: orderId,
                    otherUserId: fullOrder['patient_id'] ?? '',
                    otherUserName: fullOrder['patient_name'] ?? '患者',
                    currentUserId: '',
                    orderId: orderId,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.chat_outlined),
            label: const Text('联系患者'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppConfig.primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: AppConfig.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _payStatus(String status) {
    switch (status) {
      case 'paid':
        return '已支付 ✅';
      case 'pending':
        return '待支付';
      case 'refunded':
        return '已退款';
      default:
        return status;
    }
  }

  Widget _actionButton(
      BuildContext context, String label, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(label),
              content: Text('确认要$label吗？'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    onTap();
                  },
                  child: const Text('确定'),
                ),
              ],
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(label, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  _StatusInfo _getStatusInfo(String status) {
    switch (status) {
      case 'pending':
        return _StatusInfo('待确认', const Color(0xFFF4B400));
      case 'confirmed':
        return _StatusInfo('已确认', AppConfig.accentColor);
      case 'in_progress':
        return _StatusInfo('服务中', AppConfig.primaryColor);
      case 'completed':
        return _StatusInfo('已完成', Colors.grey);
      case 'cancelled':
        return _StatusInfo('已取消', AppConfig.errorColor);
      default:
        return _StatusInfo(status, const Color(0xFFF4B400));
    }
  }
}

class _StatusInfo {
  final String label;
  final Color color;
  _StatusInfo(this.label, this.color);
}
