import '../models/admin_support_model.dart';
import 'base_service.dart';

class AdminSupportService extends BaseService {
  AdminSupportService({required super.httpClient, required super.apiUrl});

  @override
  String get basePath => '/admin/support';

  Future<AdminSupportResponse> getReports({
    String? search,
    SupportStatus? status,
  }) {
    final query = <String, String>{};
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    if (status != null) query['status'] = status.value;

    return get<AdminSupportResponse>(
      '',
      queryParams: query.isEmpty ? null : query,
      fromJson: (json) => AdminSupportResponse.fromJson(json),
    );
  }

  Future<AdminSupportReport> getReport(int id) {
    return get<AdminSupportReport>(
      '/$id',
      fromJson: (json) => AdminSupportReport.fromJson(json),
    );
  }

  Future<bool> updateStatus(int reportId, SupportStatus status) {
    return put<bool>(
      '/respond',
      fromJson: (_) => true,
      body: {'reportId': reportId, 'status': status.value},
    );
  }
}
