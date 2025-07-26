import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:freeaihub/screens/offline/offline_view.dart';

// Connection quality levels
enum ConnectionQuality { none, poor, fair, good, excellent }

class ConnectivityService extends GetxService {
  late StreamSubscription<InternetStatus> connectionStatusListener;
  RxBool isConnected = false.obs;
  Rx<ConnectionQuality> connectionQuality = ConnectionQuality.none.obs;
  RxInt pingLatency = 0.obs;
  RxBool isCheckingConnection = false.obs;

  bool _isOfflineScreenShown = false;
  Timer? _debounceTimer;
  Timer? _qualityCheckTimer;
  int _consecutiveFailures = 0;
  int _consecutiveSuccesses = 0;

  // Configuration for sensitivity
  static const Duration _debounceDelay = Duration(seconds: 2);
  static const Duration _qualityCheckInterval = Duration(seconds: 30);
  static const Duration _connectionTimeout = Duration(seconds: 10);

  // Multiple test endpoints for better reliability
  static const List<String> _testEndpoints = [
    'google.com',
    'cloudflare.com',
    '8.8.8.8',
    'dns.google',
  ];

  Future<ConnectivityService> init() async {
    // Initial connection check
    await _performInitialCheck();

    // Start listening to connection changes
    connectionStatusListener = InternetConnection().onStatusChange.listen(
      (InternetStatus status) => _handleStatusChange(status),
    );

    // Start periodic quality checks
    _startQualityMonitoring();

    return this;
  }

  Future<void> _performInitialCheck() async {
    isCheckingConnection.value = true;

    try {
      final hasConnection = await _performDetailedConnectionCheck();
      isConnected.value = hasConnection;

      if (hasConnection) {
        await _checkConnectionQuality();
      } else {
        connectionQuality.value = ConnectionQuality.none;
        pingLatency.value = 0;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Initial connection check failed: $e');
      }
      isConnected.value = false;
      connectionQuality.value = ConnectionQuality.none;
    } finally {
      isCheckingConnection.value = false;
    }
  }

  void _handleStatusChange(InternetStatus status) {
    final connected = status == InternetStatus.connected;

    // Cancel previous debounce timer
    _debounceTimer?.cancel();

    // Use debouncing to prevent rapid state changes
    _debounceTimer = Timer(_debounceDelay, () async {
      await _processConnectionChange(connected);
    });
  }

  Future<void> _processConnectionChange(bool connected) async {
    if (connected) {
      _consecutiveFailures = 0;
      _consecutiveSuccesses++;

      // Verify connection with detailed check
      final actuallyConnected = await _performDetailedConnectionCheck();

      if (actuallyConnected) {
        isConnected.value = true;
        await _checkConnectionQuality();
        _handleConnectionRestored();
      } else {
        // False positive, treat as disconnected
        _handleConnectionLost();
      }
    } else {
      _consecutiveSuccesses = 0;
      _consecutiveFailures++;

      // Only show offline after multiple consecutive failures
      if (_consecutiveFailures >= 2) {
        _handleConnectionLost();
      } else {
        // Retry once more before declaring offline
        Timer(const Duration(seconds: 3), () async {
          final stillConnected = await _performDetailedConnectionCheck();
          if (!stillConnected) {
            _handleConnectionLost();
          }
        });
      }
    }
  }

  Future<bool> _performDetailedConnectionCheck() async {
    int successfulChecks = 0;

    for (String endpoint in _testEndpoints) {
      try {
        final result = await InternetAddress.lookup(endpoint).timeout(_connectionTimeout);

        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          successfulChecks++;
        }
      } catch (e) {
        // This endpoint failed, continue with others
        continue;
      }
    }

    // Consider connected if at least 2 out of 4 endpoints respond
    return successfulChecks >= 2;
  }

  Future<void> _checkConnectionQuality() async {
    if (!isConnected.value) return;

    try {
      final latency = await _measurePingLatency();
      pingLatency.value = latency;

      // Determine connection quality based on latency
      if (latency == -1) {
        connectionQuality.value = ConnectionQuality.none;
      } else if (latency > 1000) {
        connectionQuality.value = ConnectionQuality.poor;
      } else if (latency > 500) {
        connectionQuality.value = ConnectionQuality.fair;
      } else if (latency > 200) {
        connectionQuality.value = ConnectionQuality.good;
      } else {
        connectionQuality.value = ConnectionQuality.excellent;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Quality check failed: $e');
      }
      connectionQuality.value = ConnectionQuality.fair;
    }
  }

  Future<int> _measurePingLatency() async {
    try {
      final stopwatch = Stopwatch()..start();

      final result = await InternetAddress.lookup('8.8.8.8').timeout(const Duration(seconds: 5));

      stopwatch.stop();

      if (result.isNotEmpty) {
        return stopwatch.elapsedMilliseconds;
      }

      return -1;
    } catch (e) {
      return -1;
    }
  }

  void _startQualityMonitoring() {
    _qualityCheckTimer = Timer.periodic(_qualityCheckInterval, (timer) {
      if (isConnected.value) {
        _checkConnectionQuality();
      }
    });
  }

  void _handleConnectionLost() {
    isConnected.value = false;
    connectionQuality.value = ConnectionQuality.none;
    pingLatency.value = 0;

    if (!_isOfflineScreenShown) {
      _isOfflineScreenShown = true;
      Get.to(() => const OfflineView());
    }
  }

  void _handleConnectionRestored() {
    if (_isOfflineScreenShown) {
      _isOfflineScreenShown = false;
      // Go back to previous screen or home if no previous
      try {
        Get.back();
      } catch (e) {
        // If can't go back, do nothing
        if (kDebugMode) {
          print('Cannot navigate back: $e');
        }
      }
    }
  }

  // Public method to manually trigger connection check
  Future<void> checkConnection() async {
    isCheckingConnection.value = true;

    try {
      final hasConnection = await _performDetailedConnectionCheck();
      isConnected.value = hasConnection;

      if (hasConnection) {
        await _checkConnectionQuality();
        _handleConnectionRestored();
      } else {
        _handleConnectionLost();
      }
    } finally {
      isCheckingConnection.value = false;
    }
  }

  // Get connection quality as string for UI
  String get connectionQualityText {
    switch (connectionQuality.value) {
      case ConnectionQuality.none:
        return 'No Connection';
      case ConnectionQuality.poor:
        return 'Poor Connection';
      case ConnectionQuality.fair:
        return 'Fair Connection';
      case ConnectionQuality.good:
        return 'Good Connection';
      case ConnectionQuality.excellent:
        return 'Excellent Connection';
    }
  }

  // Check if connection is stable enough for heavy operations
  bool get isStableConnection {
    return isConnected.value &&
        connectionQuality.value != ConnectionQuality.poor &&
        _consecutiveSuccesses >= 2;
  }

  @override
  void onClose() {
    connectionStatusListener.cancel();
    _debounceTimer?.cancel();
    _qualityCheckTimer?.cancel();
    super.onClose();
  }
}
