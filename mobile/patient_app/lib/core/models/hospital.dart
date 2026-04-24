class Hospital {
  final String id;
  final String name;
  final String level;
  final String address;
  final String province;
  final String city;
  final String district;
  final String phone;
  final String description;
  final bool isActive;

  Hospital({
    required this.id,
    required this.name,
    required this.level,
    required this.address,
    this.province = '',
    this.city = '',
    this.district = '',
    this.phone = '',
    this.description = '',
    this.isActive = true,
  });

  factory Hospital.fromJson(Map<String, dynamic> json) {
    return Hospital(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      level: json['level'] ?? '',
      address: json['address'] ?? '',
      province: json['province'] ?? '',
      city: json['city'] ?? '',
      district: json['district'] ?? '',
      phone: json['phone'] ?? '',
      description: json['description'] ?? '',
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }
}
