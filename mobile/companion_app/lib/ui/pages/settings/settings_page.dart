import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/companion_state.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/config/app_config.dart';

/// 设置页面
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final StorageService _storage = StorageService();
  bool _notificationSound = true;
  bool _notificationVibrate = true;
  bool _autoAccept = false;
  bool _showOnline = true;
  bool _loadingSettings = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _loadingSettings = true);
    _notificationSound =
        await _storage.getSetting('notification_sound') ?? true;
    _notificationVibrate =
        await _storage.getSetting('notification_vibrate') ?? true;
    _autoAccept = await _storage.getSetting('auto_accept') ?? false;
    _showOnline = await _storage.getSetting('show_online') ?? true;
    if (mounted) setState(() => _loadingSettings = false);
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    await _storage.saveSetting(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: _loadingSettings
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 通知设置
                _sectionHeader('通知设置'),
                const SizedBox(height: 8),
                _buildSwitchTile(
                  icon: Icons.volume_up_outlined,
                  title: '接单提示音',
                  subtitle: '有新订单时播放提示音',
                  value: _notificationSound,
                  onChanged: (v) {
                    setState(() => _notificationSound = v);
                    _saveSetting('notification_sound', v);
                  },
                ),
                _buildSwitchTile(
                  icon: Icons.vibration,
                  title: '振动提醒',
                  subtitle: '有新订单时振动提醒',
                  value: _notificationVibrate,
                  onChanged: (v) {
                    setState(() => _notificationVibrate = v);
                    _saveSetting('notification_vibrate', v);
                  },
                ),
                _buildSwitchTile(
                  icon: Icons.wifi_tethering,
                  title: '在线状态',
                  subtitle: '向患者显示在线状态',
                  value: _showOnline,
                  onChanged: (v) {
                    setState(() => _showOnline = v);
                    _saveSetting('show_online', v);
                  },
                ),

                const SizedBox(height: 24),

                // 接单设置
                _sectionHeader('接单设置'),
                const SizedBox(height: 8),
                _buildSwitchTile(
                  icon: Icons.auto_awesome,
                  title: '自动接单',
                  subtitle: '开启后系统自动接取符合条件的订单',
                  value: _autoAccept,
                  onChanged: (v) {
                    setState(() => _autoAccept = v);
                    _saveSetting('auto_accept', v);
                  },
                ),

                const SizedBox(height: 24),

                // 账号安全
                _sectionHeader('账号安全'),
                const SizedBox(height: 8),
                _buildActionTile(
                  icon: Icons.lock_outline,
                  title: '修改密码',
                  subtitle: '定期修改密码保障账户安全',
                  onTap: () => _showChangePasswordDialog(),
                ),
                _buildActionTile(
                  icon: Icons.phone_android,
                  title: '修改手机号',
                  subtitle: '更换绑定的手机号码',
                  onTap: () {},
                ),

                const SizedBox(height: 24),

                // 其他
                _sectionHeader('其他'),
                const SizedBox(height: 8),
                _buildInfoTile(
                  icon: Icons.info_outline,
                  title: '版本信息',
                  subtitle: 'v${AppConfig.appVersion}',
                ),
                _buildInfoTile(
                  icon: Icons.description_outlined,
                  title: '服务协议',
                  subtitle: '查看用户协议和隐私政策',
                  onTap: () {},
                ),

                const SizedBox(height: 32),

                // 退出登录
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showLogoutDialog(),
                    icon: const Icon(Icons.logout, color: AppConfig.errorColor),
                    label: const Text(
                      '退出登录',
                      style: TextStyle(color: AppConfig.errorColor),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppConfig.errorColor),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        title,
        style: TextStyle(
          color: AppConfig.primaryColor,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        secondary: Icon(icon, color: AppConfig.primaryColor, size: 22),
        title: Text(title, style: const TextStyle(fontSize: 15)),
        subtitle: Text(subtitle,
            style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        value: value,
        onChanged: onChanged,
        activeTrackColor: AppConfig.primaryColor,
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppConfig.primaryColor, size: 22),
        title: Text(title, style: const TextStyle(fontSize: 15)),
        subtitle: Text(subtitle,
            style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppConfig.primaryColor, size: 22),
        title: Text(title, style: const TextStyle(fontSize: 15)),
        trailing: subtitle != null
            ? Text(subtitle,
                style: TextStyle(color: Colors.grey[500], fontSize: 13))
            : const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  void _showChangePasswordDialog() {
    final oldPwdCtrl = TextEditingController();
    final newPwdCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('修改密码'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPwdCtrl,
              decoration: const InputDecoration(
                labelText: '原密码',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPwdCtrl,
              decoration: const InputDecoration(
                labelText: '新密码',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmCtrl,
              decoration: const InputDecoration(
                labelText: '确认新密码',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('密码修改功能开发中')),
              );
            },
            child: const Text('确认修改'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<CompanionState>().logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('确定', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
