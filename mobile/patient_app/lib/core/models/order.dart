class Order {
  final String id;
  final String? userId;
  final String? hospitalId;
  final String? companionId;
  final String serviceType;
  final String appointmentTime;
  final int durationMinutes;
  final double price;
  final String status;
  final String? paymentMethod;
  final String paymentStatus;
  final String? hospitalName;
  final String? companionName;
  final String createdAt;

  Order({
    required this.id,
    this.userId,
    this.hospitalId,
    this.companionId,
    this.serviceType = '普通陪诊',
    this.appointmentTime = '',
    this.durationMinutes = 120,
    this.price = 0,
    this.status = 'pending',
    this.paymentMethod,
    this.paymentStatus = 'unpaid',
    this.hospitalName,
    this.companionName,
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  factory Order.fromJson(Map<String, dynamic> json) {
    double price = 0;
    if (json['price'] != null) {
      price = json['price'] is double ? json['price'] : (json['price'] as num).toDouble();
    }
    if (price == 0 && json['total_amount'] != null) {
      price = json['total_amount'] is double ? json['total_amount'] : (json['total_amount'] as num).toDouble();
    }

    return Order(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? json['patient_id'],
      hospitalId: json['hospital_id'],
      companionId: json['companion_id'],
      serviceType: json['service_type'] ?? '普通陪诊',
      appointmentTime: json['appointment_time'] ?? json['appointment_date'] ?? '',
      durationMinutes: json['duration_minutes'] ?? 120,
      price: price,
      status: json['status'] ?? 'pending',
      paymentMethod: json['payment_method'],
      paymentStatus: json['payment_status'] ?? 'unpaid',
      hospitalName: json['hospital_name'] ?? '未知医院',
      companionName: json['companion_name'] ?? '未知陪诊师',
      createdAt: json['created_at'],
    );
  }

  String get statusText {
    switch (status) {
      case 'pending': return '待确认';
      case 'confirmed': return '已确认';
      case 'in_progress': return '服务中';
      case 'completed': return '已完成';
      case 'cancelled': return '已取消';
      default: return status;
    }
  }

  String get paymentStatusText {
    switch (paymentStatus) {
      case 'unpaid': return '未支付';
      case 'paid': return '已支付';
      case 'refunding': return '退款中';
      case 'refunded': return '已退款';
      default: return paymentStatus;
    }
  }
}
