import 'package:flutter/material.dart';

/// 医生选择页 — 按科室筛选 + 医生列表 + 价格展示
class DoctorSelectPage extends StatefulWidget {
  const DoctorSelectPage({super.key});

  @override
  State<DoctorSelectPage> createState() => _DoctorSelectPageState();
}

class _DoctorSelectPageState extends State<DoctorSelectPage> {
  Map<String, dynamic>? _symptomData; // 上一步传来的症状数据
  // 科室筛选
  final _departments = ['全部', '内科', '外科', '儿科', '妇科', '皮肤科', '眼科', '耳鼻喉科', '口腔科', '精神科', '中医科'];
  String _selectedDept = '全部';
  
  // 医生数据
  List<Map<String, dynamic>> _allDoctors = [];
  List<Map<String, dynamic>> _filteredDoctors = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDoctorList();
    // 读取问诊数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        _symptomData = args;
        debugPrint('[医生选择] 收到症状数据: $args');
      }
    });
  }

  Future<void> _loadDoctorList() async {
    try {
      // 从后端 API 获取医生列表
      final res = await (() async {
        // 模拟数据，实际项目中调用 _api 的 getDoctors()
        // 目前 APIService 还没有 getDoctors 方法，先模拟
        return {
          'success': true,
          'data': [
            {
              'id': 'doc_1',
              'name': '张明华',
              'title': '主任医师',
              'department': '内科',
              'hospital': '上海交通大学医学院附属瑞金医院',
              'avatar': null,
              'rating': 4.8,
              'consultation_count': 1256,
              'introduction': '从事内科临床工作30余年，擅长呼吸系统疾病、高血压、糖尿病等慢性病诊治。',
              'text_price': 19.9,
              'phone_price': 39.9,
              'video_price': 59.9,
              'is_online': true,
            },
            {
              'id': 'doc_2',
              'name': '李芳',
              'title': '副主任医师',
              'department': '儿科',
              'hospital': '复旦大学附属儿科医院',
              'avatar': null,
              'rating': 4.9,
              'consultation_count': 2341,
              'introduction': '儿科临床经验丰富，尤其擅长儿童呼吸系统疾病、儿童过敏性疾病诊治。',
              'text_price': 29.9,
              'phone_price': 49.9,
              'video_price': 69.9,
              'is_online': true,
            },
            {
              'id': 'doc_3',
              'name': '王建国',
              'title': '主治医师',
              'department': '皮肤科',
              'hospital': '上海华山医院',
              'avatar': null,
              'rating': 4.7,
              'consultation_count': 876,
              'introduction': '专业治疗湿疹、荨麻疹、痤疮等常见皮肤病，多年临床经验。',
              'text_price': 19.9,
              'phone_price': 29.9,
              'video_price': 49.9,
              'is_online': false,
            },
            {
              'id': 'doc_4',
              'name': '陈小红',
              'title': '主任医师',
              'department': '妇科',
              'hospital': '上海市第一妇婴保健院',
              'avatar': null,
              'rating': 4.8,
              'consultation_count': 1892,
              'introduction': '妇科常见病及疑难杂症诊治，尤其擅长妇科内分泌疾病。',
              'text_price': 29.9,
              'phone_price': 49.9,
              'video_price': 79.9,
              'is_online': true,
            },
            {
              'id': 'doc_5',
              'name': '赵明',
              'title': '主治医师',
              'department': '内科',
              'hospital': '上海市第六人民医院',
              'avatar': null,
              'rating': 4.6,
              'consultation_count': 654,
              'introduction': '内科常见病诊治，擅长消化系统疾病及慢性病管理。',
              'text_price': 14.9,
              'phone_price': 24.9,
              'video_price': 39.9,
              'is_online': true,
            },
            {
              'id': 'doc_6',
              'name': '刘丽华',
              'title': '副主任医师',
              'department': '耳鼻喉科',
              'hospital': '上海五官科医院',
              'avatar': null,
              'rating': 4.7,
              'consultation_count': 1123,
              'introduction': '擅长中耳炎、鼻炎、咽炎、声带疾病等耳鼻喉科常见病及多发病诊治。',
              'text_price': 24.9,
              'phone_price': 44.9,
              'video_price': 64.9,
              'is_online': false,
            },
          ],
        };
      })();

      if (!mounted) return;
      setState(() {
        _allDoctors = (res['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        _filterByDepartment();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      debugPrint('获取医生列表失败: $e');
    }
  }

  void _filterByDepartment() {
    setState(() {
      if (_selectedDept == '全部') {
        _filteredDoctors = List.from(_allDoctors);
      } else {
        _filteredDoctors = _allDoctors
            .where((d) => d['department'] == _selectedDept)
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('选择医生'),
      ),
      body: Column(
        children: [
          // 科室筛选栏
          _buildDepartmentFilter(),
          // 医生列表
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredDoctors.isEmpty
                    ? _buildEmpty()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredDoctors.length,
                        itemBuilder: (_, i) => _buildDoctorCard(_filteredDoctors[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentFilter() {
    return Container(
      height: 50,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _departments.length,
        itemBuilder: (_, i) {
          final dept = _departments[i];
          final selected = dept == _selectedDept;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: GestureDetector(
              onTap: () {
                _selectedDept = dept;
                _filterByDepartment();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFF1A73E8) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(
                  dept,
                  style: TextStyle(
                    color: selected ? Colors.white : const Color(0xFF5F6368),
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDoctorCard(Map<String, dynamic> doctor) {
    final name = doctor['name'] as String? ?? '';
    final title = doctor['title'] as String? ?? '';
    final dept = doctor['department'] as String? ?? '';
    final hospital = doctor['hospital'] as String? ?? '';
    final rating = (doctor['rating'] as num?)?.toDouble() ?? 0;
    final count = (doctor['consultation_count'] as num?)?.toInt() ?? 0;
    final intro = doctor['introduction'] as String? ?? '';
    final isOnline = doctor['is_online'] as bool? ?? false;

    // 根据问诊类型显示对应价格
    final consultationType = _symptomData?['type'] as String? ?? 'text';
    double price;
    switch (consultationType) {
      case 'phone': price = (doctor['phone_price'] as num?)?.toDouble() ?? 39.9;
      case 'video': price = (doctor['video_price'] as num?)?.toDouble() ?? 59.9;
      default: price = (doctor['text_price'] as num?)?.toDouble() ?? 19.9;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _startConsultation(doctor, consultationType);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 医生基本信息
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 头像
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFF1A73E8).withValues(alpha: 0.1),
                    child: Text(
                      name.isNotEmpty ? name[0] : '医',
                      style: const TextStyle(
                        color: Color(0xFF1A73E8),
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F0FE),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(title,
                                style: const TextStyle(fontSize: 11, color: Color(0xFF1A73E8)),
                              ),
                            ),
                            if (isOnline) ...[
                              const SizedBox(width: 4),
                              Container(
                                width: 6, height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF34A853),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('$dept · $hospital',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star, size: 14, color: Colors.amber),
                            Text(' $rating ', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                            Text('· $count次咨询', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // 价格
                  Column(
                    children: [
                      Text('¥$price', style: const TextStyle(
                        color: Color(0xFFE37400),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      )),
                      const SizedBox(height: 2),
                      Text('${consultationType == 'text' ? '图文' : consultationType == 'phone' ? '电话' : '视频'}',
                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // 简介
              if (intro.isNotEmpty)
                Text(intro,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.4),
                ),
              const SizedBox(height: 12),
              // 按钮区
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => _showDoctorDetail(doctor),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      side: const BorderSide(color: Color(0xFF1A73E8)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('查看详情', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => _startConsultation(doctor, consultationType),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                    child: const Text('立即咨询'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDoctorDetail(Map<String, dynamic> doctor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.85,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(doctor['name'] as String? ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('${doctor['title']} · ${doctor['department']}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(doctor['hospital'] as String? ?? '',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
                const SizedBox(height: 16),
                const Text('医生简介', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(doctor['introduction'] as String? ?? '暂无简介',
                  style: TextStyle(color: Colors.grey[700], fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 24),
                const Text('服务价格', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                _buildPriceRow('图文咨询', '¥${doctor['text_price'] ?? '—'}'),
                _buildPriceRow('电话咨询', '¥${doctor['phone_price'] ?? '—'}'),
                _buildPriceRow('视频咨询', '¥${doctor['video_price'] ?? '—'}'),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPriceRow(String label, String price) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          Text(price, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFFE37400))),
        ],
      ),
    );
  }

  void _startConsultation(Map<String, dynamic> doctor, String type) {
    final data = {
      'doctor': doctor,
      'type': type,
      'symptomData': _symptomData,
    };
    Navigator.pushNamed(context, '/consultation/confirm', arguments: data);
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('暂无${_selectedDept}医生', style: TextStyle(color: Colors.grey[500], fontSize: 15)),
        ],
      ),
    );
  }
}
