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
    _instances.clear;
    _factories.clear();
  }
}
