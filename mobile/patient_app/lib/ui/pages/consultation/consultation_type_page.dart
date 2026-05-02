import 'package:flutter/material.dart';

/// 问诊类型选择页 — 患者选择图文/电话/视频咨询
class ConsultationTypePage extends StatefulWidget {
  const ConsultationTypePage({super.key});

  @override
  State<ConsultationTypePage> createState() => _ConsultationTypePageState();
}

class _ConsultationTypePageState extends State<ConsultationTypePage> {
  @override
  void initState() {
    super.initState();
  }

  final _types = [
    _ConsultationType(
      icon: Icons.chat_bubble_outline_rounded,
      title: '图文咨询',
      subtitle: '文字+图片描述病情，医生在线回复',
      price: '¥19.9 起',
      tag: '推荐',
      tagColor: const Color(0xFF34A853),
      route: '/consultation/symptom',
      args: {'type': 'text'},
    ),
    _ConsultationType(
      icon: Icons.phone_in_talk_rounded,
      title: '电话咨询',
      subtitle: '与医生一对一通话，高效沟通',
      price: '¥39.9 起',
      tag: '15分钟',
      tagColor: const Color(0xFF1A73E8),
      route: '/consultation/symptom',
      args: {'type': 'phone'},
    ),
    _ConsultationType(
      icon: Icons.videocam_rounded,
      title: '视频咨询',
      subtitle: '面对面视频问诊，看得更清楚',
      price: '¥59.9 起',
      tag: '20分钟',
      tagColor: const Color(0xFFE37400),
      route: '/consultation/symptom',
      args: {'type': 'video'},
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('选择问诊方式'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 顶部说明
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFF34A853), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '三甲医院执业医生在线接诊，请根据您的病情选择合适的问诊方式',
                    style: TextStyle(color: Colors.grey[700], fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 问诊类型卡片
          ..._types.map((type) => _buildTypeCard(type)),
          const SizedBox(height: 24),

          // 底部提示
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '在线问诊不能替代线下急诊，急重症请立即拨打 120',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeCard(_ConsultationType type) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.pushNamed(context, type.route, arguments: type.args);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 左侧图标
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: type.tagColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(type.icon, color: type.tagColor, size: 28),
              ),
              const SizedBox(width: 16),
              // 中间内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(type.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: type.tagColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(type.tag,
                            style: TextStyle(
                              color: type.tagColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(type.subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ],
                ),
              ),
              // 右侧价格
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(type.price, style: const TextStyle(
                    color: Color(0xFFE37400),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  )),
                ],
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConsultationType {
  final IconData icon;
  final String title;
  final String subtitle;
  final String price;
  final String tag;
  final Color tagColor;
  final String route;
  final Map<String, dynamic> args;

  const _ConsultationType({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.tag,
    required this.tagColor,
    required this.route,
    required this.args,
  });
}
