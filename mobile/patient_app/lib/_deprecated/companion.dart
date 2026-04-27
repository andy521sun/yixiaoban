class Companion {
  final String id;
  final String name;
  final String realName;
  final String introduction;
  final int experienceYears;
  final String specialty;
  final double hourlyRate;
  final double rating;
  final int serviceCount;
  final bool isAvailable;
  final bool isCertified;

  Companion({
    required this.id,
    required this.name,
    this.realName = '',
    this.introduction = '',
    this.experienceYears = 0,
    this.specialty = '',
    this.hourlyRate = 0,
    this.rating = 0,
    this.serviceCount = 0,
    this.isAvailable = true,
    this.isCertified = false,
  });

  factory Companion.fromJson(Map<String, dynamic> json) {
    double rating = 0;
    if (json['rating'] != null) rating = json['rating'] is double ? json['rating'] : (json['rating'] as num).toDouble();
    if (rating == 0 && json['average_rating'] != null) {
      rating = json['average_rating'] is double ? json['average_rating'] : (json['average_rating'] as num).toDouble();
    }

    double rate = 0;
    if (json['hourly_rate'] != null) rate = json['hourly_rate'] is double ? json['hourly_rate'] : (json['hourly_rate'] as num).toDouble();

    String specialty = json['specialty'] ?? '';
    if (specialty.startsWith('[') || specialty.startsWith('"')) {
      try {
        final parsed = specialty.split(',').map((s) => s.replaceAll(RegExp(r'[\[\]\"\']'), '').trim()).where((s) => s.isNotEmpty).join('、');
        if (parsed.isNotEmpty) specialty = parsed;
      } catch (_) {}
    }

    return Companion(
      id: json['id'] ?? '',
      name: json['name'] ?? json['real_name'] ?? '',
      realName: json['real_name'] ?? '',
      introduction: json['introduction'] ?? '',
      experienceYears: json['experience_years'] ?? 0,
      specialty: specialty,
      hourlyRate: rate,
      rating: rating,
      serviceCount: json['service_count'] ?? 0,
      isAvailable: json['is_available'] == 1 || json['is_available'] == true,
      isCertified: json['is_certified'] == 1 || json['is_certified'] == true,
    );
  }
}
