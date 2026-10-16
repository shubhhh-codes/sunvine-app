import 'package:flutter/foundation.dart';
import '../../../../core/network/api_result.dart';
import '../../data/dashboard_repository.dart';
import '../../domain/dashboard_models.dart';

/// State representation for Dashboard data loading.
enum DashboardStatus { initial, loading, loaded, error }

/// Reactive controller managing Dashboard overview telemetry and filter states.
class DashboardController extends ChangeNotifier {
  final IDashboardRepository repository;

  DashboardStatus _status = DashboardStatus.initial;
  DashboardOverview? _overview;
  String? _errorMessage;
  String _selectedRange = 'Last 30 Days';

  final List<String> timeRanges = const [
    'Today',
    'Last 7 Days',
    'Last 30 Days',
    'This Quarter',
    'Financial Year',
  ];

  DashboardController({required this.repository});

  DashboardStatus get status => _status;
  DashboardOverview? get overview => _overview;
  String? get errorMessage => _errorMessage;
  String get selectedRange => _selectedRange;
  bool get isLoading => _status == DashboardStatus.loading;

  /// Loads dashboard metrics.
  Future<void> loadDashboard() async {
    _status = DashboardStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await repository.getDashboardOverview(range: _selectedRange);

    switch (result) {
      case Success(data: final data):
        _overview = data;
        _status = DashboardStatus.loaded;
        notifyListeners();
        break;
      case FailureResult(failure: final failure):
        _errorMessage = failure.message;
        _status = DashboardStatus.error;
        notifyListeners();
        break;
    }
  }

  /// Sets active time range and refreshes overview.
  Future<void> setTimeRange(String range) async {
    if (_selectedRange == range) return;
    _selectedRange = range;
    notifyListeners();
    await loadDashboard();
  }
}
