import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import '../../features/quotations/data/quotations_repository.dart';

typedef SyncCallback = void Function(int syncedCount);

class AutoSyncService with WidgetsBindingObserver {
  final IQuotationsRepository quotationsRepository;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isSyncing = false;

  final List<SyncCallback> _listeners = [];

  AutoSyncService({required this.quotationsRepository}) {
    WidgetsBinding.instance.addObserver(this);
    _initConnectivityListener();
  }

  void addListener(SyncCallback callback) {
    _listeners.add(callback);
  }

  void removeListener(SyncCallback callback) {
    _listeners.remove(callback);
  }

  void _notifyListeners(int count) {
    for (final listener in _listeners) {
      listener(count);
    }
  }

  void _initConnectivityListener() {
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final isConnected = results.any((r) => r != ConnectivityResult.none);
      if (isConnected) {
        syncPendingDrafts();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      syncPendingDrafts();
    }
  }

  Future<int> syncPendingDrafts() async {
    if (_isSyncing) return 0;
    _isSyncing = true;

    try {
      final results = await _connectivity.checkConnectivity();
      final isConnected = results.any((r) => r != ConnectivityResult.none);
      if (!isConnected) {
        _isSyncing = false;
        return 0;
      }

      final pendingDrafts = await quotationsRepository.getPendingSyncDrafts();
      if (pendingDrafts.isEmpty) {
        _isSyncing = false;
        return 0;
      }

      int syncedCount = 0;
      for (final draft in pendingDrafts) {
        final localId = draft['id']?.toString() ?? '';
        final cleanPayload = Map<String, dynamic>.from(draft);
        cleanPayload.remove('syncPending');
        cleanPayload.remove('savedAt');

        final result = await quotationsRepository.saveQuotation(cleanPayload);
        final resData = result.dataOrNull;
        if (result.isSuccess && resData != null) {
          final quoteObj = resData['quotation'] as Map<String, dynamic>? ?? resData;
          final serverId = quoteObj['id']?.toString() ?? localId;
          final shareToken = quoteObj['share_token']?.toString() ?? quoteObj['shareToken']?.toString() ?? '';

          await quotationsRepository.markDraftSynced(localId, serverId, shareToken);
          syncedCount++;
        }
      }

      if (syncedCount > 0) {
        _notifyListeners(syncedCount);
      }

      _isSyncing = false;
      return syncedCount;
    } catch (_) {
      _isSyncing = false;
      return 0;
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    _listeners.clear();
  }
}
