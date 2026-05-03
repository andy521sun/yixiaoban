import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:doctor_app/core/providers/doctor_state.dart';

/// 医生端问诊聊天室 — 接诊、聊天、完成问诊、开处方
/// 支持 WebSocket 实时推送
class DoctorConsultationChatPage extends StatefulWidget {
  final String consultationId;

  const DoctorConsultationChatPage({super.key, required this.consultationId});

  @override
  State<DoctorConsultationChatPage> createState() => _DoctorConsultationChatPageState();
}

class _DoctorConsultationChatPageState extends State<DoctorConsultationChatPage> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  Map<String, dynamic>? _consultation;
  bool _loading = true;
  bool _submitting = false;
  StreamSubscription<Map<String, dynamic>>? _wsSubscription;

  // 诊断和处方
  final _diagnosisController = TextEditingController();
  final _notesController = TextEditingController();
  final List<Map<String, TextEditingController>> _drugControllers = [];

  @override
  void initState() {
    super.initState();
    _loadDetail();
    WidgetsBinding.instance.addPostFrameCallback((_) => _listenWs());
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _diagnosisController.dispose();
    _notesController.dispose();
    for (final d in _drugControllers) {
      d.values.forEach((c) => c.dispose());
    }
    _wsSubscription?.cancel();
    super.dispose();
  }

  /// 监听 WebSocket 实时新消息
  void _listenWs() {
    final state = context.read<DoctorAppState>();
    _wsSubscription = state.ws.messages.listen((msg) {
      if (msg['type'] == 'consultation_message') {
        final data = msg['data'] as Map<String, dynamic>?;
        if (data != null) {
          final msgConsultId = data['consultation_id']?.toString() ?? '';
          if (msgConsultId == widget.consultationId) {
            if (mounted) {
              setState(() => _messages.add(data));
              _scrollToBottom();
            }
          }
        }
      }
    });
  }

  Future<void> _loadDetail() async {
    final state = context.read<DoctorAppState>();
    final detail = await state.api.getConsultationDetail(widget.consultationId);
    final msgs = await state.api.getMessages(widget.consultationId);

    if (!mounted) return;
    setState(() {
      _consultation = detail;
      _messages.clear();
      _messages.addAll(msgs.cast<Map<String, dynamic>>());
      _loading = false;
    });
    _scrollToBottom();
  }

  Future<void> _sendMessage(String content) async {
    if (content.trim().isEmpty || _submitting) return;
    setState(() => _submitting = true);
    _textController.clear();

    final state = context.read<DoctorAppState>();
    final res = await state.api.sendMessage(widget.consultationId, {
      'msg_type': 'text',
      'content': content,
    });

    if (res['success'] == true) {
      // 不重复加载，等 WebSocket 推回来
    } else {
      _loadDetail();
    }
    if (mounted) setState(() => _submitting = false);
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showCompleteDialog() {
    _drugControllers.clear();
    _drugControllers.add({
      'name': TextEditingController(),
      'spec': TextEditingController(),
      'dosage': TextEditingController(),
      'frequency': TextEditingController(),
      'days': TextEditingController(),
      'quantity': TextEditingController(),
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) => SingleChildScrollView(
            controller: scrollController,
            padding: EdgeInsets.only(
              left: 24, right: 24, top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('完成问诊', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                const Text('诊断结果 *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                TextField(
                  controller: _diagnosisController,
                  maxLines: 3,
                  decoration: const InputDecoration(hintText: '输入诊断结论...'),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('处方药品', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    TextButton.icon(
                      onPressed: () {
                        setSheetState(() {
                          _drugControllers.add({
                            'name': TextEditingController(),
                            'spec': TextEditingController(),
                            'dosage': TextEditingController(),
                            'frequency': TextEditingController(),
                            'days': TextEditingController(),
                            'quantity': TextEditingController(),
                          });
                        });
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('添加药品'),
                    ),
                  ],
                ),
                ..._drugControllers.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final ctrls = entry.value;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text('药品 $idx', style: const TextStyle(fontWeight: FontWeight.w500)),
                              if (_drugControllers.length > 1)
                                IconButton(
                                  icon: const Icon(Icons.close, size: 16),
                                  onPressed: () {
                                    ctrls.values.forEach((c) => c.dispose());
                                    setSheetState(() => _drugControllers.removeAt(idx - 1));
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(controller: ctrls['name']!, decoration: const InputDecoration(labelText: '药品名称 *', isDense: true)),
                          TextField(controller: ctrls['spec']!, decoration: const InputDecoration(labelText: '规格', isDense: true)),
                          Row(
                            children: [
                              Expanded(child: TextField(controller: ctrls['dosage']!, decoration: const InputDecoration(labelText: '用量', isDense: true))),
                              const SizedBox(width: 8),
                              Expanded(child: TextField(controller: ctrls['frequency']!, decoration: const InputDecoration(labelText: '频次', isDense: true))),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(child: TextField(controller: ctrls['days']!, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '天数', isDense: true))),
                              const SizedBox(width: 8),
                              Expanded(child: TextField(controller: ctrls['quantity']!, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '数量', isDense: true))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                const Text('医生嘱咐', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(hintText: '用药注意事项、饮食建议等...'),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _submitCompleteAndPrescription(),
                    child: const Text('完成问诊并开具处方'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitCompleteAndPrescription() async {
    final diagnosis = _diagnosisController.text.trim();
    if (diagnosis.isEmpty) {
      _showSnack('请输入诊断结果');
      return;
    }

    final state = context.read<DoctorAppState>();

    final completeRes = await state.api.completeConsultation(widget.consultationId, {
      'diagnosis': diagnosis,
      'notes': _notesController.text.trim(),
    });

    if (completeRes['success'] != true) {
      _showSnack(completeRes['message'] as String? ?? '完成问诊失败');
      return;
    }

    final drugs = _drugControllers
        .map((d) => {
          'drug_name': d['name']?.text.trim() ?? '',
          'specification': d['spec']?.text.trim() ?? '',
          'dosage': d['dosage']?.text.trim() ?? '',
          'frequency': d['frequency']?.text.trim() ?? '',
          'duration_days': int.tryParse(d['days']?.text.trim() ?? '') ?? 0,
          'total_quantity': int.tryParse(d['quantity']?.text.trim() ?? '') ?? 0,
        })
        .where((d) => (d['drug_name'] as String).isNotEmpty)
        .toList();

    if (drugs.isNotEmpty) {
      await state.api.createPrescription(widget.consultationId, {
        'diagnosis': diagnosis,
        'notes': _notesController.text.trim(),
        'items': drugs,
      });
    }

    if (mounted) {
      Navigator.pop(context);
      Navigator.pop(context);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final status = _consultation?['status'] as String? ?? '';
    final isActive = status == 'active' || status == 'in_progress';
    final patientName = _consultation?['patient_name'] as String? ?? '患者';

    return Scaffold(
      appBar: AppBar(
        title: Text('$patientName · 问诊'),
        actions: [
          if (isActive)
            TextButton.icon(
              onPressed: _showCompleteDialog,
              icon: const Icon(Icons.check_circle, size: 18),
              label: const Text('完成', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_consultation?['main_complaint'] != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: const Color(0xFFE8F5E9),
              child: Row(
                children: [
                  const Icon(Icons.healing, size: 16, color: Color(0xFF34A853)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('主诉: ${_consultation!['main_complaint']}',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF2E7D32)),
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
                            const SizedBox(height: 8),
                            Text('开始与 $patientName 沟通', style: TextStyle(color: Colors.grey[500])),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) {
                          final m = _messages[i];
                          final isMe = (m['sender_role'] as String? ?? '') == 'doctor' || (m['role'] as String? ?? '') == 'doctor';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                              children: [
                                if (!isMe)
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: const Color(0xFF34A853).withValues(alpha: 0.1),
                                    child: const Icon(Icons.person, size: 16, color: Color(0xFF34A853)),
                                  ),
                                if (!isMe) const SizedBox(width: 8),
                                Flexible(
                                  child: Container(
                                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isMe ? const Color(0xFF1A73E8) : Colors.grey[100],
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(16),
                                        topRight: const Radius.circular(16),
                                        bottomLeft: Radius.circular(isMe ? 16 : 4),
                                        bottomRight: Radius.circular(isMe ? 4 : 16),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                      children: [
                                        Text(m['content'] as String? ?? '',
                                          style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 14),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          (m['created_at'] as String? ?? '').substring(11, 16),
                                          style: TextStyle(color: isMe ? Colors.white70 : Colors.grey[500], fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (isMe) const SizedBox(width: 8),
                              ],
                            ),
                          );
                        },
                      ),
          ),
          if (isActive)
            _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 100),
                  decoration: BoxDecoration(color: const Color(0xFFF1F3F4), borderRadius: BorderRadius.circular(20)),
                  child: TextField(
                    controller: _textController,
                    textInputAction: TextInputAction.send,
                    maxLines: null,
                    decoration: const InputDecoration(
                      hintText: '输入回复...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (v) => _sendMessage(v),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: const Color(0xFF1A73E8),
                shape: const CircleBorder(),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _sendMessage(_textController.text),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
