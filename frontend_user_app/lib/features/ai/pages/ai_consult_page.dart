import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_colors.dart';
import '../../../core/config/app_text_styles.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';

class AiConsultPage extends StatefulWidget {
  const AiConsultPage({super.key});

  @override
  State<AiConsultPage> createState() => _AiConsultPageState();
}

class _AiConsultPageState extends State<AiConsultPage> {
  final TextEditingController _symptomsController = TextEditingController();
  final TextEditingController _reportController = TextEditingController();
  
  int _selectedTab = 0; // 0: 症状咨询, 1: 报告解读
  bool _isLoading = false;
  String? _aiResponse;
  String? _reportAnalysis;
  
  final List<String> _commonSymptoms = [
    '头痛', '发热', '咳嗽', '腹痛', '乏力',
    '头晕', '胸闷', '恶心', '失眠', '关节痛'
  ];
  
  final List<String> _reportTypes = [
    '血常规', '尿常规', '肝功能', '肾功能',
    '心电图', 'B超', 'CT', 'MRI'
  ];
  
  @override
  void dispose() {
    _symptomsController.dispose();
    _reportController.dispose();
    super.dispose();
  }
  
  Future<void> _consultSymptoms() async {
    final symptoms = _symptomsController.text.trim();
    if (symptoms.isEmpty) return;
    
    setState(() {
      _isLoading = true;
      _aiResponse = null;
    });
    
    try {
      final apiService = context.read<ApiService>();
      final response = await apiService.post('/ai/consult', {
        'symptoms': symptoms,
      });
      
      if (response['success']) {
        setState(() {
          _aiResponse = response['data']['diagnosis'];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('咨询失败: ${response['error']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('咨询失败: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _analyzeReport() async {
    final report = _reportController.text.trim();
    if (report.isEmpty) return;
    
    setState(() {
      _isLoading = true;
      _reportAnalysis = null;
    });
    
    try {
      final apiService = context.read<ApiService>();
      final response = await apiService.post('/ai/report', {
        'report_text': report,
        'report_type': '血常规', // 实际应从选择器获取
      });
      
      if (response['success']) {
        setState(() {
          _reportAnalysis = response['data']['analysis'];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('分析失败: ${response['error']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('分析失败: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  void _addSymptom(String symptom) {
    final current = _symptomsController.text;
    if (current.isNotEmpty && !current.endsWith('，')) {
      _symptomsController.text = '$current，$symptom';
    } else {
      _symptomsController.text = '$current$symptom';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI问诊'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 标签页
            Container(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTabButton(0, '症状咨询'),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: _buildTabButton(1, '报告解读'),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24.h),
            
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: _selectedTab == 0
                    ? _buildSymptomsConsultation()
                    : _buildReportAnalysis(),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTabButton(int index, String title) {
    final isSelected = _selectedTab == index;
    
    return AppButton.outline(
      text: title,
      backgroundColor: isSelected ? AppColors.primary : Colors.white,
      textColor: isSelected ? Colors.white : AppColors.primary,
      borderColor: isSelected ? AppColors.primary : AppColors.gray300,
      onPressed: () {
        setState(() {
          _selectedTab = index;
          _aiResponse = null;
          _reportAnalysis = null;
        });
      },
    );
  }
  
  Widget _buildSymptomsConsultation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '描述您的症状',
          style: AppTextStyles.heading3,
        ),
        SizedBox(height: 16.h),
        
        AppTextField(
          controller: _symptomsController,
          hintText: '例如：头痛、发热、咳嗽3天',
          maxLines: 4,
        ),
        
        SizedBox(height: 16.h),
        
        // 常见症状
        Text(
          '常见症状',
          style: AppTextStyles.body1.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12.h),
        
        Wrap(
          spacing: 12.w,
          runSpacing: 12.h,
          children: _commonSymptoms.map((symptom) {
            return ChoiceChip(
              label: Text(symptom),
              selected: false,
              onSelected: (_) => _addSymptom(symptom),
              backgroundColor: AppColors.gray100,
              selectedColor: AppColors.primary.withOpacity(0.1),
              labelStyle: AppTextStyles.body2.copyWith(
                color: AppColors.gray800,
              ),
            );
          }).toList(),
        ),
        
        SizedBox(height: 32.h),
        
        AppButton(
          text: '开始咨询',
          isLoading: _isLoading,
          onPressed: _consultSymptoms,
        ),
        
        SizedBox(height: 32.h),
        
        if (_aiResponse != null) ...[
          Text(
            'AI分析结果',
            style: AppTextStyles.heading3,
          ),
          SizedBox(height: 16.h),
          
          AppCard(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _aiResponse!,
                  style: AppTextStyles.body1,
                ),
                SizedBox(height: 16.h),
                
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.w),
                    border: Border.all(
                      color: AppColors.warning.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber,
                        size: 20.w,
                        color: AppColors.warning,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          '重要提示：本建议由AI生成，仅供参考，不能替代专业医生的诊断。如有不适，请及时就医。',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 24.h),
          
          // 后续操作
          Row(
            children: [
              Expanded(
                child: AppButton.outline(
                  text: '预约陪诊',
                  icon: Icons.calendar_today,
                  onPressed: () {
                    // 跳转到预约页面
                  },
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: AppButton.outline(
                  text: '联系客服',
                  icon: Icons.chat,
                  onPressed: () {
                    // 跳转到客服页面
                  },
                ),
              ),
            ],
          ),
        ],
        
        SizedBox(height: 40.h),
      ],
    );
  }
  
  Widget _buildReportAnalysis() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '上传或输入报告内容',
          style: AppTextStyles.heading3,
        ),
        SizedBox(height: 16.h),
        
        // 报告类型选择
        Text(
          '报告类型',
          style: AppTextStyles.body1.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12.h),
        
        Wrap(
          spacing: 12.w,
          runSpacing: 12.h,
          children: _reportTypes.map((type) {
            return ChoiceChip(
              label: Text(type),
              selected: false,
              onSelected: (_) {
                // 选择报告类型
              },
              backgroundColor: AppColors.gray100,
              selectedColor: AppColors.primary.withOpacity(0.1),
              labelStyle: AppTextStyles.body2.copyWith(
                color: AppColors.gray800,
              ),
            );
          }).toList(),
        ),
        
        SizedBox(height: 24.h),
        
        // 报告内容输入
        AppTextField(
          controller: _reportController,
          hintText: '请输入或粘贴您的检查报告内容...',
          maxLines: 8,
        ),
        
        SizedBox(height: 16.h),
        
        // 上传报告按钮
        AppButton.outline(
          text: '上传报告图片',
          icon: Icons.upload,
          onPressed: () {
            // 上传报告图片
          },
        ),
        
        SizedBox(height: 32.h),
        
        AppButton(
          text: '开始解读',
          isLoading: _isLoading,
          onPressed: _analyzeReport,
        ),
        
        SizedBox(height: 32.h),
        
        if (_reportAnalysis != null) ...[
          Text(
            '报告解读结果',
            style: AppTextStyles.heading3,
          ),
          SizedBox(height: 16.h),
          
          AppCard(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _reportAnalysis!,
                  style: AppTextStyles.body1,
                ),
                SizedBox(height: 16.h),
                
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.w),
                    border: Border.all(
                      color: AppColors.warning.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber,
                        size: 20.w,
                        color: AppColors.warning,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          '重要提示：本解读由AI生成，仅供参考，不能替代专业医生的诊断。请以医生的专业意见为准。',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 24.h),
          
          // 后续操作
          Column(
            children: [
              AppButton.outline(
                text: '保存解读结果',
                icon: Icons.save,
                onPressed: () {
                  // 保存解读结果
                },
              ),
              SizedBox(height: 16.h),
              AppButton.outline(
                text: '分享给医生',
                icon: Icons.share,
                onPressed: () {
                  // 分享功能
                },
              ),
            ],
          ),
        ],
        
        SizedBox(height: 40.h),
      ],
    );
  }
}