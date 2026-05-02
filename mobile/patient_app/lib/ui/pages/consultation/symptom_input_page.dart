import 'package:flutter/material.dart';

/// 症状描述填写页 — 结构化表单：主诉/现病史/既往史
class SymptomInputPage extends StatefulWidget {
  const SymptomInputPage({super.key});

  @override
  State<SymptomInputPage> createState() => _SymptomInputPageState();
}

class _SymptomInputPageState extends State<SymptomInputPage> {
  String _consultationType = 'text'; // text | phone | video
  final _mainComplaintController = TextEditingController();
  final _presentIllnessController = TextEditingController();
  final _pastHistoryController = TextEditingController();
  
  // 常见症状标签
  final _commonSymptoms = [
    '头痛', '发热', '咳嗽', '腹痛', '腹泻',
    '喉咙痛', '鼻塞', '呕吐', '头晕', '乏力',
    '关节痛', '皮疹', '失眠', '胸闷', '胃痛',
  ];
  
  final List<String> _selectedSymptoms = [];
  final List<String> _imagePaths = [];
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // 从路由参数读取问诊类型
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        setState(() {
          _consultationType = args['type'] as String? ?? 'text';
        });
      }
    });
  }

  @override
  void dispose() {
    _mainComplaintController.dispose();
    _presentIllnessController.dispose();
    _pastHistoryController.dispose();
    super.dispose();
  }

  String get _typeLabel {
    switch (_consultationType) {
      case 'phone': return '电话咨询';
      case 'video': return '视频咨询';
      default: return '图文咨询';
    }
  }

  String get _typeIcon {
    switch (_consultationType) {
      case 'phone': return '📞';
      case 'video': return '📹';
      default: return '💬';
    }
  }

  void _toggleSymptom(String symptom) {
    setState(() {
      if (_selectedSymptoms.contains(symptom)) {
        _selectedSymptoms.remove(symptom);
      } else if (_selectedSymptoms.length < 5) {
        _selectedSymptoms.add(symptom);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('最多选择5个症状'), duration: Duration(seconds: 1)),
        );
      }
    });
  }

  Future<void> _pickImage() async {
    // 在 Flutter Web 中不能用 image_picker 的 file 模式，这里用模拟
    // 实际项目中改用 web_image_picker 或 file_picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('图片上传功能需要实际部署后使用'), duration: Duration(seconds: 2)),
    );
  }

  void _removeImage(int index) {
    setState(() {
      _imagePaths.removeAt(index);
    });
  }

  Future<void> _submitConsultation() async {
    final mainComplaint = _mainComplaintController.text.trim();
    if (mainComplaint.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请描述您的主要症状'), duration: Duration(seconds: 2)),
      );
      return;
    }

    setState(() => _submitting = true);

    // 构建提交数据
    final data = {
      'type': _consultationType,
      'symptoms': _selectedSymptoms.join(','),
      'main_complaint': mainComplaint,
      'present_illness': _presentIllnessController.text.trim(),
      'past_history': _pastHistoryController.text.trim(),
      'image_count': _imagePaths.length,
    };

    debugPrint('[问诊] 提交数据: $data');

    // 模拟提交，实际调用 API
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    setState(() => _submitting = false);

    // 跳转到医生选择页
    Navigator.pushNamed(context, '/consultation/doctor-select', arguments: data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('描述病情'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 问诊类型标识
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F0FE),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_typeIcon, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(_typeLabel, style: const TextStyle(color: Color(0xFF1A73E8), fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 快速选择症状
            const Text('快速选择症状', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _commonSymptoms.map((s) {
                final selected = _selectedSymptoms.contains(s);
                return GestureDetector(
                  onTap: () => _toggleSymptom(s),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFF1A73E8) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? const Color(0xFF1A73E8) : const Color(0xFFDADCE0),
                      ),
                    ),
                    child: Text(
                      s,
                      style: TextStyle(
                        color: selected ? Colors.white : const Color(0xFF5F6368),
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (_selectedSymptoms.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('已选 ${_selectedSymptoms.length}/5', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ),
            const SizedBox(height: 24),

            // 主诉（必填）
            const Text('主要症状描述 *', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('请详细描述您的症状、持续时间、严重程度等', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            const SizedBox(height: 8),
            TextField(
              controller: _mainComplaintController,
              maxLines: 4,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText: '例如：头痛3天，前额持续性胀痛，伴有鼻塞流涕...',
                hintStyle: TextStyle(color: Color(0xFF9AA0A6), fontSize: 14),
                counterStyle: TextStyle(fontSize: 11),
              ),
            ),
            const SizedBox(height: 20),

            // 现病史
            const Text('现病史（可选）', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('发病以来的诊疗经过、用药情况等', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            const SizedBox(height: 8),
            TextField(
              controller: _presentIllnessController,
              maxLines: 3,
              maxLength: 300,
              decoration: const InputDecoration(
                hintText: '例如：已自行服用布洛芬，效果不明显...',
                hintStyle: TextStyle(color: Color(0xFF9AA0A6), fontSize: 14),
                counterStyle: TextStyle(fontSize: 11),
              ),
            ),
            const SizedBox(height: 20),

            // 既往史
            const Text('既往史（可选）', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('既往疾病史、过敏史、手术史等', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            const SizedBox(height: 8),
            TextField(
              controller: _pastHistoryController,
              maxLines: 3,
              maxLength: 300,
              decoration: const InputDecoration(
                hintText: '例如：有高血压病史，青霉素过敏...',
                hintStyle: TextStyle(color: Color(0xFF9AA0A6), fontSize: 14),
                counterStyle: TextStyle(fontSize: 11),
              ),
            ),
            const SizedBox(height: 24),

            // 图片上传
            const Text('上传图片（可选）', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('可上传检查报告、患处照片等', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            const SizedBox(height: 8),
            _buildImagePicker(),
            const SizedBox(height: 32),

            // 提交按钮
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submitConsultation,
                child: _submitting
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('下一步：选择医生', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      children: [
        Row(
          children: [
            ..._imagePaths.asMap().entries.map((entry) {
              final index = entry.key;
              final path = entry.value;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[100],
                      ),
                      child: path.startsWith('http')
                          ? Image.network(path, fit: BoxFit.cover)
                          : Icon(Icons.image, color: Colors.grey[400], size: 32),
                    ),
                    Positioned(
                      top: -4,
                      right: -4,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (_imagePaths.length < 9)
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFDADCE0), style: BorderStyle.solid),
                    color: Colors.grey[50],
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined, color: Color(0xFF9AA0A6), size: 24),
                      SizedBox(height: 4),
                      Text('添加图片', style: TextStyle(color: Color(0xFF9AA0A6), fontSize: 10)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
