import 'package:flutter/material.dart';

class HospitalCard extends StatelessWidget {
  final Map<String, dynamic> hospital;
  
  const HospitalCard({
    super.key,
    required this.hospital,
  });

  String _getHospitalLevelColor(String level) {
    switch (level) {
      case '三甲':
        return 'FF5252'; // 红色
      case '三乙':
        return 'FF9800'; // 橙色
      case '二甲':
        return '4CAF50'; // 绿色
      case '二乙':
        return '2196F3'; // 蓝色
      default:
        return '9E9E9E'; // 灰色
    }
  }

  @override
  Widget build(BuildContext context) {
    final level = hospital['level']?.toString() ?? '未知';
    final levelColor = _getHospitalLevelColor(level);
    
    return Container(
      width: 280,
      margin: EdgeInsets.only(right: 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 医院图片区域
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              color: Color(0xFFE8F5E9),
              image: hospital['image'] != null
                  ? DecorationImage(
                      image: NetworkImage(hospital['image']),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: hospital['image'] == null
                ? Center(
                    child: Icon(
                      Icons.local_hospital,
                      size: 48,
                      color: Color(0xFF4CAF50),
                    ),
                  )
                : null,
          ),
          
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 医院名称和等级
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        hospital['name']?.toString() ?? '未知医院',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color(int.parse('0xFF$levelColor')).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Color(int.parse('0xFF$levelColor')).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        level,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(int.parse('0xFF$levelColor')),
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 8),
                
                // 医院地址
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        hospital['address']?.toString() ?? '地址未知',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 8),
                
                // 科室标签
                if (hospital['departments'] != null && hospital['departments'].isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: (hospital['departments'] as List)
                        .take(3)
                        .map((dept) => Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                dept.toString(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF4CAF50),
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
                        child: Text('查看详情'),
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
                        child: Text('立即预约'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}