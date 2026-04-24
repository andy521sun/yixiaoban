import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_colors.dart';
import '../../../core/config/app_text_styles.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';

class OrderCreatePage extends StatefulWidget {
  const OrderCreatePage({super.key});

  @override
  State<OrderCreatePage> createState() => _OrderCreatePageState();
}

class _OrderCreatePageState extends State<OrderCreatePage> {
  final _formKey = GlobalKey<FormState>();
  
  // 表单控制器
  final _hospitalController = TextEditingController();
  final _departmentController = TextEditingController();
  final _doctorController = TextEditingController();
  final _addressController = TextEditingController();
  final _requirementsController = TextEditingController();
  
  // 选择器状态
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _serviceType = 'hourly';
  double _hours = 2.0;
  
  // 计算费用
  double get _hourlyRate => 80.0;
  double get _platformFeeRate => 0.15;
  double get _baseAmount => _hours * _hourlyRate;
  double get _platformFee => _baseAmount * _platformFeeRate;
  double get _totalAmount => _baseAmount + _platformFee;
  
  // 加载状态
  bool _isLoading = false;
  
  @override
  void dispose() {
    _hospitalController.dispose();
    _departmentController.dispose();
    _doctorController.dispose();
    _addressController.dispose();
    _requirementsController.dispose();
    super.dispose();
  }
  
