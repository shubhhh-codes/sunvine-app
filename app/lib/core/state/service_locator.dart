import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/domain/auth_service.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/quotations/data/quotations_repository.dart';
import '../services/auto_sync_service.dart';

/// A lightweight, zero-dependency service locator for Dependency Injection.
///
/// Enables clean decoupling between data repositories, services, controllers, and UI.
class ServiceLocator {
  ServiceLocator._();

  static final Map<Type, dynamic> _instances = {};
  static final Map<Type, dynamic Function()> _factories = {};

  /// Registers a singleton instance of type [T].
  static void registerSingleton<T>(T instance) {
    _instances[T] = instance;
  }

  /// Registers a lazy factory that generates an instance of type [T] when requested.
  static void registerFactory<T>(T Function() factory) {
    _factories[T] = factory;
  }

  /// Retrieves an instance of type [T].
  ///
  /// Throws [StateError] if type [T] has not been registered.
  static T get<T>() {
    if (_instances.containsKey(T)) {
      return _instances[T] as T;
    }
    if (_factories.containsKey(T)) {
      return _factories[T]!() as T;
    }
    throw StateError('ServiceLocator: No instance or factory registered for type $T.');
  }

  /// Checks if a type [T] has been registered.
  static bool isRegistered<T>() {
    return _instances.containsKey(T) || _factories.containsKey(T);
  }

  /// Resets all registered singletons and factories (useful for unit/widget testing).
  static void reset() {
    _instances.clear();
    _factories.clear();
  }

  // Convenient static accessors
  static AuthService get authService => get<AuthService>();
  static AuthRepository get authRepository => get<AuthRepository>();
  static AuthController get authController => get<AuthController>();
  static IQuotationsRepository get quotationsRepository => get<IQuotationsRepository>();
  static AutoSyncService get autoSyncService => get<AutoSyncService>();
}
