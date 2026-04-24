import 'package:flutter/material.dart';

class CompanionDetailPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const CompanionDetailPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final name = data['name'] ?? data['real_name'] ?? '';
    final intro = data['introduction'] ?? '';
    final spec = data['specialty'] ?? '';
    final rating = data['rating'] ?? data['average_rating'] ?? 0;
    final rate = data['hourly_rate'] ?? 0;
    final services = data['service_count'] ?? 0;
    final experience = data['experience_years'] ?? 0;

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 头部
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF34A853), Color(0xFF66BB6A)],
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Text(
                      name.isNotEmpty ? name[0] : '?',
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  if (experience > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('${experience}年经验', style: TextStyle(color: Colors.white.withOpacity(0.9))),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (rating > 0) ...[
                        const Icon(Icons.star, color: Colors.amber, size: 20),
                        const SizedBox(width: 4),
                        Text('$rating', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                        Container(width: 1, height: 16, color: Colors.white.withOpacity(0.3), margin: const EdgeInsets.symmetric(horizontal: 12)),
                      ],
                      if (services > 0) ...[
                        Text('$services单', style: TextStyle(color: Colors.white.withOpacity(0.9))),
                        Container(width: 1, height: 16, color: Colors.white.withOpacity(0.3), margin: const EdgeInsets.symmetric(horizontal: 12)),
                      ],
                      if (rate > 0)
                        Text('¥$rate/时', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 专长
                  if (spec.isNotEmpty) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('专业擅长', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: spec.split('、').map((s) {
                                final tag = s.trim();
                                if (tag.isEmpty) return const SizedBox.shrink();
                                return Chip(
                                  label: Text(tag, style: const TextStyle(fontSize: 13)),
                                  backgroundColor: const Color(0xFF34A853).withOpacity(0.1),
                                  side: BorderSide.none,
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 个人介绍
                  if (intro.isNotEmpty) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('个人介绍', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                            const SizedBox(height: 8),
                            Text(intro, style: TextStyle(color: Colors.grey[700], height: 1.6)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // 预约按钮
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/appointment', arguments: {
                        'companion_id': data['id'],
                        'companion_name': name,
                        'hourly_rate': rate,
                      }),
                      icon: const Icon(Icons.calendar_today),
                      label: const Text('预约该陪诊师'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF34A853),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
