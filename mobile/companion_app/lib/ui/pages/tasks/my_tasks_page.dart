import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/companion_state.dart';
import '../../../core/config/app_config.dart';
import '../order/order_detail_page.dart';

/// 我的任务页面 v2
/// 增强：任务按状态分组，操作按钮更清晰，支持取消订单
class MyTasksPage extends StatelessWidget {
  const MyTasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CompanionState>();
    final orders = state.myOrders;

    // 按状态分组
    final inProgress = orders.where((o) => o['status'] == 'in_progress').toList();
    final confirmed = orders.where((o) => o['status'] == 'confirmed').toList();
    final completed = orders.where((o) => o['status'] == 'completed').toList();
    final cancelled = orders.where((o) => o['status'] == 'cancelled').toList();
    // final hasActiveTasks = inProgress.isNotEmpty || confirmed.isNotEmpty;

    return RefreshIndicator(
      onRefresh: state.refreshAll,
      child: orders.isEmpty
          ? ListView(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.task_alt_outlined,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('暂无任务',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 16)),
                        const SizedBox(height: 4),
                        Text('接单后的任务将在这里显示',
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 13)),
                        const SizedBox(height: 20),
                        if (state.availableOrderCount > 0)
                          Text(
                            '当前有 ${state.availableOrderCount} 个待接订单',
                            style: TextStyle(
                              color: AppConfig.accentColor,
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 进行中的任务区块（如果有）
                if (inProgress.isNotEmpty) ...[
                  _sectionHeader('服务中', inProgress.length, AppConfig.primaryColor),
                  ...inProgress.map((o) => _TaskCard(
                        order: o as Map<String, dynamic>,
                        showAction: true,
                      )),
                  const SizedBox(height: 12),
                ],

                // 待服务的任务
                if (confirmed.isNotEmpty) ...[
                  _sectionHeader('待服务', confirmed.length, AppConfig.accentColor),
                  ...confirmed.map((o) => _TaskCard(
                        order: o as Map<String, dynamic>,
                        showAction: true,
                      )),
                  const SizedBox(height: 12),
                ],

                // 已完成 + 已取消（可折叠展示，只显示最近5条）
                if (completed.isNotEmpty || cancelled.isNotEmpty) ...[
                  _sectionHeader('历史记录', completed.length + cancelled.length, Colors.grey),
                  ...completed.take(3).map((o) => _TaskCard(
                        order: o as Map<String, dynamic>,
                        showAction: false,
                      )),
                  if (completed.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 8),
                      child: Center(
                        child: Text(
                          '还有 ${completed.length - 3} 条已完成记录...',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ),
    );
  }

  Widget _sectionHeader(String title, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 任务卡片
class _TaskCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final bool showAction;

  const _TaskCard({
    required this.order,
    this.showAction = true,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.read<CompanionState>();
    final status = order['status'] ?? '';
    final statusInfo = _getStatusInfo(status);
    final orderId = order['id'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderDetailPage(
              order: order,
              orderId: orderId,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头部：患者名 + 状态标签 + 价格
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: statusInfo.color.withValues(alpha: 0.1),
                    child: Text(
                      (order['patient_name'] ?? '?').toString()[0],
                      style: TextStyle(
                        color: statusInfo.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      order['patient_name'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusInfo.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      statusInfo.label,
                      style: TextStyle(
                        color: statusInfo.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // 信息行
              _detailRow(
                  Icons.local_hospital, order['hospital_name'] ?? ''),
              _detailRow(
                  Icons.access_time,
                  '${order['appointment_date'] ?? ''} ${order['appointment_time'] ?? ''}'),
              _detailRow(Icons.attach_money,
                  '¥${order['price'] ?? 0}'),

              // 操作按钮
              if (showAction) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (status == 'confirmed') ...[
                      // 取消按钮
                      TextButton(
                        onPressed: () => _showCancelDialog(context, orderId),
                        style: TextButton.styleFrom(
                          foregroundColor: AppConfig.errorColor,
                          minimumSize: const Size(80, 36),
                        ),
                        child: const Text('取消订单',
                            style: TextStyle(fontSize: 13)),
                      ),
                      const SizedBox(width: 8),
                      // 开始服务按钮
                      ElevatedButton(
                        onPressed: () => _confirmAction(
                          context,
                          '开始服务',
                          '确认已到达医院，开始为患者服务吗？',
                          () => state.startService(orderId),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConfig.accentColor,
                          minimumSize: const Size(120, 38),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('开始服务',
                            style: TextStyle(
                                fontSize: 14, color: Colors.white)),
                      ),
                    ],
                    if (status == 'in_progress') ...[
                      ElevatedButton(
                        onPressed: () => _confirmAction(
                          context,
                          '完成服务',
                          '确认服务已完成，结束本次陪伴吗？',
                          () => state.completeService(orderId),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConfig.primaryColor,
                          minimumSize: const Size(120, 38),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('完成服务',
                            style: TextStyle(
                                fontSize: 14, color: Colors.white)),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _confirmAction(
    BuildContext context,
    String title,
    String content,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: Text(title,
                style: TextStyle(
                    color: title == '完成服务'
                        ? AppConfig.primaryColor
                        : AppConfig.accentColor,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context, String orderId) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('取消订单'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('确定要取消这个订单吗？'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: '填写取消原因（可选）',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('不了'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context
                  .read<CompanionState>()
                  .cancelOrder(orderId, reason: reasonController.text);
            },
            child: const Text('确认取消',
                style: TextStyle(
                    color: AppConfig.errorColor,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 15, color: Colors.grey[500]),
          const SizedBox(width: 6),
          Flexible(
            child: Text(text,
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ),
        ],
      ),
    );
  }

  _StatusInfo _getStatusInfo(String status) {
    switch (status) {
      case 'pending':
        return _StatusInfo('待确认', const Color(0xFFF4B400));
      case 'confirmed':
        return _StatusInfo('待服务', AppConfig.accentColor);
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
