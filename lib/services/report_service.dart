import '../models/report_model.dart';
import 'base_service.dart';

class ReportService extends BaseService {
  ReportService({required super.httpClient, required super.apiUrl});

  @override
  String get basePath => '/support';

  Future<bool> createReport(CreateReportRequest request) {
    return post<bool>(
      '/create',
      fromJson: (_) => true,
      body: request.toJson(),
    );
  }
}