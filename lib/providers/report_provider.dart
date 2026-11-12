import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/report_model.dart';
import '../services/report_service.dart';
import 'service_providers.dart';

class ReportState {
  final bool isLoading;
  final bool submitted;
  final String? error;

  const ReportState({
    this.isLoading = false,
    this.submitted = false,
    this.error,
  });

  ReportState copyWith({
    bool? isLoading,
    bool? submitted,
    String? error,
    bool clearError = false,
  }) {
    return ReportState(
      isLoading: isLoading ?? this.isLoading,
      submitted: submitted ?? this.submitted,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class ReportNotifier extends StateNotifier<ReportState> {
  final ReportService _service;

  ReportNotifier(this._service) : super(const ReportState());

  Future<bool> createReport(CreateReportRequest request) async {
    state = state.copyWith(isLoading: true, submitted: false, clearError: true);

    try {
      final created = await _service.createReport(request);
      state = state.copyWith(isLoading: false, submitted: created);
      return created;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void resetSubmitted() {
    state = state.copyWith(submitted: false);
  }
}

final reportNotifierProvider =
    StateNotifierProvider<ReportNotifier, ReportState>((ref) {
      return ReportNotifier(ref.watch(reportServiceProvider));
    });