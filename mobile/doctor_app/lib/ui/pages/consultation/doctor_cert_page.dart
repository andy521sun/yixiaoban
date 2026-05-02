import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:doctor_app/core/providers/doctor_state.dart';

/// 医生认证/入驻页面
class DoctorCertPage extends StatefulWidget {
  const DoctorCertPage({super.key});

  @override
  State<DoctorCertPage> createState() => _DoctorCertPageState();
}

class _DoctorCertPageState extends State<DoctorCertPage> {
  final _nameController = TextEditingController();
  final _titleController = TextEditingController();
  final _deptController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _licenseController = TextEditingController();
  final _introController = TextEditingController();
  bool _submitting = false;

  final _titles = ['主任医师', '副主任医师', '主治医师', '住院医师', '医学生'];
  String? _selectedTitle;

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _deptController.dispose();
    _hospitalController.dispose();
    _licenseController.dispose();
    _introController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty ||
        _selectedTitle == null ||
        _deptController.text.trim().isEmpty ||
        _hospitalController.text.trim().isEmpty) {
      _showSnack('请填写完整信息');
      return;
    }

    setState(() => _submitting = true);

    final state = context.read<DoctorAppState>();
    final res = await state.api.submitCertification({
      'real_name': _nameController.text.trim(),
      'title': _selectedTitle,
      'department': _deptController.text.trim(),
      'hospital_affiliation': _hospitalController.text.trim(),
      'license_number': _licenseController.text.trim(),
      'introduction': _introController.text.trim(),
    });

    if (!mounted) return;
    setState(() => _submitting = false);

    if (res['success'] == true) {
      state.setCertStatus('pending');
      state.setDoctorInfo(name: _nameController.text.trim(), title: _selectedTitle, department: _deptController.text.trim(), hospital: _hospitalController.text.trim());
      _showSnack('认证申请已提交，等待审核');
      Navigator.pop(context);
    } else {
      _showSnack(res['message'] as String? ?? '提交失败');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('医生认证入驻')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('基本信息', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: '真实姓名 *', prefixIcon: Icon(Icons.person)),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedTitle,
              decoration: const InputDecoration(labelText: '职称 *', prefixIcon: Icon(Icons.work)),
              items: _titles.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _selectedTitle = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _deptController,
              decoration: const InputDecoration(labelText: '科室 *', prefixIcon: Icon(Icons.local_hospital)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _hospitalController,
              decoration: const InputDecoration(labelText: '所属医院 *', prefixIcon: Icon(Icons.business)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _licenseController,
              decoration: const InputDecoration(labelText: '执业医师编号', prefixIcon: Icon(Icons.note)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _introController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: '个人简介', prefixIcon: Icon(Icons.description)),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('提交认证申请', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
