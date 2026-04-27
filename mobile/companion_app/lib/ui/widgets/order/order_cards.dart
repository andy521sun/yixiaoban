import 'package:flutter/material.dart';
import '../../../../core/config/app_config.dart';
import '../common/common_widgets.dart';

/// 待接订单卡片
class AvailableOrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onAccept;

  const AvailableOrderCard({
    super.key,
    required this.order,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 患者信息 + 服务类型
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppConfig.accentColor.withValues(alpha: 0.1),
                  child: Text(
                    (order['patient_name'] ?? '?').toString()[0],
                    style: const TextStyle(
                      color: AppConfig.accentColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    order['patient_name'] ?? '未知',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppConfig.accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    order['service_type'] ?? '',
                    style: const TextStyle(
                      color: AppConfig.accentColor,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            InfoRow(
              icon: Icons.local_hospital,
              text: order['hospital_name'] ?? '',
            ),
            InfoRow(
              icon: Icons.access_time,
              text: '${order['appointment_date'] ?? ''} ${order['appointment_time'] ?? ''}',
            ),
            InfoRow(
              icon: Icons.timer_outlined,
              text: '${order['duration_minutes'] ?? 120}分钟',
            ),
            if ((order['symptoms'] ?? '').toString().isNotEmpty)
              InfoRow(
                icon: Icons.healing,
                text: '症状: ${order['symptoms']}',
                textColor: Colors.grey[600],
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '¥${order['price'] ?? 0}',
                  style: const TextStyle(
                    color: AppConfig.accentColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '/单',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(100, 38),
                  ),
                  child: const Text('接单', style: TextStyle(fontSize: 15)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 我的任务卡片
class MyOrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback? onAction;

  const MyOrderCard({
    super.key,
    required this.order,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final status = order['status'] ?? '';
    final actionInfo = _getActionInfo(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  order['patient_name'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                OrderStatusBadge(status: status),
              ],
            ),
            const SizedBox(height: 6),
            InfoRow(icon: Icons.local_hospital, text: order['hospital_name'] ?? ''),
            InfoRow(
              icon: Icons.access_time,
              text: '${order['appointment_date'] ?? ''} ${order['appointment_time'] ?? ''}',
            ),
            if (actionInfo != null) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: onAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: actionInfo.color,
                    minimumSize: const Size(120, 38),
                  ),
                  child: Text(
                    actionInfo.label,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  _ActionInfo? _getActionInfo(String status) {
    switch (status) {
      case 'confirmed':
        return _ActionInfo('开始服务', AppConfig.accentColor);
      case 'in_progress':
        return _ActionInfo('完成服务', AppConfig.primaryColor);
      default:
        return null;
    }
  }
}

class _ActionInfo {
  final String label;
  final Color color;
  _ActionInfo(this.label, this.color);
}
