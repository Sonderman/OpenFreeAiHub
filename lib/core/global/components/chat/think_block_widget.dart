import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

import 'package:freeaihub/core/app_configs.dart';

class ThinkBlockWidget extends StatefulWidget {
  final String content;

  final Map<String, dynamic>? metadata;

  const ThinkBlockWidget({super.key, required this.content, this.metadata});

  /// Static method to clean up all think block timers
  /// Call this when starting a new chat session or when needed
  static void cleanupAllTimers() {
    _ThinkBlockWidgetState._startTimes.clear();
    _ThinkBlockWidgetState._timerStarted.clear();
    if (kDebugMode && showDebugLogs) {
      print('[DEBUG] ThinkBlock - All timer data cleaned up');
    }
  }

  /// Static method to clean up think block timers for completed blocks
  /// This can be called periodically to prevent memory leaks
  static void cleanupCompletedTimers() {
    final keysToRemove = <String>[];

    for (final key in _ThinkBlockWidgetState._timerStarted.keys) {
      // Remove entries older than 1 hour to prevent memory leaks
      if (_ThinkBlockWidgetState._startTimes[key] != null) {
        final age = DateTime.now().difference(_ThinkBlockWidgetState._startTimes[key]!);
        if (age.inHours > 1) {
          keysToRemove.add(key);
        }
      }
    }

    for (final key in keysToRemove) {
      _ThinkBlockWidgetState._startTimes.remove(key);
      _ThinkBlockWidgetState._timerStarted.remove(key);
    }

    if (kDebugMode && keysToRemove.isNotEmpty) {
      print('[DEBUG] ThinkBlock - Cleaned up ${keysToRemove.length} old timer entries');
    }
  }

  @override
  State<ThinkBlockWidget> createState() => _ThinkBlockWidgetState();
}

