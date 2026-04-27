import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/companion_state.dart';
import '../../../core/services/schedule_service.dart';
import '../../../core/config/app_config.dart';

/// 日程管理页面
class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  final ScheduleService _scheduleService = ScheduleService();
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();
  List<Map<String, dynamic>> _monthEvents = [];
  List<Map<String, dynamic>> _selectedEvents = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _scheduleService.setToken(context.read<CompanionState>().token);
    _loadMonthOverview();
  }

  @override
  void dispose() {
    _scheduleService.dispose();
    super.dispose();
  }

  Future<void> _loadMonthOverview() async {
    setState(() => _loading = true);
    final events = await _scheduleService.getMonthOverview(
      _focusedMonth.year,
      _focusedMonth.month,
    );
    if (!mounted) return;
    setState(() {
      _monthEvents = events;
      _loading = false;
    });
    _loadSelectedDateEvents();
  }

  Future<void> _loadSelectedDateEvents() async {
    final events = await _scheduleService.getScheduleByDate(_selectedDate);
    if (!mounted) return;
    setState(() => _selectedEvents = events);
  }

  void _onDaySelected(DateTime day) {
    setState(() => _selectedDate = day);
    _loadSelectedDateEvents();
  }

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    });
    _loadMonthOverview();
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    });
    _loadMonthOverview();
  }

  bool _hasEventOnDay(DateTime day) {
    return _monthEvents.any((e) {
      final dateStr = e['date'] ?? e['appointment_date'] ?? '';
      if (dateStr.isEmpty) return false;
      try {
        final dt = DateTime.parse(dateStr);
        return dt.year == day.year && dt.month == day.month && dt.day == day.day;
      } catch (_) {
        return false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的日程')),
      body: Column(
        children: [
          // 日历头部（年月切换）
          _buildCalendarHeader(),
          // 日历网格
          _buildCalendarGrid(),
          // 分隔线
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(color: Colors.grey[200]),
          ),
          // 选中日期的日程列表
          Expanded(
            child: _buildEventList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarHeader() {
    final monthNames = [
      '一月', '二月', '三月', '四月', '五月', '六月',
      '七月', '八月', '九月', '十月', '十一月', '十二月'
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _previousMonth,
            icon: const Icon(Icons.chevron_left),
            color: AppConfig.textSecondary,
          ),
          Text(
            '${_focusedMonth.year}年 ${monthNames[_focusedMonth.month - 1]}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            onPressed: _nextMonth,
            icon: const Icon(Icons.chevron_right),
            color: AppConfig.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDay =
        DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDay =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final firstWeekday = firstDay.weekday % 7; // 周一=0...周日=6
    final daysInMonth = lastDay.day;

    const weekDays = ['一', '二', '三', '四', '五', '六', '日'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          // 星期行
          Row(
            children: weekDays.map((d) => Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    d,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            )).toList(),
          ),
          // 日期网格
          ...List.generate(
            ((firstWeekday + daysInMonth + 6) ~/ 7),
            (weekIndex) {
              return Row(
                children: List.generate(7, (dayIndex) {
                  final dayNum = weekIndex * 7 + dayIndex - firstWeekday + 1;
                  if (dayNum < 1 || dayNum > daysInMonth) {
                    return const Expanded(child: SizedBox(height: 44));
                  }

                  final date = DateTime(
                      _focusedMonth.year, _focusedMonth.month, dayNum);
                  final isToday = _isSameDay(date, DateTime.now());
                  final isSelected = _isSameDay(date, _selectedDate);
                  final hasEvent = _hasEventOnDay(date);

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _onDaySelected(date),
                      child: Container(
                        height: 44,
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppConfig.primaryColor
                              : isToday
                                  ? AppConfig.primaryColor.withValues(alpha: 0.08)
                                  : null,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$dayNum',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight:
                                    isToday || isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                color: isSelected
                                    ? Colors.white
                                    : isToday
                                        ? AppConfig.primaryColor
                                        : AppConfig.textPrimary,
                              ),
                            ),
                            if (hasEvent)
                              Container(
                                width: 5,
                                height: 5,
                                margin: const EdgeInsets.only(top: 2),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white
                                      : AppConfig.primaryColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEventList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final dateStr =
        '${_selectedDate.month}月${_selectedDate.day}日 ${_weekdayName(_selectedDate.weekday)}';

    if (_selectedEvents.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Icon(Icons.event_busy, size: 48, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text(
                  '当天无日程安排',
                  style: TextStyle(color: Colors.grey[500], fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            dateStr,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ..._selectedEvents.map((e) => _buildEventCard(e)),
      ],
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final status = event['status'] ?? 'pending';
    final Color statusColor;
    String statusText;
    switch (status) {
      case 'confirmed':
        statusColor = AppConfig.accentColor;
        statusText = '待服务';
        break;
      case 'in_progress':
        statusColor = AppConfig.primaryColor;
        statusText = '服务中';
        break;
      case 'completed':
        statusColor = Colors.grey;
        statusText = '已完成';
        break;
      case 'cancelled':
        statusColor = AppConfig.errorColor;
        statusText = '已取消';
        break;
      default:
        statusColor = const Color(0xFFF4B400);
        statusText = '待确认';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // 时间竖线
            Container(
              width: 3,
              height: 50,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        event['appointment_time'] ?? '--:--',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event['hospital_name'] ?? '未知医院',
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    '患者: ${event['patient_name'] ?? '未知'}',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _weekdayName(int wd) {
    const names = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return names[wd - 1];
  }
}
