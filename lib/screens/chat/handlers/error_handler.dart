import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Custom exception class for chat-related errors
class ChatException implements Exception {
  final String message;
  final String? code;
  final Exception? originalException;

  const ChatException(this.message, {this.code, this.originalException});

  @override
  String toString() => 'ChatException: $message';
}

/// Handles all error-related functionality for chat operations
class ErrorHandler {
  final RxString errorMessage = ''.obs;
  final RxBool hasError = false.obs;

  /// Show error message to user and update error state
  void showError(String message, {Exception? exception}) {
    errorMessage.value = message;
    hasError.value = true;
    Get.snackbar(
      'Error',
      message,
      backgroundColor: Colors.red.shade100,
      colorText: Colors.red.shade800,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 4),
    );
  }

  /// Clear error state
  void clearError() {
    errorMessage.value = '';
    hasError.value = false;
  }

  /// Check if there's currently an error
  bool get hasCurrentError => hasError.value;

  /// Get current error message
  String get currentErrorMessage => errorMessage.value;
}
