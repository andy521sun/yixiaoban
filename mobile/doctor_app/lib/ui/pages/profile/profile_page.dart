import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:doctor_app/core/providers/doctor_state.dart';

/// 医生端个人中心
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DoctorAppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 医生信息
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: const Color(0xFF1A73E8).withValues(alpha: 0.1),
                    child: Text(
                      state.doctorName.isNotEmpty ? state.doctorName[0] : '医',
                      style: const TextStyle(color: Color(0xFF1A73E8), fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(state.doctorName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        if (state.doctorTitle.isNotEmpty)
                          Text('${state.doctorTitle} · ${state.doctorDepartment}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                        if (state.doctorHospital.isNotEmpty)
                          Text(state.doctorHospital, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                        const SizedBox(height: 8),
                        if (state.isCertified)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('已认证', style: TextStyle(color: Color(0xFF34A853), fontSize: 11)),
                          )
                        else
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/certification'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                state.certStatus == 'pending' ? '审核中' : '未认证',
                                style: TextStyle(color: Colors.orange[700], fontSize: 11),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 菜单
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('处方记录'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pushNamed(context, '/prescriptions'),
                ),
                const Divider(height: 0, indent: 16),
                ListTile(
                  leading: const Icon(Icons.price_change_outlined),
                  title: const Text('服务价格设置'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pushNamed(context, '/service-pricing'),
                ),
                const Divider(height: 0, indent: 16),
                ListTile(
                  leading: const Icon(Icons.verified_outlined),
                  title: const Text('认证信息'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pushNamed(context, '/certification'),
                ),
                const Divider(height: 0, indent: 16),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('关于医小伴'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('退出登录'),
                    content: const Text('确定要退出登录吗？'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
                      ElevatedButton(
                        onPressed: () {
                          context.read<DoctorAppState>().logout();
                          Navigator.pop(context);
                        },
                        child: const Text('退出'),
                      ),
                    ],
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
              child: const Text('退出登录'),
            ),
          ),
        ],
      ),
    );
  }
}
