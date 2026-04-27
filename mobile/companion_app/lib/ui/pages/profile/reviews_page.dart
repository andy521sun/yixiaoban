import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/companion_state.dart';
import '../../../core/services/review_service.dart';
import '../../../core/config/app_config.dart';

/// 服务评价页面
class ReviewsPage extends StatefulWidget {
  const ReviewsPage({super.key});

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  final ReviewService _service = ReviewService();
  List<Map<String, dynamic>> _reviews = [];
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _service.setToken(context.read<CompanionState>().token);
    _loadData();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      _service.getMyReviews(),
      _service.getReviewStats(),
    ]);
    if (!mounted) return;
    setState(() {
      _reviews = results[0] as List<Map<String, dynamic>>;
      _stats = results[1] as Map<String, dynamic>?;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('服务评价')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 评分概览
                  _buildRatingOverview(),
                  const SizedBox(height: 16),

                  // 评价列表标题
                  Row(
                    children: [
                      const Text(
                        '全部评价',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppConfig.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_reviews.length}条',
                          style: const TextStyle(
                            color: AppConfig.primaryColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 评价列表
                  if (_reviews.isEmpty)
                    _buildEmptyState()
                  else
                    ..._reviews.map((r) => _buildReviewCard(r)),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildRatingOverview() {
    final avgRating = _stats?['average_rating'] ?? _stats?['avg_rating'] ?? 0.0;
    final total = _stats?['total_reviews'] ?? _stats?['total'] ?? 0;
    final distribution = _stats?['distribution'] as Map<String, dynamic>? ?? {};

    // 将avgRating转为double
    final double rating = (avgRating is double) ? avgRating : (avgRating is num ? avgRating.toDouble() : 0.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  rating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.bold,
                    color: AppConfig.textPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStars(rating),
                    const SizedBox(height: 4),
                    Text(
                      '$total条评价',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 评分分布
            ...List.generate(5, (i) {
              final star = 5 - i;
              final count = (distribution['$star'] ?? 0);
              final ratio = total > 0
                  ? ((count as int).toDouble() / (total as int).toDouble())
                  : 0.0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: Text(
                        '$star星',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ratio,
                          backgroundColor: Colors.grey[200],
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFF4B400),
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 24,
                      child: Text(
                        '$count',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStars(double rating) {
    return Row(
      children: List.generate(5, (i) {
        final filled = i < rating.round();
        return Icon(
          filled ? Icons.star : Icons.star_border,
          color: const Color(0xFFF4B400),
          size: 20,
        );
      }),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final userName = review['reviewer_name'] ?? review['patient_name'] ?? '用户';
    final rating = (review['rating'] ?? 5) is int
        ? (review['rating'] ?? 5).toDouble()
        : (review['rating'] ?? 5.0);
    final comment = review['comment'] ?? review['content'] ?? '';
    final createdAt = review['created_at'] ?? '';

    String timeStr = '';
    if (createdAt is String && createdAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(createdAt);
        timeStr = '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {}
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppConfig.accentColor.withValues(alpha: 0.1),
                  child: Text(
                    userName.toString()[0],
                    style: const TextStyle(
                      color: AppConfig.accentColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                _buildStars(rating),
              ],
            ),
            if (comment.toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                comment,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
            if (timeStr.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                timeStr,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star_outline, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              '暂无评价',
              style: TextStyle(color: Colors.grey[500], fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              '完成服务后患者可以为你评价',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
