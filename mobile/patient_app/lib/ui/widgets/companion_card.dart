import 'package:flutter/material.dart';

class CompanionCard extends StatelessWidget {
  final Map<String, dynamic> companion;
  
  const CompanionCard({
    super.key,
    required this.companion,
  });

  Widget _buildRatingStars(double rating) {
    final fullStars = rating.floor();
    final hasHalfStar = rating - fullStars >= 0.5;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < fullStars; i++)
          Icon(Icons.star, size: 16, color: Colors.amber),
        if (hasHalfStar)
          Icon(Icons.star_half, size: 16, color: Colors.amber),
        for (int i = 0; i < 5 - fullStars - (hasHalfStar ? 1 : 0); i++)
          Icon(Icons.star_border, size: 16, color: Colors.grey[400]),
        SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = companion['name']?.toString() ?? '未知陪诊师';
    final title = companion['title']?.toString() ?? '专业陪诊师';
    final experience = companion['experience']?.toString() ?? '0';
    final rating = double.tryParse(companion['rating']?.toString() ?? '5.0') ?? 5.0;
    final completedOrders = companion['completed_orders']?.toString() ?? '0';
    final specialties = companion['specialties'] ?? [];
    final price = companion['price_per_hour']?.toString() ?? '0';
    
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头像区域
          Container(
            width: 100,
            height: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              color: Color(0xFFE8F5E9),
              image: companion['avatar'] != null
                  ? DecorationImage(
                      image: NetworkImage(companion['avatar']),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: companion['avatar'] == null
                ? Center(
                    child: Icon(
                      Icons.person,
                      size: 48,
                      color: Color(0xFF4CAF50),
                    ),
                  )
                : null,
          ),
          
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 姓名和职称
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 2),
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF4CAF50),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 在线状态
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (companion['is_online'] ?? false)
                              ? Color(0xFF4CAF50).withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: (companion['is_online'] ?? false)
                                ? Color(0xFF4CAF50)
                                : Colors.grey,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: (companion['is_online'] ?? false)
                                    ? Color(0xFF4CAF50)
                                    : Colors.grey,
                              ),
                            ),
                            SizedBox(width: 4),
                            Text(
                              (companion['is_online'] ?? false) ? '在线' : '离线',
                              style: TextStyle(
                                fontSize: 12,
                                color: (companion['is_online'] ?? false)
                                    ? Color(0xFF4CAF50)
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 8),
                  
                  // 评分和经验
                  Row(
                    children: [
                      _buildRatingStars(rating),
                      SizedBox(width: 16),
                      Row(
                        children: [
                          Icon(
                            Icons.work,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: 4),
                          Text(
                            '$experience年经验',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 8),
                  
                  // 服务统计
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 14,
                              color: Color(0xFF4CAF50),
                            ),
                            SizedBox(width: 4),
                            Text(
                              '$completedOrders单完成',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF4CAF50),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.attach_money,
                              size: 14,
                              color: Color(0xFFFF9800),
                            ),
                            SizedBox(width: 4),
                            Text(
                              '¥$price/小时',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFFFF9800),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 8),
                  
                  // 专长标签
                  if (specialties.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: specialties
                          .take(3)
                          .map((specialty) => Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Color(0xFFE3F2FD),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  specialty.toString(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF2196F3),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  
                  SizedBox(height: 12),
                  
                  // 操作按钮
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            // 查看详情
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Color(0xFF4CAF50),
                            side: BorderSide(color: Color(0xFF4CAF50)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.info_outline, size: 18),
                              SizedBox(width: 4),
                              Text('查看详情'),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // 立即预约
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF4CAF50),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.calendar_today, size: 18),
                              SizedBox(width: 4),
                              Text('立即预约'),
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
        ],
      ),
    );
  }
}