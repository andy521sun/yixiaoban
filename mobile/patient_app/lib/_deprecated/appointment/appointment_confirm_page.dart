import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/models/hospital.dart';
import '../../../core/models/companion.dart';
import '../../../core/providers/appointment_provider.dart';
import '../../widgets/hospital_card.dart';
import '../../widgets/companion_card.dart';

class AppointmentConfirmPage extends StatefulWidget {
  const AppointmentConfirmPage({Key? key}) : super(key: key);

  @override
  _AppointmentConfirmPageState createState() => _AppointmentConfirmPageState();
}

class _AppointmentConfirmPageState extends State<AppointmentConfirmPage> {
  late Hospital _selectedHospital;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late Companion _selectedCompanion;
  late String _selectedServiceType;
  late int _selectedDuration;
  
  double _basePrice = 199.0;
  double _serviceFee = 30.0;
  double _totalPrice = 0.0;
  
  @override
  void initState() {
    super.initState();
    _loadAppointmentData();
    _calculatePrice();
  }
  
  void _loadAppointmentData() {
    final appointmentProvider = Provider.of<AppointmentProvider>(context, listen: false);
    
    _selectedHospital = appointmentProvider.hospital!;
    _selectedDate = appointmentProvider.date!;
    _selectedTime = appointmentProvider.time!;
    _selectedCompanion = appointmentProvider.companion!;
    _selectedServiceType = appointmentProvider.serviceType;
    _selectedDuration = appointmentProvider.duration;
  }
  
  void _calculatePrice() {
    // 基础价格
    double price = _basePrice;
    
    // 根据服务类型调整价格
    switch (_selectedServiceType) {
      case '专业陪诊':
        price *= 1.5;
        break;
      case '急诊陪诊':
        price *= 2.0;
        break;
      case '长期陪护':
        price *= 3.0;
        break;
    }
    
    // 根据时长调整价格
    final hours = _selectedDuration / 60;
    price *= hours;
    
    // 陪诊师等级加成
    if (_selectedCompanion.level == '高级') {
      price *= 1.3;
    } else if (_selectedCompanion.level == '专家') {
      price *= 1.5;
    }
    
    // 计算总价
    _totalPrice = price + _serviceFee;
  }
  
  void _submitAppointment() {
    // 显示加载对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在创建预约...'),
          ],
        ),
      ),
    );
    
    // 模拟API调用
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context); // 关闭加载对话框
      
      // 导航到支付页面
      Navigator.pushNamed(context, '/payment');
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final appointmentTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('确认预约'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 预约信息卡片
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
                      '预约信息',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // 医院信息
                    _buildInfoRow('🏥 医院', _selectedHospital.name),
                    const SizedBox(height: 12),
                    
                    // 时间信息
                    _buildInfoRow(
                      '⏰ 时间',
                      DateFormat('yyyy年MM月dd日 HH:mm').format(appointmentTime),
                    ),
                    const SizedBox(height: 12),
                    
                    // 陪诊师信息
                    _buildInfoRow('👤 陪诊师', _selectedCompanion.name),
                    const SizedBox(height: 12),
                    
                    // 服务类型
                    _buildInfoRow('💼 服务类型', _selectedServiceType),
                    const SizedBox(height: 12),
                    
                    // 服务时长
                    final hours = _selectedDuration ~/ 60;
                    final minutes = _selectedDuration % 60;
                    final durationText = minutes > 0 
                        ? '$hours小时$minutes分钟' 
                        : '$hours小时';
                    _buildInfoRow('⏱️ 服务时长', durationText),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // 医院详情卡片
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: HospitalCard(hospital: _selectedHospital),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // 陪诊师详情卡片
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: CompanionCard(companion: _selectedCompanion),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // 费用明细
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
                      '费用明细',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    _buildPriceRow('基础服务费', '¥${_basePrice.toStringAsFixed(2)}'),
                    const SizedBox(height: 8),
                    
                    _buildPriceRow('${_selectedServiceType}加成', '¥${(_basePrice * 0.5).toStringAsFixed(2)}'),
                    const SizedBox(height: 8),
                    
                    _buildPriceRow('时长费用（${hours}小时）', '¥${(_basePrice * hours).toStringAsFixed(2)}'),
                    const SizedBox(height: 8),
                    
                    if (_selectedCompanion.level != '普通')
                      _buildPriceRow('${_selectedCompanion.level}陪诊师加成', '¥${(_basePrice * 0.3).toStringAsFixed(2)}'),
                    
                    const SizedBox(height: 8),
                    _buildPriceRow('平台服务费', '¥${_serviceFee.toStringAsFixed(2)}'),
                    
                    const Divider(height: 24),
                    
                    _buildPriceRow(
                      '总计',
                      '¥${_totalPrice.toStringAsFixed(2)}',
                      isTotal: true,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // 用户协议
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: true,
                          onChanged: (value) {
                            // 同意协议逻辑
                          },
                        ),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: Theme.of(context).textTheme.bodySmall,
                              children: [
                                const TextSpan(text: '我已阅读并同意'),
                                TextSpan(
                                  text: '《医小伴用户服务协议》',
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                const TextSpan(text: '和'),
                                TextSpan(
                                  text: '《隐私政策》',
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
      
      // 底部操作栏
      bottomNavigationBar: _buildBottomBar(),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildPriceRow(String label, String price, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          price,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? Colors.red : Colors.black,
          ),
        ),
      ],
    );
  }
  
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 价格显示
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '总计',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                Text(
                  '¥${_totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
          
          // 提交按钮
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _submitAppointment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
              ),
              child: const Text(
                '确认并支付',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}