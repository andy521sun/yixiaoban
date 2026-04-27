import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/models/hospital.dart';
import '../../../core/models/companion.dart';
import '../../../core/services/api_service.dart';
import '../../../core/providers/appointment_provider.dart';
import '../../widgets/hospital_card.dart';
import '../../widgets/companion_card.dart';

class AppointmentSelectPage extends StatefulWidget {
  const AppointmentSelectPage({Key? key}) : super(key: key);

  @override
  _AppointmentSelectPageState createState() => _AppointmentSelectPageState();
}

class _AppointmentSelectPageState extends State<AppointmentSelectPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  
  // 表单数据
  Hospital? _selectedHospital;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  Companion? _selectedCompanion;
  String _selectedServiceType = '普通陪诊';
  int _selectedDuration = 120; // 分钟
  
  // 服务类型选项
  final List<String> _serviceTypes = [
    '普通陪诊',
    '专业陪诊',
    '急诊陪诊',
    '长期陪护',
  ];
  
  // 服务时长选项
  final List<int> _durations = [60, 120, 180, 240, 360];
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    // 这里可以加载默认数据
    // 实际开发中可以从API加载推荐医院和陪诊师
  }
  
  void _nextStep() {
    if (_currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep++;
      });
    }
  }
  
  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep--;
      });
    }
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }
  
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }
  
  void _confirmAppointment() {
    if (_selectedHospital == null || 
        _selectedDate == null || 
        _selectedTime == null || 
        _selectedCompanion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请完成所有必填项'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // 保存预约数据到Provider
    final appointmentProvider = Provider.of<AppointmentProvider>(context, listen: false);
    appointmentProvider.setAppointmentData(
      hospital: _selectedHospital!,
      date: _selectedDate!,
      time: _selectedTime!,
      companion: _selectedCompanion!,
      serviceType: _selectedServiceType,
      duration: _selectedDuration,
    );
    
    // 导航到确认页面
    Navigator.pushNamed(context, '/appointment/confirm');
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('预约陪诊服务'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 步骤指示器
          _buildStepIndicator(),
          
          // 页面内容
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                // 步骤1: 选择医院
                _buildHospitalSelection(),
                
                // 步骤2: 选择时间
                _buildTimeSelection(),
                
                // 步骤3: 选择陪诊师
                _buildCompanionSelection(),
                
                // 步骤4: 选择服务
                _buildServiceSelection(),
              ],
            ),
          ),
          
          // 底部导航按钮
          _buildBottomNavigation(),
        ],
      ),
    );
  }
  
  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStepItem(0, '医院', _currentStep >= 0),
          _buildStepItem(1, '时间', _currentStep >= 1),
          _buildStepItem(2, '陪诊师', _currentStep >= 2),
          _buildStepItem(3, '服务', _currentStep >= 3),
        ],
      ),
    );
  }
  
  Widget _buildStepItem(int step, String title, bool isActive) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? Colors.blue : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${step + 1}',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.blue : Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
  
  Widget _buildHospitalSelection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '选择医院',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '请选择您需要就诊的医院',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          
          // 搜索框
          TextField(
            decoration: InputDecoration(
              hintText: '搜索医院名称或科室',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            onChanged: (value) {
              // 搜索逻辑
            },
          ),
          const SizedBox(height: 16),
          
          // 医院列表
          Expanded(
            child: FutureBuilder<List<Hospital>>(
              future: ApiService().getHospitals(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Text('加载失败: ${snapshot.error}'),
                  );
                }
                
                final hospitals = snapshot.data ?? [];
                
                return ListView.builder(
                  itemCount: hospitals.length,
                  itemBuilder: (context, index) {
                    final hospital = hospitals[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedHospital = hospital;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedHospital?.id == hospital.id
                                ? Colors.blue
                                : Colors.grey[200]!,
                            width: _selectedHospital?.id == hospital.id ? 2 : 1,
                          ),
                        ),
                        child: HospitalCard(hospital: hospital),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTimeSelection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '选择时间',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '请选择您的就诊时间',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          
          // 日期选择
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const Icon(Icons.calendar_today, color: Colors.blue),
              title: Text(
                _selectedDate == null
                    ? '选择日期'
                    : DateFormat('yyyy年MM月dd日').format(_selectedDate!),
                style: TextStyle(
                  color: _selectedDate == null ? Colors.grey[500] : Colors.black,
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _selectDate(context),
            ),
          ),
          const SizedBox(height: 16),
          
          // 时间选择
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const Icon(Icons.access_time, color: Colors.blue),
              title: Text(
                _selectedTime == null
                    ? '选择时间'
                    : _selectedTime!.format(context),
                style: TextStyle(
                  color: _selectedTime == null ? Colors.grey[500] : Colors.black,
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _selectTime(context),
            ),
          ),
          const SizedBox(height: 24),
          
          // 时间建议
          Text(
            '建议时间',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildTimeSuggestion('上午', '08:00-12:00'),
              _buildTimeSuggestion('下午', '14:00-18:00'),
              _buildTimeSuggestion('晚上', '18:00-22:00'),
              _buildTimeSuggestion('明天', '全天'),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildTimeSuggestion(String period, String timeRange) {
    return GestureDetector(
      onTap: () {
        // 设置建议时间
        final now = DateTime.now();
        setState(() {
          _selectedDate = now.add(const Duration(days: 1));
          _selectedTime = const TimeOfDay(hour: 9, minute: 0);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue[100]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              period,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            Text(
              timeRange,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCompanionSelection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '选择陪诊师',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '请选择为您服务的陪诊师',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          
          // 筛选条件
          Row(
            children: [
              _buildFilterChip('全部', true),
              const SizedBox(width: 8),
              _buildFilterChip('在线', false),
              const SizedBox(width: 8),
              _buildFilterChip('评分高', false),
              const SizedBox(width: 8),
              _buildFilterChip('经验丰富', false),
            ],
          ),
          const SizedBox(height: 16),
          
          // 陪诊师列表
          Expanded(
            child: FutureBuilder<List<Companion>>(
              future: ApiService().getCompanions(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Text('加载失败: ${snapshot.error}'),
                  );
                }
                
                final companions = snapshot.data ?? [];
                
                return ListView.builder(
                  itemCount: companions.length,
                  itemBuilder: (context, index) {
                    final companion = companions[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCompanion = companion;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedCompanion?.id == companion.id
                                ? Colors.blue
                                : Colors.grey[200]!,
                            width: _selectedCompanion?.id == companion.id ? 2 : 1,
                          ),
                        ),
                        child: CompanionCard(companion: companion),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterChip(String label, bool isSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        // 筛选逻辑
      },
      backgroundColor: Colors.grey[100],
      selectedColor: Colors.blue[100],
      checkmarkColor: Colors.blue,
      labelStyle: TextStyle(
        color: isSelected ? Colors.blue : Colors.grey[700],
      ),
    );
  }
  
  Widget _buildServiceSelection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '选择服务',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '请选择您需要的服务类型和时长',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          
          // 服务类型选择
          Text(
            '服务类型',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _serviceTypes.map((type) {
              return ChoiceChip(
                label: Text(type),
                selected: _selectedServiceType == type,
                onSelected: (selected) {
                  setState(() {
                    _selectedServiceType = type;
                  });
                },
              );
            }).toList(),
          ),
          
          const SizedBox(height: 24),
          
          // 服务时长选择
          Text(
            '服务时长',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _durations.map((duration) {
              final hours = duration ~/ 60;
              final minutes = duration % 60;
              final label = minutes > 0 ? '$hours小时$minutes分钟' : '$hours小时';
              
              return ChoiceChip(
                label: Text(label),
                selected: _selectedDuration == duration,
                onSelected: (selected) {
                  setState(() {
                    _selectedDuration = duration;
                  });
                },
              );
            }).toList(),
          ),
          
          const SizedBox(height: 32),
          
          // 价格预览
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '费用