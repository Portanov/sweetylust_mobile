class CreateReportRequest {
  final String name;
  final String email;
  final String? phone;
  final String subject;
  final String message;

  const CreateReportRequest({
    required this.name,
    required this.email,
    this.phone,
    required this.subject,
    required this.message,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    if (phone != null && phone!.isNotEmpty) 'phone': phone,
    'subject': subject,
    'message': message,
  };
}