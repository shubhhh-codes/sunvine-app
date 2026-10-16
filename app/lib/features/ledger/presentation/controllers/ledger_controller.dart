import 'package:flutter/foundation.dart';
import '../../../../core/network/api_result.dart';
import '../../data/ledger_repository.dart';
import '../../domain/models/ledger_model.dart';

enum LedgerStatus { initial, loading, loaded, error }

/// Reactive controller managing dealer ledger transactions and payout summaries.
class LedgerController extends ChangeNotifier {
  final ILedgerRepository repository;

  LedgerStatus _status = LedgerStatus.initial;
  List<LedgerEntryModel> _entries = [];
  LedgerSummaryModel? _summary;
  String? _errorMessage;

  LedgerController({required this.repository});

  LedgerStatus get status => _status;
  bool get isLoading => _status == LedgerStatus.loading;
  List<LedgerEntryModel> get entries => _entries;
  LedgerSummaryModel? get summary => _summary;
  String? get errorMessage => _errorMessage;

  /// Loads dealer financial ledger records.
  Future<void> loadLedger() async {
    _status = LedgerStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await repository.getLedger();

    switch (result) {
      case Success(data: final snapshot):
        _entries = snapshot.entries;
        _summary = snapshot.summary;
        _status = LedgerStatus.loaded;
        notifyListeners();
        break;
      case FailureResult(failure: final failure):
        _errorMessage = failure.message;
        _status = LedgerStatus.error;
        notifyListeners();
        break;
    }
  }
}
