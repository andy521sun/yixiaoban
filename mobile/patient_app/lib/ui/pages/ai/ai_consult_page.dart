import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../main.dart';

/// AI问诊页面 - 症状咨询、报告解读、健康问答
/// 对接后端真实 AI 接口
class AiConsultPage extends StatefulWidget {
  const AiConsultPage({super.key});

  @override
  State<AiConsultPage> createState() => _AiConsultPageState();
}

class _AiConsultPageState extends State<AiConsultPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 症状咨询
  final _symptomsCtrl = TextEditingController();
  bool _consultLoading = false;
  String? _diagnosis;
  bool _consultDone = false;

  // 报告解读
  final _reportCtrl = TextEditingController();
  String _reportType = '化验单';
  bool _reportLoading = false;
  String? _analysis;
  bool _reportDone = false;

  // 健康问答
  final _qaCtrl = TextEditingController();
  final List<Map<String, String>> _qaMessages = [];
  bool _qaLoading = false;

  final _commonSymptoms = [
    '头痛', '发热', '咳嗽', '腹痛', '乏力',
    '头晕', '胸闷', '恶心', '失眠', '关节痛',
    '腹泻', '背痛', '皮疹', '咽痛', '耳鸣',
  ];

  static const Color _primary = Color(0xFF1A73E8);
  static const Color _accent = Color(0xFF34A853);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _symptomsCtrl.dispose();
    _reportCtrl.dispose();
    _qaCtrl.dispose();
    super.dispose();
  }

  // ========== 症状咨询 ==========
  Future<void> _submitConsultation() async {
    final text = _symptomsCtrl.text.trim();
    if (text.isEmpty) {
      _showSnack('请描述您的症状');
      return;
    }
    setState(() => _consultLoading = true);

    final appState = context.read<AppState>();
    final res = await appState.api.aiConsultation(text);

    if (!mounted) return;
    if (res['success'] == true) {
      final data = res['data'] as Map<String, dynamic>? ?? {};
      final suggestions = (data['suggestions'] as List?) ?? [];
      final emergency = data['emergency'] as bool? ?? false;
      final recommendation = data['recommendation'] as String? ?? '';

      final sb = StringBuffer();
      sb.writeln('🤖 **AI智能诊断分析**\n');
      sb.writeln('**您的症状描述：**');
      sb.writeln('$text\n');
      sb.writeln('---\n');
      sb.writeln('**📋 建议措施：**');
      for (final s in suggestions) {
        sb.writeln('• $s');
      }
      sb.writeln();
      if (emergency) {
        sb.writeln('🚨 **警示：** 请立即就医！\n');
      }
      sb.writeln('**建议：** $recommendation\n');
      sb.writeln('---\n');
      sb.writeln('⚠️ *本建议由AI生成，仅供参考，不能替代专业医生诊断。如有不适请及时就医。*');

      setState(() {
        _diagnosis = sb.toString();
        _consultDone = true;
        _consultLoading = false;
      });
    } else {
      _showSnack(res['message'] as String? ?? '问诊失败');
      setState(() => _consultLoading = false);
    }
  }

  // ========== 报告解读 ==========
  Future<void> _submitReport() async {
    final text = _reportCtrl.text.trim();
    if (text.isEmpty) {
      _showSnack('请输入报告内容');
      return;
    }
    setState(() => _reportLoading = true);

    final appState = context.read<AppState>();
    final res = await appState.api.aiReportAnalysis(text, _reportType);

    if (!mounted) return;
    if (res['success'] == true) {
      final data = res['data'] as Map<String, dynamic>? ?? {};
      final analysis = data['analysis'] as String? ?? '';
      final suggestions = (data['suggestions'] as List?) ?? [];
      final abnormal = (data['abnormal_indicators'] as List?) ?? [];

      final sb = StringBuffer();
      sb.writeln('📋 **报告解读结果**\n');
      sb.writeln('**报告类型：** $_reportType\n');
      sb.writeln('---\n');
      sb.writeln('**📌 分析结果**\n');
      sb.writeln('$analysis\n');

      if (abnormal.isNotEmpty) {
        sb.writeln('**⚠️ 异常指标：**');
        for (final a in abnormal) {
          sb.writeln('• $a');
        }
        sb.writeln();
      }
      if (suggestions.isNotEmpty) {
        sb.writeln('**💡 建议措施：**');
        for (final s in suggestions) {
          sb.writeln('• $s');
        }
        sb.writeln();
      }
      sb.writeln('---\n');
      sb.writeln('⚠️ *本解读由AI生成，仅供参考，不能替代专业医生诊断。*');

      setState(() {
        _analysis = sb.toString();
        _reportDone = true;
        _reportLoading = false;
      });
    } else {
      _showSnack(res['message'] as String? ?? '解读失败');
      setState(() => _reportLoading = false);
    }
  }

  // ========== 健康问答 ==========
  Future<void> _sendQA() async {
    final text = _qaCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _qaMessages.add({'role': 'user', 'content': text});
      _qaLoading = true;
    });
    _qaCtrl.clear();

    // 用症状咨询接口做问答（传用户问题）
    final appState = context.read<AppState>();
    final res = await appState.api.aiConsultation(text);

    if (!mounted) return;
    setState(() {
      if (res['success'] == true) {
        final data = res['data'] as Map<String, dynamic>? ?? {};
        final suggestions = (data['suggestions'] as List?) ?? [];
        final answer = suggestions.isNotEmpty
            ? suggestions.join('\n')
            : data['analysis'] as String? ?? '未能获取回答，请稍后重试';
        _qaMessages.add({'role': 'assistant', 'content': answer});
      } else {
        _qaMessages.add({'role': 'assistant', 'content': '抱歉，暂时无法回答这个问题。'});
      }
      _qaLoading = false;
    });
  }

  void _addSymptomTag(String s) {
    final current = _symptomsCtrl.text;
    if (current.isEmpty) {
      _symptomsCtrl.text = s;
    } else {
      _symptomsCtrl.text = '$current、$s';
    }
    _symptomsCtrl.selection = TextSelection.fromPosition(
      TextPosition(offset: _symptomsCtrl.text.length),
    );
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 智能问诊'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _primary,
          labelColor: _primary,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.healing), text: '症状咨询'),
            Tab(icon: Icon(Icons.description), text: '报告解读'),
            Tab(icon: Icon(Icons.forum), text: '健康问答'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildConsultTab(),
          _buildReportTab(),
          _buildQATab(),
        ],
      ),
    );
  }

  Widget _buildConsultTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: _primary.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: _primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '描述您的症状，AI将提供初步分析。本建议仅供参考，不能替代医生诊断。',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('快速选择症状', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _commonSymptoms.map((s) => ActionChip(
              label: Text(s, style: const TextStyle(fontSize: 13)),
              onPressed: () => _addSymptomTag(s),
              avatar: const Icon(Icons.add, size: 16),
            )).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _symptomsCtrl,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: '请详细描述您的症状，例如：发烧38.5度，持续2天，伴有头痛、咳嗽...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true, fillColor: const Color(0xFFF5F7FA),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity, height: 48,
            child: ElevatedButton(
              onPressed: _consultLoading ? null : _submitConsultation,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _consultLoading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('开始诊断分析', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
          if (_consultDone && _diagnosis != null) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('诊断结果', style: TextStyle(color: _primary, fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 20),
                        onPressed: () => setState(() { _consultDone = false; _diagnosis = null; _symptomsCtrl.clear(); }),
                        tooltip: '重新咨询',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(_diagnosis!, style: const TextStyle(fontSize: 14, height: 1.6)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/consultation/type-select'),
                      icon: const Icon(Icons.chat, size: 18),
                      label: const Text('找医生在线问诊'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _accent,
                        side: const BorderSide(color: _accent),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: _accent.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: _accent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '输入化验单或检查报告内容，AI将提供通俗易懂的解读。',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('报告类型', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _reportType,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true, fillColor: const Color(0xFFF5F7FA),
            ),
            items: ['化验单', '影像报告', '体检报告', '病理报告', '其他'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setState(() => _reportType = v ?? '化验单'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reportCtrl,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: '请输入报告中的关键指标和数值，例如：白细胞 12.5×10⁹/L，血红蛋白 130g/L...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true, fillColor: const Color(0xFFF5F7FA),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity, height: 48,
            child: ElevatedButton(
              onPressed: _reportLoading ? null : _submitReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _reportLoading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('开始解读报告', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
          if (_reportDone && _analysis != null) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _accent.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('解读结果', style: TextStyle(color: _accent, fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 20),
                        onPressed: () => setState(() { _reportDone = false; _analysis = null; _reportCtrl.clear(); }),
                        tooltip: '重新解读',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(_analysis!, style: const TextStyle(fontSize: 14, height: 1.6)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQATab() {
    return Column(
      children: [
        Expanded(
          child: _qaMessages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.forum_outlined, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text('有什么健康问题想问？', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('关于疾病、用药、饮食等都可以问', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _qaMessages.length + (_qaLoading ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i == _qaMessages.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                            SizedBox(width: 8),
                            Text('思考中...', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                      );
                    }
                    final msg = _qaMessages[i];
                    final isUser = msg['role'] == 'user';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isUser) ...[
                            Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(
                                color: _primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.auto_awesome, color: _primary, size: 18),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isUser ? _primary : Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(12),
                                  topRight: const Radius.circular(12),
                                  bottomLeft: Radius.circular(isUser ? 12 : 4),
                                  bottomRight: Radius.circular(isUser ? 4 : 12),
                                ),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
                                ],
                              ),
                              child: Text(
                                msg['content'] ?? '',
                                style: TextStyle(
                                  color: isUser ? Colors.white : Colors.black87,
                                  fontSize: 14, height: 1.5,
                                ),
                              ),
                            ),
                          ),
                          if (isUser) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(
                                color: _accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.person, color: _accent, size: 18),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
        ),
        if (_qaMessages.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 8, runSpacing: 8,
              children: ['感冒了怎么办？', '陪诊服务怎么收费？', '就医前要注意什么？'].map((q) => ActionChip(
                label: Text(q, style: const TextStyle(fontSize: 12)),
                onPressed: () {
                  _qaCtrl.text = q;
                  _sendQA();
                },
              )).toList(),
            ),
          ),
        Container(
          padding: EdgeInsets.only(left: 12, right: 8, top: 8, bottom: MediaQuery.of(context).padding.bottom + 8),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, -2))],
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F3F4),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: TextField(
                    controller: _qaCtrl,
                    decoration: const InputDecoration(
                      hintText: '输入健康问题...',
                      hintStyle: TextStyle(color: Color(0xFF9AA0A6)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendQA(),
                  ),
                ),
              ),
              IconButton(
                onPressed: _qaLoading ? null : _sendQA,
                icon: const Icon(Icons.send_rounded),
                color: _primary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
