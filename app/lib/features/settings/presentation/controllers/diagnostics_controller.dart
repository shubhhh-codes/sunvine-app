import 'package:flutter/foundation.dart';
import '../../../../core/network/api_result.dart';
import '../../data/system_repository.dart';

enum DiagnosticsStatus { initial, loading, loaded, error }

/// Reactive controller managing gateway health telemetry and environment diagnostics.
class DiagnosticsController extends ChangeNotifier {
  final ISystemRepository repository;

  DiagnosticsStatus _status = DiagnosticsStatus.initial;
  Map<String, dynamic>? _healthData;
  String? _errorMessage;

  DiagnosticsController({required this.repository});

  DiagnosticsStatus get status => _status;
  bool get isLoading => _status == DiagnosticsStatus.loading;
  Map<String, dynamic>? get healthData => _healthData;
  String? get errorMessage => _errorMessage;

  /// Fetches gateway health indicators.
  Future<void> fetchHealth() async {
    _status = DiagnosticsStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await repository.checkHealth();

    switch (result) {
      case Success(data: final data):
        _healthData = data;
        _status = DiagnosticsStatus.loaded;
        notifyListeners();
        break;
      case FailureResult(failure: final failure):
        _errorMessage = failure.message;
        _status = DiagnosticsStatus.error;
        notifyListeners();
        break;
    }
  }
}
