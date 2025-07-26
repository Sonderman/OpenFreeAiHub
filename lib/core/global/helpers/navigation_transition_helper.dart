import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Custom transition helper for iOS-style page transitions
class IOSTransition {
  /// Default iOS transition duration
  static const Duration defaultDuration = Duration(milliseconds: 350);

  /// Default iOS curve
  static const Curve defaultCurve = Curves.easeInOut;

  /// Creates iOS-style slide transition from right to left
  static GetPageRoute createRoute({
    required Widget page,
    String? routeName,
    Bindings? binding,
    Duration? duration,
    Curve? curve,
  }) {
    return GetPageRoute(
      page: () => page,
      routeName: routeName,
      binding: binding,
      transition: Transition.cupertino,
      transitionDuration: duration ?? defaultDuration,
      curve: curve ?? defaultCurve,
    );
  }

  /// Creates iOS-style modal transition from bottom to top
  static GetPageRoute createModalRoute({
    required Widget page,
    String? routeName,
    Bindings? binding,
    Duration? duration,
    Curve? curve,
  }) {
    return GetPageRoute(
      page: () => page,
      routeName: routeName,
      binding: binding,
      transition: Transition.downToUp,
      transitionDuration: duration ?? defaultDuration,
      curve: curve ?? defaultCurve,
    );
  }

  /// Creates iOS-style fade transition
  static GetPageRoute createFadeRoute({
    required Widget page,
    String? routeName,
    Bindings? binding,
    Duration? duration,
  }) {
    return GetPageRoute(
      page: () => page,
      routeName: routeName,
      binding: binding,
      transition: Transition.fade,
      transitionDuration: duration ?? const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  /// Navigation helpers with iOS-style transitions
  static Future<T?>? toWithCupertinoTransition<T>(
    String routeName, {
    dynamic arguments,
    Duration? duration,
    Curve? curve,
  }) {
    return Get.toNamed(routeName, arguments: arguments);
  }

  /// Modal navigation with iOS-style bottom-to-top transition
  static Future<T?>? toModalWithTransition<T>(
    String routeName, {
    dynamic arguments,
    Duration? duration,
    Curve? curve,
  }) {
    return Get.toNamed(routeName, arguments: arguments);
  }
}
