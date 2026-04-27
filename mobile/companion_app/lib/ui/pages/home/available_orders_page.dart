import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/companion_state.dart';
import '../../../core/config/app_config.dart';
import '../order/order_detail_dialog.dart';

/// 待接订单页面 v2
/// 增强：点击订单查看详情再决定接单，接单后反馈
class AvailableOrdersPage extends StatelessWidget {
  const AvailableOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CompanionState>();
    final orders = state.availableOrders;

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
                        Icon(Icons.check_circle_outline,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('暂无待接订单',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 16)),
                        const SizedBox(height: 4),
                        Text('有新订单时会实时通知你',
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 13)),
                        const SizedBox(height: 24),
                        OutlinedButton.icon(
                          onPressed: () => state.refreshAll(),
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('刷新'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, i) {
                final order = orders[i] as Map<String, dynamic>;
                return _OrderCard(order: order);
              },
            ),
    );
  }
}

/// 单个待接订单卡片（点击可查看详情）
class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final state = context.read<CompanionState>();

    // 判断是否是紧急订单
    final isUrgent = (order['service_type'] ?? '').toString().contains('急诊');
    final price = order['price'] ?? 0;
    final duration = order['duration_minutes'] ?? 120;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // 点击查看详情
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (ctx) => OrderDetailSheet(
              order: order,
              onAccept: () {
                Navigator.pop(ctx);
                state.acceptOrder(order['id']);
              },
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头部：患者信息 + 服务类型标签
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: isUrgent
                        ? AppConfig.errorColor.withValues(alpha: 0.1)
                        : AppConfig.accentColor.withValues(alpha: 0.1),
                    child: Text(
                      (order['patient_name'] ?? '?').toString()[0],
                      style: TextStyle(
                        color: isUrgent
                            ? AppConfig.errorColor
                            : AppConfig.accentColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order['patient_name'] ?? '未知',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        if (order['patient_phone'] != null &&
                            order['patient_phone'].toString().isNotEmpty)
                          Text(
                            order['patient_phone'],
                            style: TextStyle(
                                color: Colors.grey[500], fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                  // 紧急标签
                  if (isUrgent)
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppConfig.errorColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '急诊',
                        style: TextStyle(
                          color: AppConfig.errorColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  // 服务类型标签
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppConfig.accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      order['service_type'] ?? '陪诊',
                      style: TextStyle(
                        color: AppConfig.accentColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // 信息行
              _infoRow(Icons.local_hospital,
                  order['hospital_name'] ?? '', Colors.grey[700]!),
              _infoRow(
                  Icons.schedule,
                  '${order['appointment_date'] ?? ''} ${order['appointment_time'] ?? ''}',
                  Colors.grey[700]!),
              _infoRow(Icons.timer_outlined,
                  '约${duration}分钟', Colors.grey[700]!),
              // 症状（如果有）
              if ((order['symptoms'] ?? '').toString().isNotEmpty)
                _infoRow(Icons.healing,
                    '症状: ${order['symptoms']}', Colors.grey[600]!),
              // 备注（如果有）
              if ((order['notes'] ?? '').toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline,
                            size: 14, color: Colors.orange[700]),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            order['notes'],
                            style: TextStyle(
                              color: Colors.orange[900],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              // 底部：价格 + 操作按钮
              Row(
                children: [
                  // 价格展示
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '¥$price',
                            style: const TextStyle(
                              color: AppConfig.accentColor,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Text(
                              '/单（${(price / (duration / 60)).round()}元/时）',
                              style: TextStyle(
                                  color: Colors.grey[400], fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  // 操作按钮
                  Row(
                    children: [
                      // 忽略按钮
                      OutlinedButton(
                        onPressed: () {
                          // 刷新即可忽略
                          state.refreshAll();
                        },
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(80, 38),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          foregroundColor: Colors.grey[500],
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                        child: const Text('忽略',
                            style: TextStyle(fontSize: 14)),
                      ),
                      const SizedBox(width: 8),
                      // 查看详情按钮
                      OutlinedButton(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (ctx) => OrderDetailSheet(
                              order: order,
                              onAccept: () {
                                Navigator.pop(ctx);
                                state.acceptOrder(order['id']);
                              },
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(80, 38),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          foregroundColor: AppConfig.accentColor,
                          side: BorderSide(color: AppConfig.accentColor),
                        ),
                        child: const Text('详情',
                            style: TextStyle(fontSize: 14)),
                      ),
                      const SizedBox(width: 8),
                      // 抢单按钮
                      ElevatedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('确认接单'),
                              content: Text('确定接取${order['patient_name']}的${order['service_type'] ?? "陪诊"}订单吗？'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('再想想'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    state.acceptOrder(order['id']);
                                  },
                                  child: Text('确认接单',
                                      style: TextStyle(
                                          color: AppConfig.primaryColor,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(100, 38),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          backgroundColor: AppConfig.primaryColor,
                        ),
                        child: const Text('立即接单',
                            style: TextStyle(
                                fontSize: 15, color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[500]),
          const SizedBox(width: 6),
          Flexible(
            child: Text(text,
                style: TextStyle(color: color, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
