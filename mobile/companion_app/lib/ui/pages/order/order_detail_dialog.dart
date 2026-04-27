import 'package:flutter/material.dart';
import '../../../core/config/app_config.dart';

/// 订单详情底部弹出面板
/// 展示完整订单信息，供陪诊师查看后再决定接单
class OrderDetailSheet extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback? onAccept;

  const OrderDetailSheet({
    super.key,
    required this.order,
    this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    final isUrgent = (order['service_type'] ?? '').toString().contains('急诊');
    final price = order['price'] ?? 0;
    final duration = order['duration_minutes'] ?? 120;
    final hourlyRate = price > 0 ? (price / (duration / 60)).round() : 0;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 拖拽指示器
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 标题
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  '订单详情',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (isUrgent)
                  Container(
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
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 价格大标题
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '¥$price',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppConfig.accentColor,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '约${duration}分钟 · ¥$hourlyRate/时',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          const Divider(),
          Flexible(
            child: ListView(
              padding: const EdgeInsets.all(20),
              shrinkWrap: true,
              children: [
                // 患者信息区块
                _sectionTitle('患者信息'),
                const SizedBox(height: 8),
                _detailCard([
                  _row('姓名', order['patient_name'] ?? '未知', icon: Icons.person),
                  _row('手机号', order['patient_phone'] ?? '', icon: Icons.phone),
                ]),
                const SizedBox(height: 16),

                // 服务信息区块
                _sectionTitle('服务信息'),
                const SizedBox(height: 8),
                _detailCard([
                  _row('服务类型', order['service_type'] ?? '普通陪诊',
                      icon: Icons.medical_services_outlined),
                  _row('医　　院', order['hospital_name'] ?? '',
                      icon: Icons.local_hospital),
                  if ((order['department'] ?? '').toString().isNotEmpty)
                    _row('科　　室', order['department'],
                        icon: Icons.meeting_room_outlined),
                  if ((order['doctor_name'] ?? '').toString().isNotEmpty)
                    _row('医　　生', order['doctor_name'],
                        icon: Icons.person_outline),
                  _row('预约日期', order['appointment_date'] ?? '',
                      icon: Icons.calendar_today),
                  _row('预约时间', order['appointment_time'] ?? '',
                      icon: Icons.access_time),
                  _row('预计时长', '${duration}分钟',
                      icon: Icons.timer_outlined),
                ]),
                const SizedBox(height: 16),

                // 症状/备注
                if ((order['symptoms'] ?? '').toString().isNotEmpty) ...[
                  _sectionTitle('症状描述'),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      order['symptoms'],
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppConfig.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if ((order['notes'] ?? '').toString().isNotEmpty) ...[
                  _sectionTitle('患者备注'),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline,
                            size: 16, color: Colors.orange[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            order['notes'],
                            style: TextStyle(
                              color: Colors.orange[900],
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 医院地址（如果有）
                if ((order['hospital_address'] ?? '').toString().isNotEmpty) ...[
                  _sectionTitle('医院地址'),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 18, color: AppConfig.errorColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            order['hospital_address'],
                            style: TextStyle(
                              color: AppConfig.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),

          // 底部按钮
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        foregroundColor: Colors.grey[600],
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      child: const Text('再看看',
                          style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: onAccept,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: AppConfig.primaryColor,
                        elevation: 0,
                      ),
                      child: const Text(
                        '确认接单',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: AppConfig.primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppConfig.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _detailCard(List<Widget> rows) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rows,
      ),
    );
  }

  Widget _row(String label, String value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: Colors.grey[400]),
            const SizedBox(width: 6),
          ],
          SizedBox(
            width: 56,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: AppConfig.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
