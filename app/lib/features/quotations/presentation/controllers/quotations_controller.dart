import 'package:flutter/foundation.dart';
import '../../../../core/network/api_result.dart';
import '../../data/quotations_repository.dart';
import '../../domain/models/quotation_model.dart';

enum QuotationsStatus { initial, loading, loaded, error }

/// Reactive controller managing quotation lists, search filtering, and error handling.
class QuotationsController extends ChangeNotifier {
  final IQuotationsRepository repository;

  QuotationsStatus _status = QuotationsStatus.initial;
  List<QuotationModel> _allQuotations = [];
  String _searchQuery = '';
  String? _errorMessage;

  QuotationsController({required this.repository});

  QuotationsStatus get status => _status;
  bool get isLoading => _status == QuotationsStatus.loading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  /// Returns filtered quotations matching search query.
  List<QuotationModel> get filteredQuotations {
    if (_searchQuery.trim().isEmpty) return _allQuotations;
    final q = _searchQuery.toLowerCase().trim();
    return _allQuotations.where((quote) {
      return quote.customerName.toLowerCase().contains(q) ||
          quote.quoteNumber.toLowerCase().contains(q) ||
          quote.customerPhone.contains(q) ||
          quote.status.toLowerCase().contains(q);
    }).toList();
  }

  /// Loads quotations list from gateway.
  Future<void> loadQuotations() async {
    _status = QuotationsStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await repository.getQuotations();

    switch (result) {
      case Success(data: final data):
        _allQuotations = data;
        _status = QuotationsStatus.loaded;
        notifyListeners();
        break;
      case FailureResult(failure: final failure):
        _errorMessage = failure.message;
        _status = QuotationsStatus.error;
        notifyListeners();
        break;
    }
  }

  /// Updates search query filter.
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
}
