import 'package:flutter/material.dart';
import '../../../core/config/theme_config.dart' as prefix0;
import '../../../core/config/app_config.dart';

/// AI问诊页面 - 症状咨询、报告解读、健康问答
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

    // 模拟加载 -> 显示清晰结果
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    setState(() {
      _diagnosis = _mockDiagnosis(text);
      _consultDone = true;
      _consultLoading = false;
    });
  }

  String _mockDiagnosis(String symptoms) {
    return """🤖 **AI智能诊断分析**

**您的症状描述：**
$symptoms

---

**1️⃣ 可能的疾病方向**
根据您的症状描述，可能与以下情况有关：
• 上呼吸道感染（感冒/流感）
• 急性咽炎/扁桃体炎
• 疲劳综合征

**2️⃣ 建议检查项目**
• 血常规检查
• 体温测量
• 咽喉检查

**3️⃣ 是否需要立即就医**
✅ 建议 **近期就医检查**（黄色级别）
• 若出现高烧不退、呼吸困难请立即就医

**4️⃣ 日常注意事项**
• 多休息，保证充足睡眠
• 多喝温水（每日2000ml以上）
• 清淡饮食，避免辛辣刺激
• 保持室内通风

**5️⃣ 建议挂号科室**
🏥 建议挂 **内科** 或 **全科**

---

⚠️ *本建议由AI生成，仅供参考，不能替代专业医生诊断。如有不适请及时就医。*""";
  }

  // ========== 报告解读 ==========
  Future<void> _submitReport() async {
    final text = _reportCtrl.text.trim();
    if (text.isEmpty) {
      _showSnack('请输入报告内容');
      return;
    }
    setState(() => _reportLoading = true);

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    setState(() {
      _analysis = _mockAnalysis(text);
      _reportDone = true;
      _reportLoading = false;
    });
  }

  String _mockAnalysis(String reportText) {
    return """📋 **报告解读结果**

**报告类型：** $_reportType

---

**📌 关键指标分析**
以下是指标情况概览：
• 主要指标均处于正常范围
• 有1-2项轻微偏离参考值
• 无重大异常发现

**📖 通俗解释**
这些指标表明您的身体状况整体良好，少数偏离可能与近期饮食或作息有关，建议复查确认。

**💡 建议措施**
• 1-2周后复查异常指标
• 保持规律作息
• 如有不适请及时就医

⚠️ *本解读由AI生成，仅供参考，不能替代专业医生诊断。*""";
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

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    setState(() {
      _qaMessages.add({
        'role': 'assistant',
        'content': _mockQA(text),
      });
      _qaLoading = false;
    });
  }

  String _mockQA(String question) {
    final lowered = question.toLowerCase();
    if (lowered.contains('感冒') || lowered.contains('发热')) {
      return '感冒通常由病毒引起，症状包括发热、咳嗽、流鼻涕等。建议多休息、多喝水。如果体温超过38.5°C或症状持续加重，请及时就医。';
    }
    if (lowered.contains('饮食') || lowered.contains('吃')) {
      return '就医前建议清淡饮食，避免空腹检查（除非要求空腹）。术后恢复期间注意补充蛋白质和维生素，避免辛辣刺激食物。';
    }
    if (lowered.contains('陪诊') || lowered.contains('服务')) {
      return '医小伴提供专业陪诊服务，包括小时陪诊（80元/小时）、全天陪诊（500元/天）和定制服务。陪诊师均经过严格审核和培训，可全程陪同您就诊。';
    }
    return '关于「$question」这个问题，建议您咨询专业医生获取准确建议。如果您有就医需求，可以在医小伴上预约陪诊服务，陪诊师会全程协助您。';
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
          indicatorColor: AppConfig.primaryColor,
          labelColor: AppConfig.primaryColor,
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
          // 头部提示
          Card(
            color: AppConfig.primaryColor.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppConfig.primaryColor, size: 20),
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

          // 常用症状标签
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

          // 症状输入
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

          // 提交按钮
          SizedBox(
            width: double.infinity, height: 48,
            child: ElevatedButton(
              onPressed: _consultLoading ? null : _submitConsultation,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConfig.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _consultLoading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('开始诊断分析', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),

          // 诊断结果
          if (_consultDone && _diagnosis != null) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppConfig.primaryColor.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppConfig.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('诊断结果', style: TextStyle(color: AppConfig.primaryColor, fontWeight: FontWeight.w600, fontSize: 13)),
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
                      onPressed: () => Navigator.pushNamed(context, '/appointment'),
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: const Text('预约陪诊师'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppConfig.accentColor,
                        side: const BorderSide(color: AppConfig.accentColor),
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
            color: AppConfig.accentColor.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppConfig.accentColor, size: 20),
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

          // 报告类型选择
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

          // 报告内容输入
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
                backgroundColor: AppConfig.accentColor,
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
                border: Border.all(color: AppConfig.accentColor.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppConfig.accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('解读结果', style: TextStyle(color: AppConfig.accentColor, fontWeight: FontWeight.w600, fontSize: 13)),
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
        // 消息列表
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
                                color: AppConfig.primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.auto_awesome, color: AppConfig.primaryColor, size: 18),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isUser ? AppConfig.primaryColor : Colors.white,
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
                                  color: isUser ? Colors.white : prefix0.ThemeConfig.textPrimaryColor,
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
                                color: AppConfig.accentColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.person, color: AppConfig.accentColor, size: 18),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
        ),

        // 快捷问题
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

        // 输入栏
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
                color: AppConfig.primaryColor,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
