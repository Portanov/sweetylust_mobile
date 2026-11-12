enum SupportStatus {
  pending('pending', 'Pendiente'),
  reviewed('reviewed', 'Revisado'),
  closed('closed', 'Cerrado');

  const SupportStatus(this.value, this.label);

  final String value;
  final String label;

  static SupportStatus fromValue(String? value) {
    return SupportStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => SupportStatus.pending,
    );
  }
}

class AdminSupportReport {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String subject;
  final String message;
  final SupportStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AdminSupportReport({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.subject,
    required this.message,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory AdminSupportReport.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    return AdminSupportReport(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      subject: json['subject']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      status: SupportStatus.fromValue(json['status']?.toString()),
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }

  AdminSupportReport copyWith({SupportStatus? status}) {
    return AdminSupportReport(
      id: id,
      name: name,
      email: email,
      phone: phone,
      subject: subject,
      message: message,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class AdminSupportResponse {
  final List<AdminSupportReport> reports;
  final int total;

  const AdminSupportResponse({required this.reports, required this.total});

  factory AdminSupportResponse.fromJson(Map<String, dynamic> json) {
    final reports = json['reports'];
    return AdminSupportResponse(
      reports: reports is List
          ? reports
                .whereType<Map>()
                .map(
                  (report) => AdminSupportReport.fromJson(
                    Map<String, dynamic>.from(report),
                  ),
                )
                .toList()
          : const [],
      total: _parseInt(json['total']),
    );
  }
}

int _parseInt(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
