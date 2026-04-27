import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:patient_app/core/config/theme_config.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final List<Widget> actions;
  final Widget? leading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;
  final bool centerTitle;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.actions = const [],
    this.leading,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 0,
    this.centerTitle = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor ?? ThemeConfig.backgroundColor,
      foregroundColor: foregroundColor ?? ThemeConfig.textPrimaryColor,
      elevation: elevation,
      centerTitle: centerTitle,
      leading: _buildLeading(context),
      title: Text(
        title,
        style: TextStyle(
          fontSize: ThemeConfig.fontSizeH2,
          fontWeight: FontWeight.w600,
          color: foregroundColor ?? ThemeConfig.textPrimaryColor,
        ),
      ),
      actions: actions,
      shape: Border(
        bottom: BorderSide(
          color: ThemeConfig.borderColor,
          width: 1,
        ),
      ),
    );
  }

  Widget? _buildLeading(BuildContext context) {
    if (leading != null) return leading;

    if (showBackButton && Navigator.of(context).canPop()) {
      return IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: foregroundColor ?? ThemeConfig.textPrimaryColor,
          size: 20,
        ),
        onPressed: () {
          if (Get.isDialogOpen == true) {
            Get.back();
          } else if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        },
      );
    }

    return null;
  }
}

// 带搜索框的AppBar
class SearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String hintText;
  final ValueChanged<String>? onSearch;
  final VoidCallback? onBack;
  final bool showBackButton;
  final List<Widget>? actions;

  const SearchAppBar({
    super.key,
    this.hintText = '搜索医院、陪诊师、服务...',
    this.onSearch,
    this.onBack,
    this.showBackButton = true,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: ThemeConfig.backgroundColor,
      elevation: 0,
      leading: showBackButton
          ? IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: ThemeConfig.textPrimaryColor,
                size: 20,
              ),
              onPressed: onBack ?? () => Navigator.of(context).pop(),
            )
          : null,
      title: Container(
        height: 40,
        decoration: BoxDecoration(
          color: ThemeConfig.cardColor,
          borderRadius: BorderRadius.circular(ThemeConfig.borderRadiusMedium),
          border: Border.all(color: ThemeConfig.borderColor),
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              fontSize: ThemeConfig.fontSizeBody2,
              color: ThemeConfig.textHintColor,
            ),
            border: InputBorder.none,
            prefixIcon: Icon(
              Icons.search,
              color: ThemeConfig.textSecondaryColor,
              size: 20,
            ),
            contentPadding: EdgeInsets.zero,
          ),
          style: TextStyle(
            fontSize: ThemeConfig.fontSizeBody2,
            color: ThemeConfig.textPrimaryColor,
          ),
          onChanged: onSearch,
          onSubmitted: onSearch,
        ),
      ),
      actions: actions,
      shape: Border(
        bottom: BorderSide(
          color: ThemeConfig.borderColor,
          width: 1,
        ),
      ),
    );
  }
}

// 带标签的AppBar
class TabAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int>? onTabChanged;
  final bool showBackButton;
  final List<Widget>? actions;

  const TabAppBar({
    super.key,
    required this.title,
    required this.tabs,
    required this.selectedIndex,
    this.onTabChanged,
    this.showBackButton = true,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight * 1.5);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: ThemeConfig.backgroundColor,
      foregroundColor: ThemeConfig.textPrimaryColor,
      elevation: 0,
      leading: showBackButton && Navigator.of(context).canPop()
          ? IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: ThemeConfig.textPrimaryColor,
                size: 20,
              ),
              onPressed: () => Navigator.of(context).pop(),
            )
          : null,
      title: Text(
        title,
        style: TextStyle(
          fontSize: ThemeConfig.fontSizeH2,
          fontWeight: FontWeight.w600,
          color: ThemeConfig.textPrimaryColor,
        ),
      ),
      actions: actions,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          height: 48,
          padding: EdgeInsets.symmetric(horizontal: ThemeConfig.spacingM),
          child: Row(
            children: List.generate(tabs.length, (index) {
              final isSelected = index == selectedIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTabChanged?.call(index),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isSelected
                              ? ThemeConfig.primaryColor
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      tabs[index],
                      style: TextStyle(
                        fontSize: ThemeConfig.fontSizeBody1,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected
                            ? ThemeConfig.primaryColor
                            : ThemeConfig.textSecondaryColor,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
      shape: Border(
        bottom: BorderSide(
          color: ThemeConfig.borderColor,
          width: 1,
        ),
      ),
    );
  }
}

// 透明背景AppBar
class TransparentAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showBackButton;
  final List<Widget>? actions;
  final Color? iconColor;

  const TransparentAppBar({
    super.key,
    this.title,
    this.showBackButton = true,
    this.actions,
    this.iconColor,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: showBackButton
          ? IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: iconColor ?? Colors.white,
                size: 20,
              ),
              onPressed: () => Navigator.of(context).pop(),
            )
          : null,
      title: title != null
          ? Text(
              title!,
              style: TextStyle(
                fontSize: ThemeConfig.fontSizeH2,
                fontWeight: FontWeight.w600,
                color: iconColor ?? Colors.white,
              ),
            )
          : null,
      actions: actions?.map((action) {
        if (action is IconButton) {
          return IconButton(
            icon: Icon(
              action.icon,
              color: iconColor ?? Colors.white,
            ),
            onPressed: action.onPressed,
          );
        }
        return action;
      }).toList(),
    );
  }
}