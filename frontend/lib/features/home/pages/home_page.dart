import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_colors.dart';
import '../../../core/config/app_text_styles.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/icon_button.dart';
import '../../order/pages/order_create_page.dart';
import '../../ai/pages/ai_consult_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const _HomeTab(),
    const _OrdersTab(),
    const _ChatTab(),
    const _ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.gray500,
        selectedLabelStyle: AppTextStyles.caption,
        unselectedLabelStyle: AppTextStyles.caption,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: '首页',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined),
            activeIcon: Icon(Icons.list_alt),
            label: '订单',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: '消息',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().user;
    
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 120.h,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              color: AppColors.primary,
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 16.h),
                      Text(
                        '你好，${user?.name ?? '用户'}',
                        style: AppTextStyles.heading2.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '温暖陪诊，安心就医',
                        style: AppTextStyles.body1.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        
        SliverPadding(
          padding: EdgeInsets.all(24.w),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // 快速入口
              Row(
                children: [
                  Expanded(
                    child: AppIconButton(
                      icon: Icons.add_circle_outline,
                      label: '预约陪诊',
                      onTap: () => context.go('/order/create'),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: AppIconButton(
                      icon: Icons.medical_services_outlined,
                      label: 'AI问诊',
                      onTap: () => context.go('/ai/consult'),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: AppIconButton(
                      icon: Icons.history,
                      label: '历史订单',
                      onTap: () => context.go('/orders'),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 32.h),
              
              // 推荐陪诊师
              Text(
                '推荐陪诊师',
                style: AppTextStyles.heading3,
              ),
              SizedBox(height: 16.h),
              
              // 陪诊师列表
              SizedBox(
                height: 180.h,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 5,
                  separatorBuilder: (_, __) => SizedBox(width: 16.w),
                  itemBuilder: (context, index) {
                    return SizedBox(
                      width: 140.w,
                      child: AppCard(
                        padding: EdgeInsets.all(12.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 30.w,
                              backgroundColor: AppColors.gray200,
                              child: Icon(
                                Icons.person,
                                size: 30.w,
                                color: AppColors.gray500,
                              ),
                            ),
                            SizedBox(height: 12.h),
                            Text(
                              '张医生',
                              style: AppTextStyles.body1.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              '5年陪诊经验',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.gray600,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Row(
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 14.w,
                                  color: AppColors.warning,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  '4.9',
                                  style: AppTextStyles.caption.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              SizedBox(height: 32.h),
              
              // 附近医院
              Text(
                '附近医院',
                style: AppTextStyles.heading3,
              ),
              SizedBox(height: 16.h),
              
              // 医院列表
              Column(
                children: List.generate(3, (index) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 16.h),
                    child: AppCard(
                      padding: EdgeInsets.all(16.w),
                      child: Row(
                        children: [
                          Container(
                            width: 60.w,
                            height: 60.w,
                            decoration: BoxDecoration(
                              color: AppColors.gray100,
                              borderRadius: BorderRadius.circular(8.w),
                            ),
                            child: Icon(
                              Icons.local_hospital,
                              size: 30.w,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '复旦大学附属中山医院',
                                  style: AppTextStyles.body1.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  '徐汇区枫林路180号',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.gray600,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  '距离2.5km',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _OrdersTab extends StatelessWidget {
  const _OrdersTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.list_alt,
            size: 60.w,
            color: AppColors.gray400,
          ),
          SizedBox(height: 16.h),
          Text(
            '订单页面',
            style: AppTextStyles.heading3,
          ),
          SizedBox(height: 8.h),
          Text(
            '查看和管理您的所有订单',
            style: AppTextStyles.body1.copyWith(
              color: AppColors.gray600,
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: () => context.go('/orders'),
            child: const Text('查看订单'),
          ),
        ],
      ),
    );
  }
}

class _ChatTab extends StatelessWidget {
  const _ChatTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 60.w,
            color: AppColors.gray400,
          ),
          SizedBox(height: 16.h),
          Text(
            '消息中心',
            style: AppTextStyles.heading3,
          ),
          SizedBox(height: 8.h),
          Text(
            '与陪诊师实时沟通',
            style: AppTextStyles.body1.copyWith(
              color: AppColors.gray600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline,
            size: 60.w,
            color: AppColors.gray400,
          ),
          SizedBox(height: 16.h),
          Text(
            '个人中心',
            style: AppTextStyles.heading3,
          ),
          SizedBox(height: 8.h),
          Text(
            '管理您的账户和设置',
            style: AppTextStyles.body1.copyWith(
              color: AppColors.gray600,
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: () => context.go('/profile'),
            child: const Text('个人资料'),
          ),
        ],
      ),
    );
  }
}