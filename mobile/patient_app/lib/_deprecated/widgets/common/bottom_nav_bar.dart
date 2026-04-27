import 'package:flutter/material.dart';

import 'package:patient_app/core/config/theme_config.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool showLabels;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.showLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ThemeConfig.backgroundColor,
        border: Border(
          top: BorderSide(
            color: ThemeConfig.borderColor,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: '首页',
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.receipt_long_outlined,
                activeIcon: Icons.receipt_long,
                label: '订单',
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.chat_bubble_outline,
                activeIcon: Icons.chat_bubble,
                label: '消息',
              ),
              _buildNavItem(
                index: 3,
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: '我的',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isActive = currentIndex == index;
    final color = isActive
        ? ThemeConfig.primaryColor
        : ThemeConfig.textSecondaryColor;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(index),
          highlightColor: ThemeConfig.primaryColor.withOpacity(0.1),
          splashColor: ThemeConfig.primaryColor.withOpacity(0.2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                children: [
                  // 背景圆点（激活状态）
                  if (isActive)
                    Positioned(
                      top: -4,
                      left: 0,
                      right: 0,
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: ThemeConfig.primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  // 图标
                  Icon(
                    isActive ? activeIcon : icon,
                    size: 24,
                    color: color,
                  ),
                ],
              ),
              if (showLabels) ...[
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: ThemeConfig.fontSizeCaption,
                    color: color,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// 带浮动按钮的底部导航栏
class FloatingBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback? onFloatingButtonTap;
  final IconData? floatingButtonIcon;

  const FloatingBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.onFloatingButtonTap,
    this.floatingButtonIcon = Icons.add,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 底部导航栏
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: CustomBottomNavBar(
            currentIndex: currentIndex,
            onTap: onTap,
          ),
        ),
        // 浮动按钮
        if (onFloatingButtonTap != null)
          Positioned(
            left: MediaQuery.of(context).size.width / 2 - 28,
            bottom: 20,
            child: GestureDetector(
              onTap: onFloatingButtonTap,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: ThemeConfig.primaryColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: ThemeConfig.primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  floatingButtonIcon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// 带徽章的底部导航栏
class BadgeBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Map<int, int> badgeCounts;
  final bool showLabels;

  const BadgeBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.badgeCounts = const {},
    this.showLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ThemeConfig.backgroundColor,
        border: Border(
          top: BorderSide(
            color: ThemeConfig.borderColor,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              _buildNavItemWithBadge(
                index: 0,
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: '首页',
                badgeCount: badgeCounts[0] ?? 0,
              ),
              _buildNavItemWithBadge(
                index: 1,
                icon: Icons.receipt_long_outlined,
                activeIcon: Icons.receipt_long,
                label: '订单',
                badgeCount: badgeCounts[1] ?? 0,
              ),
              _buildNavItemWithBadge(
                index: 2,
                icon: Icons.chat_bubble_outline,
                activeIcon: Icons.chat_bubble,
                label: '消息',
                badgeCount: badgeCounts[2] ?? 0,
              ),
              _buildNavItemWithBadge(
                index: 3,
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: '我的',
                badgeCount: badgeCounts[3] ?? 0,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItemWithBadge({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int badgeCount,
  }) {
    final isActive = currentIndex == index;
    final color = isActive
        ? ThemeConfig.primaryColor
        : ThemeConfig.textSecondaryColor;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(index),
          highlightColor: ThemeConfig.primaryColor.withOpacity(0.1),
          splashColor: ThemeConfig.primaryColor.withOpacity(0.2),
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 图标
                  Icon(
                    isActive ? activeIcon : icon,
                    size: 24,
                    color: color,
                  ),
                  if (showLabels) ...[
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: ThemeConfig.fontSizeCaption,
                        color: color,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ],
              ),
              // 徽章
              if (badgeCount > 0)
                Positioned(
                  top: 8,
                  right: MediaQuery.of(context).size.width / 8 - 16,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: badgeCount > 9 ? 4 : 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: ThemeConfig.errorColor,
                      borderRadius:
                          BorderRadius.circular(ThemeConfig.borderRadiusFull),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      badgeCount > 99 ? '99+' : badgeCount.toString(),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}