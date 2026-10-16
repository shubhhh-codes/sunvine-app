import 'package:flutter/material.dart';
import 'app_logger.dart';

/// Navigation observer that logs clean screen transitions.
class AppNavObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    final name = _getRouteName(route);
    if (name.isNotEmpty) {
      AppLogger.nav('Screen: $name');
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      final name = _getRouteName(newRoute);
      if (name.isNotEmpty) {
        AppLogger.nav('Screen replaced with: $name');
      }
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) {
      final name = _getRouteName(previousRoute);
      if (name.isNotEmpty) {
        AppLogger.nav('Returned back to: $name');
      }
    }
  }

  String _getRouteName(Route<dynamic> route) {
    if (route.settings.name != null && route.settings.name!.isNotEmpty) {
      return route.settings.name!;
    }
    // Extract widget class name from route representation
    final routeStr = route.toString();
    final match = RegExp(r'MaterialPageRoute<.+>\((.+)\)').firstMatch(routeStr);
    if (match != null && match.group(1) != null) {
      return match.group(1)!;
    }
    return route.runtimeType.toString();
  }
}
