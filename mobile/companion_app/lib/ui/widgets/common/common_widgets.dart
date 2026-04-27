import 'package:flutter/material.dart';
import '../../../core/config/app_config.dart';

/// 通用信息行（图标 + 文本）
class InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? textColor;
  final double fontSize;

  const InfoRow({
    super.key,
    required this.icon,
    required this.text,
    this.textColor,
    this.fontSize = 13,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[500]),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: textColor ?? Colors.grey[700],
                fontSize: fontSize,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// 统计项（数字 + 标签）
class StatItem extends StatelessWidget {
  final String count;
  final String label;
  final Color? color;

  const StatItem({
    super.key,
    required this.count,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color ?? AppConfig.primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

/// 功能菜单项
class MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;

  const MenuItem({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(label, style: const TextStyle(fontSize: 15)),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}

/// 连接状态指示器
class ConnectionIndicator extends StatelessWidget {
  final String status;
  final int notificationCount;

  const ConnectionIndicator({
    super.key,
    required this.status,
    this.notificationCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isConnected = status == '已连接';
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (isConnected ? AppConfig.primaryColor : Colors.red).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isConnected ? AppConfig.primaryColor : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isConnected ? '在线' : '离线',
            style: TextStyle(
              color: isConnected ? AppConfig.primaryColor : Colors.red,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

/// 订单状态标签
class OrderStatusBadge extends StatelessWidget {
  final String status;

  const OrderStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final info = _getStatusInfo(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: info.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        info.label,
        style: TextStyle(
          color: info.color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
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