class _ThinkBlockWidgetState extends State<ThinkBlockWidget> with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;

  // Timer related variables
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _isThinking = true;
  static final Map<String, DateTime> _startTimes = {}; // Static map to persist across rebuilds
  static final Map<String, bool> _timerStarted =
      {}; // Track if timer was started for this think block
  String? _widgetKey;

  @override
  void initState() {
    super.initState();

    // Create a unique key that remains stable during content updates
    // Use a combination of content start and message metadata if available
    final contentStart = widget.content.length > 20
        ? widget.content.substring(0, 20)
        : widget.content;
    final messageId = widget.metadata?['messageId'] ?? '';
    _widgetKey = '$messageId-${contentStart.hashCode}';

    // Check if this think block is already completed
    final isCompleted =
        widget.content.contains("</think>") || widget.metadata?['responseStarted'] == true;

    // Use the thinkBlockStartTime from metadata if available, otherwise use current time
    final metadataStartTime = widget.metadata?['thinkBlockStartTime'];
    DateTime startTime;

    if (metadataStartTime != null && metadataStartTime is int) {
      startTime = DateTime.fromMillisecondsSinceEpoch(metadataStartTime);
    } else {
      startTime = DateTime.now();
    }

    // Only set start time if this is a new think block and timer hasn't been started
    if (!_startTimes.containsKey(_widgetKey) && !_timerStarted.containsKey(_widgetKey)) {
      _startTimes[_widgetKey!] = startTime;
      _timerStarted[_widgetKey!] = true;

      // If think block is already completed, set _isThinking to false immediately
      if (isCompleted) {
        _isThinking = false;
        // Calculate the final elapsed time based on completion
        if (widget.metadata?['thinkBlockEndTime'] != null) {
          final endTime = DateTime.fromMillisecondsSinceEpoch(
            widget.metadata!['thinkBlockEndTime'],
          );
          _elapsedSeconds = endTime.difference(startTime).inSeconds;
        } else {
          _elapsedSeconds = DateTime.now().difference(startTime).inSeconds;
        }

        if (kDebugMode) {
          print(
            '[DEBUG] ThinkBlock loaded as completed for key: $_widgetKey, time: ${_formatDuration(_elapsedSeconds)}',
          );
        }
      } else {
        if (kDebugMode) {
          print('[DEBUG] ThinkBlock timer started for key: $_widgetKey with time: $startTime');
        }
      }
    } else if (_startTimes.containsKey(_widgetKey)) {
      // Update the start time if metadata provides a more accurate one
      if (metadataStartTime != null && metadataStartTime is int) {
        _startTimes[_widgetKey!] = startTime;
        if (kDebugMode) {
          print(
            '[DEBUG] ThinkBlock timer updated for key: $_widgetKey with metadata time: $startTime',
          );
        }
      }

      // Check if this existing think block is completed
      if (isCompleted) {
        _isThinking = false;
        // Calculate elapsed time from stored start time
        if (widget.metadata?['thinkBlockEndTime'] != null) {
          final endTime = DateTime.fromMillisecondsSinceEpoch(
            widget.metadata!['thinkBlockEndTime'],
          );
          _elapsedSeconds = endTime.difference(_startTimes[_widgetKey!]!).inSeconds;
        } else {
          _elapsedSeconds = DateTime.now().difference(_startTimes[_widgetKey!]!).inSeconds;
        }

        if (kDebugMode) {
          print(
            '[DEBUG] ThinkBlock reloaded as completed for key: $_widgetKey, time: ${_formatDuration(_elapsedSeconds)}',
          );
        }
      }
    }

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    // Only start timer if think block is not completed
    if (!isCompleted) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();

    // For completed think blocks, clean up immediately to prevent session loading issues
    final shouldStopTimer =
        widget.content.contains("</think>") || widget.metadata?['responseStarted'] == true;

    if (shouldStopTimer && _widgetKey != null) {
      _startTimes.remove(_widgetKey);
      _timerStarted.remove(_widgetKey);
      if (kDebugMode) {
        print('[DEBUG] ThinkBlock timer cleaned up for completed block: $_widgetKey');
      }
    } else if (_widgetKey != null && !_isThinking) {
      // Also clean up if thinking has stopped for any reason
      _startTimes.remove(_widgetKey);
      _timerStarted.remove(_widgetKey);
      if (kDebugMode) {
        print('[DEBUG] ThinkBlock timer cleaned up for non-thinking block: $_widgetKey');
      }
    }

    super.dispose();
  }

  @override
  void didUpdateWidget(ThinkBlockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update start time if metadata provides a more accurate one
    final metadataStartTime = widget.metadata?['thinkBlockStartTime'];
    if (metadataStartTime != null && metadataStartTime is int && _widgetKey != null) {
      final newStartTime = DateTime.fromMillisecondsSinceEpoch(metadataStartTime);
      final oldStartTime = _startTimes[_widgetKey];

      // Only update if the new time is significantly different (more than 1 second)
      if (oldStartTime == null || (newStartTime.difference(oldStartTime).abs().inSeconds > 1)) {
        _startTimes[_widgetKey!] = newStartTime;
        if (kDebugMode) {
          print(
            '[DEBUG] ThinkBlock timer updated in didUpdateWidget for key: $_widgetKey with new time: $newStartTime',
          );
        }
      }
    }

    // Check if thinking timer should be stopped (response started or think tag completed)
    final shouldStopTimer =
        widget.content.contains("</think>") || widget.metadata?['responseStarted'] == true;
    final wasStopped =
        oldWidget.content.contains("</think>") || oldWidget.metadata?['responseStarted'] == true;

    // Only stop timer if it wasn't already stopped and should now be stopped
    if (shouldStopTimer && !wasStopped && _isThinking) {
      if (kDebugMode) {
        print('[DEBUG] ThinkBlock stopping timer in didUpdateWidget for key: $_widgetKey');
      }
      _stopTimer();
    }
    // Don't restart timer if it was stopped - think blocks should not restart once completed
  }

  void _startTimer() {
    if (_timer?.isActive == true) {
      if (kDebugMode) {
        print('[DEBUG] ThinkBlock timer already active for key: $_widgetKey');
      }
      return;
    }

    // Don't start timer if think block is already completed
    final shouldStopTimer =
        widget.content.contains("</think>") || widget.metadata?['responseStarted'] == true;
    if (shouldStopTimer) {
      if (kDebugMode) {
        print(
          '[DEBUG] ThinkBlock timer not started - think block already completed for key: $_widgetKey',
        );
      }
      return;
    }

    _isThinking = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _widgetKey != null && _startTimes.containsKey(_widgetKey)) {
        final newElapsedSeconds = DateTime.now().difference(_startTimes[_widgetKey]!).inSeconds;
        if (mounted) {
          setState(() {
            _elapsedSeconds = newElapsedSeconds;
          });
        }
      } else {
        // Clean up timer if conditions are not met
        timer.cancel();
      }
    });

    if (kDebugMode) {
      print('[DEBUG] ThinkBlock timer started for key: $_widgetKey');
    }
  }

  void _stopTimer() {
    if (!_isThinking) return; // Already stopped, don't do anything

    _timer?.cancel();
    _timer = null; // Clear the timer reference

    if (mounted) {
      setState(() {
        _isThinking = false;
        // Calculate final elapsed time one last time
        if (_widgetKey != null && _startTimes.containsKey(_widgetKey)) {
          _elapsedSeconds = DateTime.now().difference(_startTimes[_widgetKey]!).inSeconds;
        }
      });
    }

    if (kDebugMode) {
      print(
        '[DEBUG] ThinkBlock timer stopped for key: $_widgetKey, final time: ${_formatDuration(_elapsedSeconds)}',
      );
    }
  }

  void _toggleExpanded() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  String _cleanContent(String rawContent) {
    // Remove think tags and clean up content
    String content = rawContent
        .replaceFirst(RegExp(r'<think>', caseSensitive: false), "")
        .replaceFirst(RegExp(r'</think>', caseSensitive: false), "")
        .trim();

    // If content is too long, show a preview
    if (!_expanded && content.length > 100) {
      return '${content.substring(0, 100)}...';
    }

    return content;
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    } else {
      final minutes = seconds ~/ 60;
      final remainingSeconds = seconds % 60;
      return '${minutes}m ${remainingSeconds}s';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cleanedContent = _cleanContent(widget.content);

    if (cleanedContent.isEmpty) {
      return const SizedBox.shrink();
    }

    // Determine if timer should be stopped (response started or think tag completed)
    final shouldStopTimer =
        widget.content.contains("</think>") || widget.metadata?['responseStarted'] == true;

    // Update timer status if it has changed - but only call _stopTimer once
    if (shouldStopTimer && _isThinking) {
      // Calculate final elapsed time before stopping
      if (_widgetKey != null && _startTimes.containsKey(_widgetKey)) {
        _elapsedSeconds = DateTime.now().difference(_startTimes[_widgetKey]!).inSeconds;
      }
      _stopTimer();
    }

    // Only update elapsed time if still thinking (timer is running)
    // Do NOT update elapsed time for completed think blocks to prevent continuous incrementation
    if (_isThinking && _widgetKey != null && _startTimes.containsKey(_widgetKey)) {
      // This will be updated by the timer periodically, not on every build
      // Just ensure we have a current value if timer hasn't updated yet
      final currentElapsed = DateTime.now().difference(_startTimes[_widgetKey]!).inSeconds;
      if (currentElapsed > _elapsedSeconds) {
        _elapsedSeconds = currentElapsed;
      }
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final backgroundColor = isDarkMode
        ? Theme.of(context).colorScheme.surfaceContainerHighest
        : Theme.of(context).colorScheme.surface;
    final headerColor = isDarkMode
        ? Theme.of(context).colorScheme.primaryContainer
        : Theme.of(context).colorScheme.primary.withOpacity(0.1);
    final textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
    final headerTextColor = isDarkMode ? onSurfaceColor : primaryColor;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: primaryColor.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section
          Material(
            color: headerColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: InkWell(
              onTap: _toggleExpanded,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.psychology, color: headerTextColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isThinking
                                ? 'AI is thinking...'
                                : 'AI thought for ${_formatDuration(_elapsedSeconds)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: headerTextColor,
                              fontSize: 14,
                            ),
                          ),
                          if (_isThinking)
                            Text(
                              _formatDuration(_elapsedSeconds),
                              style: TextStyle(
                                color: headerTextColor.withOpacity(0.8),
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (_isThinking)
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            headerTextColor.withOpacity(0.7),
                          ),
                        ),
                      )
                    else
                      AnimatedBuilder(
                        animation: _rotationAnimation,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _rotationAnimation.value * 3.14159,
                            child: Icon(
                              Icons.expand_more,
                              color: headerTextColor.withOpacity(0.7),
                              size: 20,
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Content section
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _expanded
                ? Container(
                    padding: const EdgeInsets.all(16),
                    width: double.infinity,
                    child: SelectableText(
                      _cleanContent(widget.content),
                      style: TextStyle(color: textColor, fontSize: 13, height: 1.4),
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      _cleanContent(widget.content),
                      style: TextStyle(
                        color: textColor.withOpacity(0.8),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
