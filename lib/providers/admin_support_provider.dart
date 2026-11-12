import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/admin_support_model.dart';
import '../services/admin_support_service.dart';
import 'http_provider.dart';

final adminSupportServiceProvider = Provider<AdminSupportService>((ref) {
  return AdminSupportService(
    httpClient: ref.watch(httpClientProvider),
    apiUrl: ref.watch(apiUrlProvider),
  );
});

class AdminSupportState {
  final List<AdminSupportReport> reports;
  final int total;
  final bool isLoading;
  final String? error;

  const AdminSupportState({
    this.reports = const [],
    this.total = 0,
    this.isLoading = false,
    this.error,
  });

  AdminSupportState copyWith({
    List<AdminSupportReport>? reports,
    int? total,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AdminSupportState(
      reports: reports ?? this.reports,
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class AdminSupportNotifier extends StateNotifier<AdminSupportState> {
  final AdminSupportService _service;

  AdminSupportNotifier(this._service) : super(const AdminSupportState());

  Future<void> fetchReports({String? search, SupportStatus? status}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _service.getReports(search: search, status: status);
      state = state.copyWith(
        reports: response.reports,
        total: response.total,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> updateStatus(int reportId, SupportStatus status) async {
    try {
      final updated = await _service.updateStatus(reportId, status);
      if (!updated) return false;

      state = state.copyWith(
        reports: state.reports
            .map(
              (report) => report.id == reportId
                  ? report.copyWith(status: status)
                  : report,
            )
            .toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final adminSupportNotifierProvider =
    StateNotifierProvider<AdminSupportNotifier, AdminSupportState>((ref) {
      return AdminSupportNotifier(ref.watch(adminSupportServiceProvider));
    });
