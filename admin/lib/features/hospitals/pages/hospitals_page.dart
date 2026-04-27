import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_provider.dart';

class HospitalsPage extends StatefulWidget {
  const HospitalsPage({super.key});

  @override
  State<HospitalsPage> createState() => _HospitalsPageState();
}

class _HospitalsPageState extends State<HospitalsPage> {
  List<dynamic> _hospitals = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await context.read<AuthProvider>().api.getHospitals();
    if (!mounted) return;
    setState(() {
      _hospitals = result['data']?['hospitals'] ?? result['data'] ?? [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: const Color(0xFF34A853),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('添加医院', style: TextStyle(color: Colors.white)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _hospitals.isEmpty
                  ? const SizedBox(height: 300, child: Center(child: Text('暂无医院', style: TextStyle(color: Colors.grey))))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _hospitals.length,
                      itemBuilder: (_, i) => _buildHospitalCard(_hospitals[i]),
                    ),
            ),
    );
  }

  Widget _buildHospitalCard(dynamic hospital) {
    final h = hospital as Map<String, dynamic>;
    final name = h['name'] ?? '';
    final level = h['level'] ?? '';
    final address = h['address'] ?? '';
    final city = h['city'] ?? '';
    final phone = h['phone'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF1A73E8).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.local_hospital, color: Color(0xFF1A73E8), size: 26),
        ),
        title: Row(
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
            if (level.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: level == '三甲' ? Colors.red.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(level, style: TextStyle(fontSize: 10, color: level == '三甲' ? Colors.red : Colors.blue, fontWeight: FontWeight.w500)),
              ),
            ],
          ],
        ),
        subtitle: Text('$city · $address\n📞 $phone', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        trailing: IconButton(
          icon: const Icon(Icons.edit_outlined, size: 20),
          onPressed: () => _showEditDialog(h),
        ),
      ),
    );
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final levelCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final addrCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加医院'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '医院名称', border: OutlineInputBorder())),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: TextField(controller: levelCtrl, decoration: const InputDecoration(labelText: '等级（如三甲）', border: OutlineInputBorder()))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: cityCtrl, decoration: const InputDecoration(labelText: '城市', border: OutlineInputBorder()))),
                ]),
                const SizedBox(height: 8),
                TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: '地址', border: OutlineInputBorder())),
                const SizedBox(height: 8),
                TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: '电话', border: OutlineInputBorder())),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () async {
              final ok = await context.read<AuthProvider>().api.createHospital({
                'name': nameCtrl.text, 'level': levelCtrl.text,
                'city': cityCtrl.text, 'address': addrCtrl.text, 'phone': phoneCtrl.text,
              });
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              if (ok) _load();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? '添加成功' : '添加失败')));
            },
            child: const Text('确认添加'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> h) {
    final nameCtrl = TextEditingController(text: h['name'] ?? '');
    final levelCtrl = TextEditingController(text: h['level'] ?? '');
    final cityCtrl = TextEditingController(text: h['city'] ?? '');
    final addrCtrl = TextEditingController(text: h['address'] ?? '');
    final phoneCtrl = TextEditingController(text: h['phone'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('编辑医院'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '医院名称', border: OutlineInputBorder())),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: TextField(controller: levelCtrl, decoration: const InputDecoration(labelText: '等级', border: OutlineInputBorder()))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: cityCtrl, decoration: const InputDecoration(labelText: '城市', border: OutlineInputBorder()))),
                ]),
                const SizedBox(height: 8),
                TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: '地址', border: OutlineInputBorder())),
                const SizedBox(height: 8),
                TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: '电话', border: OutlineInputBorder())),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () async {
              final ok = await context.read<AuthProvider>().api.updateHospital(h['id'] ?? '', {
                'name': nameCtrl.text, 'level': levelCtrl.text,
                'city': cityCtrl.text, 'address': addrCtrl.text, 'phone': phoneCtrl.text,
              });
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              if (ok) _load();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? '更新成功' : '更新失败')));
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}
