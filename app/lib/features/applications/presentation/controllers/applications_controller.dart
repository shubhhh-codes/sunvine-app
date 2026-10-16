import 'package:flutter/foundation.dart';
import '../../../../core/network/api_result.dart';
import '../../data/applications_repository.dart';
import '../../domain/models/customer_file_model.dart';

enum ApplicationsStatus { initial, loading, loaded, error }

/// Reactive controller managing active customer installation pipelines.
class ApplicationsController extends ChangeNotifier {
  final IApplicationsRepository repository;

  ApplicationsStatus _status = ApplicationsStatus.initial;
  List<CustomerFileModel> _applications = [];
  String? _errorMessage;

  ApplicationsController({required this.repository});

  ApplicationsStatus get status => _status;
  bool get isLoading => _status == ApplicationsStatus.loading;
  String? get errorMessage => _errorMessage;
  List<CustomerFileModel> get applications => _applications;

  /// Loads pipeline application files.
  Future<void> loadApplications() async {
    _status = ApplicationsStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await repository.getCustomerFiles();

    switch (result) {
      case Success(data: final data):
        _applications = data;
        _status = ApplicationsStatus.loaded;
        notifyListeners();
        break;
      case FailureResult(failure: final failure):
        _errorMessage = failure.message;
        _status = ApplicationsStatus.error;
        notifyListeners();
        break;
    }
  }
}