  // 选择日期
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }
  
  // 选择时间
  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    
    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
    }
  }
  
  // 提交订单
  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择预约时间')),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final apiService = context.read<ApiService>();
      
      // 组合日期时间
      final appointmentTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
      
      final response = await apiService.post('/orders', {
        'hospital_id': 1, // 实际应从选择器获取
        'department': _departmentController.text.trim(),
        'doctor_name': _doctorController.text.trim(),
        'appointment_time': appointmentTime.toIso8601String(),
        'address': _addressController.text.trim(),
        'requirements': _requirementsController.text.trim(),
        'service_type': _serviceType,
        'hours': _hours,
      });
      
      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('订单创建成功')),
        );
        
        // 跳转到支付页面或订单详情
        context.go('/order/detail/${response['data']['order_no']}');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('创建失败: ${response['error']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('创建失败: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('预约陪诊'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 医院信息
                Text(
                  '医院信息',
                  style: AppTextStyles.heading3,
                ),
                SizedBox(height: 16.h),
                
                AppTextField(
                  controller: _hospitalController,
                  label: '医院名称',
                  hintText: '请输入医院名称',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入医院名称';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.h),
                
                AppTextField(
                  controller: _departmentController,
                  label: '科室',
                  hintText: '请输入科室名称',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入科室名称';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.h),
                
                AppTextField(
                  controller: _doctorController,
                  label: '医生姓名（选填）',
                  hintText: '请输入医生姓名',
                ),
                SizedBox(height: 16.h),
                
                AppTextField(
                  controller: _addressController,
                  label: '医院地址',
                  hintText: '请输入医院详细地址',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入医院地址';
                    }
                    return null;
                  },
                ),
                
                SizedBox(height: 32.h),
                
                // 预约时间
                Text(
                  '预约时间',
                  style: AppTextStyles.heading3,
                ),
                SizedBox(height: 16.h),
                
                Row(
                  children: [
                    Expanded(
                      child: AppCard(
                        padding: EdgeInsets.all(16.w),
                        onTap: _selectDate,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedDate == null
                                  ? '选择日期'
                                  : DateFormat('yyyy-MM-dd').format(_selectedDate!),
                              style: AppTextStyles.body1.copyWith(
                                color: _selectedDate == null
                                    ? AppColors.gray500
                                    : AppColors.gray900,
                              ),
                            ),
                            Icon(
                              Icons.calendar_today,
                              size: 20.w,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: AppCard(
                        padding: EdgeInsets.all(16.w),
                        onTap: _selectTime,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedTime == null
                                  ? '选择时间'
                                  : _selectedTime!.format(context),
                              style: AppTextStyles.body1.copyWith(
                                color: _selectedTime == null
                                    ? AppColors.gray500
                                    : AppColors.gray900,
                              ),
                            ),
                            Icon(
                              Icons.access_time,
                              size: 20.w,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 32.h),
                
                // 服务类型
                Text(
                  '服务类型',
                  style: AppTextStyles.heading3,
                ),
                SizedBox(height: 16.h),
                
                Row(
                  children: [
                    _buildServiceTypeOption(
                      'hourly',
                      '小时陪诊',
                      '¥${_hourlyRate.toInt()}/小时',
                    ),
                    SizedBox(width: 16.w),
                    _buildServiceTypeOption(
                      'daily',
                      '全天陪诊',
                      '¥500/天',
                    ),
                  ],
                ),
                
                SizedBox(height: 32.h),
                
                // 服务时长（小时陪诊时显示）
                if (_serviceType == 'hourly') ...[
                  Text(
                    '服务时长',
                    style: AppTextStyles.heading3,
                  ),
                  SizedBox(height: 16.h),
                  
                  AppCard(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_hours.toInt()}小时',
                              style: AppTextStyles.heading3,
                            ),
                            Text(
                              '¥${_baseAmount.toInt()}',
                              style: AppTextStyles.heading3.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        
                        Slider(
                          value: _hours,
                          min: 1,
                          max: 8,
                          divisions: 7,
                          label: '${_hours.toInt()}小时',
                          onChanged: (value) {
                            setState(() => _hours = value);
                          },
                        ),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('1小时', style: AppTextStyles.caption),
                            Text('8小时', style: AppTextStyles.caption),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 32.h),
                ],
                
                // 特殊要求
                Text(
                  '特殊要求',
                  style: AppTextStyles.heading3,
                ),
                SizedBox(height: 16.h),
                
                AppTextField(
                  controller: _requirementsController,
                  label: '请描述您的特殊需求',
                  hintText: '例如：需要轮椅、需要翻译、有特殊病史等',
                  maxLines: 4,
                ),
                
                SizedBox(height: 32.h),
                
                // 费用明细
                AppCard(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('服务费用', style: AppTextStyles.body1),
                          Text(
                            '¥${_baseAmount.toStringAsFixed(2)}',
                            style: AppTextStyles.body1,
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('平台服务费', style: AppTextStyles.body1),
                          Text(
                            '¥${_platformFee.toStringAsFixed(2)}',
                            style: AppTextStyles.body1,
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      
                      Divider(color: AppColors.gray300),
                      SizedBox(height: 12.h),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '总计',
                            style: AppTextStyles.heading3,
                          ),
                          Text(
                            '¥${_totalAmount.toStringAsFixed(2)}',
                            style: AppTextStyles.heading3.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 40.h),
                
                // 提交按钮
                AppButton(
                  text: '立即预约',
                  isLoading: _isLoading,
                  onPressed: _submitOrder,
                ),
                
                SizedBox(height: 16.h),
                
                // 服务协议
                Center(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '提交即表示同意',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.gray600,
                          ),
                        ),
                        TextSpan(
                          text: '《医小伴服务协议》',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildServiceTypeOption(String value, String title, String price) {
    final isSelected = _serviceType == value;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _serviceType = value;
            if (value == 'daily') {
              _hours = 8.0; // 全天服务按8小时计算
            }
          });
        },
        child: AppCard(
          padding: EdgeInsets.all(16.w),
          borderColor: isSelected ? AppColors.primary : AppColors.gray300,
          backgroundColor: isSelected 
              ? AppColors.primary.withOpacity(0.05)
              : Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 24.w,
                    height: 24.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected 
                            ? AppColors.primary 
                            : AppColors.gray400,
                        width: 2.w,
                      ),
                    ),
                    child: isSelected
                        ? Center(
                            child: Container(
                              width: 12.w,
                              height: 12.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary,
                              ),
                            ),
                          )
                        : null,
                  ),
                  Text(
                    price,
                    style: AppTextStyles.body1.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Text(
                title,
                style: AppTextStyles.body1.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}