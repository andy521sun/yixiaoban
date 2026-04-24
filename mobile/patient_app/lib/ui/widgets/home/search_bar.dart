import 'package:flutter/material.dart';

import 'package:patient_app/core/config/theme_config.dart';

class SearchBarWidget extends StatelessWidget {
  final ValueChanged<String>? onSearch;
  final String hintText;
  final bool autofocus;
  final bool enabled;
  final TextEditingController? controller;

  const SearchBarWidget({
    super.key,
    this.onSearch,
    this.hintText = '搜索医院、陪诊师、服务...',
    this.autofocus = false,
    this.enabled = true,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: ThemeConfig.cardColor,
        borderRadius: BorderRadius.circular(ThemeConfig.borderRadiusMedium),
        border: Border.all(color: ThemeConfig.borderColor),
        boxShadow: ThemeConfig.shadowLevel1,
      ),
      child: Row(
        children: [
          // 搜索图标
          Padding(
            padding: EdgeInsets.only(
              left: ThemeConfig.spacingM,
              right: ThemeConfig.spacingS,
            ),
            child: Icon(
              Icons.search,
              color: ThemeConfig.textSecondaryColor,
              size: 20,
            ),
          ),
          // 输入框
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: autofocus,
              enabled: enabled,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                  fontSize: ThemeConfig.fontSizeBody2,
                  color: ThemeConfig.textHintColor,
                ),
                border: InputBorder.none,
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
          // 语音搜索按钮
          if (enabled)
            IconButton(
              icon: Icon(
                Icons.mic_none,
                color: ThemeConfig.textSecondaryColor,
                size: 20,
              ),
              onPressed: () {
                // TODO: 实现语音搜索
              },
            ),
        ],
      ),
    );
  }
}

// 带过滤器的搜索栏
class FilterSearchBar extends StatefulWidget {
  final ValueChanged<String>? onSearch;
  final VoidCallback? onFilterTap;
  final String hintText;
  final String filterText;
  final bool showFilter;

  const FilterSearchBar({
    super.key,
    this.onSearch,
    this.onFilterTap,
    this.hintText = '搜索...',
    this.filterText = '筛选',
    this.showFilter = true,
  });

  @override
  State<FilterSearchBar> createState() => _FilterSearchBarState();
}

class _FilterSearchBarState extends State<FilterSearchBar> {
  final TextEditingController _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _hasText = _controller.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clearText() {
    _controller.clear();
    widget.onSearch?.call('');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: ThemeConfig.cardColor,
        borderRadius: BorderRadius.circular(ThemeConfig.borderRadiusMedium),
        border: Border.all(color: ThemeConfig.borderColor),
      ),
      child: Row(
        children: [
          // 搜索图标
          Padding(
            padding: EdgeInsets.only(
              left: ThemeConfig.spacingM,
              right: ThemeConfig.spacingS,
            ),
            child: Icon(
              Icons.search,
              color: ThemeConfig.textSecondaryColor,
              size: 20,
            ),
          ),
          // 输入框
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyle(
                  fontSize: ThemeConfig.fontSizeBody2,
                  color: ThemeConfig.textHintColor,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: TextStyle(
                fontSize: ThemeConfig.fontSizeBody2,
                color: ThemeConfig.textPrimaryColor,
              ),
              onChanged: widget.onSearch,
              onSubmitted: widget.onSearch,
            ),
          ),
          // 清除按钮
          if (_hasText)
            IconButton(
              icon: Icon(
                Icons.clear,
                color: ThemeConfig.textSecondaryColor,
                size: 18,
              ),
              onPressed: _clearText,
            ),
          // 分割线
          if (widget.showFilter && _hasText)
            Container(
              width: 1,
              height: 24,
              color: ThemeConfig.borderColor,
            ),
          // 筛选按钮
          if (widget.showFilter)
            Padding(
              padding: EdgeInsets.only(
                left: ThemeConfig.spacingS,
                right: ThemeConfig.spacingM,
              ),
              child: GestureDetector(
                onTap: widget.onFilterTap,
                child: Row(
                  children: [
                    Icon(
                      Icons.filter_list,
                      color: ThemeConfig.textSecondaryColor,
                      size: 18,
                    ),
                    SizedBox(width: ThemeConfig.spacingXS),
                    Text(
                      widget.filterText,
                      style: TextStyle(
                        fontSize: ThemeConfig.fontSizeBody2,
                        color: ThemeConfig.textSecondaryColor,
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
}

// 位置搜索栏
class LocationSearchBar extends StatelessWidget {
  final String location;
  final VoidCallback? onLocationTap;
  final ValueChanged<String>? onSearch;
  final String hintText;

  const LocationSearchBar({
    super.key,
    required this.location,
    this.onLocationTap,
    this.onSearch,
    this.hintText = '搜索医院、科室、医生...',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 位置栏
        GestureDetector(
          onTap: onLocationTap,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: ThemeConfig.spacingM,
              vertical: ThemeConfig.spacingS,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: ThemeConfig.primaryColor,
                  size: 18,
                ),
                SizedBox(width: ThemeConfig.spacingXS),
                Expanded(
                  child: Text(
                    location,
                    style: TextStyle(
                      fontSize: ThemeConfig.fontSizeBody2,
                      color: ThemeConfig.textPrimaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: ThemeConfig.textSecondaryColor,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        // 搜索栏
        Padding(
          padding: EdgeInsets.symmetric(horizontal: ThemeConfig.spacingM),
          child: SearchBarWidget(
            onSearch: onSearch,
            hintText: hintText,
          ),
        ),
      ],
    );
  }
}

// 分类搜索栏
class CategorySearchBar extends StatelessWidget {
  final List<String> categories;
  final int selectedCategory;
  final ValueChanged<int>? onCategoryChanged;
  final ValueChanged<String>? onSearch;
  final String hintText;

  const CategorySearchBar({
    super.key,
    required this.categories,
    this.selectedCategory = 0,
    this.onCategoryChanged,
    this.onSearch,
    this.hintText = '搜索...',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 分类标签
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final isSelected = index == selectedCategory;
              return Padding(
                padding: EdgeInsets.only(
                  left: index == 0 ? ThemeConfig.spacingM : ThemeConfig.spacingS,
                  right: index == categories.length - 1
                      ? ThemeConfig.spacingM
                      : 0,
                ),
                child: GestureDetector(
                  onTap: () => onCategoryChanged?.call(index),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: ThemeConfig.spacingM,
                      vertical: ThemeConfig.spacingS,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? ThemeConfig.primaryColor
                          : ThemeConfig.cardColor,
                      borderRadius:
                          BorderRadius.circular(ThemeConfig.borderRadiusFull),
                      border: Border.all(
                        color: isSelected
                            ? ThemeConfig.primaryColor
                            : ThemeConfig.borderColor,
                      ),
                    ),
                    child: Text(
                      categories[index],
                      style: TextStyle(
                        fontSize: ThemeConfig.fontSizeBody2,
                        color: isSelected
                            ? Colors.white
                            : ThemeConfig.textSecondaryColor,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: ThemeConfig.spacingM),
        // 搜索栏
        Padding(
          padding: EdgeInsets.symmetric(horizontal: ThemeConfig.spacingM),
          child: SearchBarWidget(
            onSearch: onSearch,
            hintText: hintText,
          ),
        ),
      ],
    );
  }
}