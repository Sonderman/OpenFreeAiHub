import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:path_provider/path_provider.dart';

class AudioPlayerWidget extends StatefulWidget {
  final Uint8List audioData;

  const AudioPlayerWidget({super.key, required this.audioData});

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late PlayerController _playerController;
  bool _isPlaying = false;
  bool _isLoading = true;
  late String _tempFilePath;

  @override
  void initState() {
    super.initState();
    _playerController = PlayerController();
    _initAudio();
  }

  @override
  void didUpdateWidget(AudioPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.audioData != oldWidget.audioData) {
      _reinitAudio();
    }
  }

  Future<void> _reinitAudio() async {
    _playerController.dispose();
    _playerController = PlayerController();
    _isLoading = true;
    await _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      final dir = await getTemporaryDirectory();
      _tempFilePath = '${dir.path}/temp_audio.wav';
      await File(_tempFilePath).writeAsBytes(widget.audioData);

      await _playerController.preparePlayer(
        path: _tempFilePath,
        shouldExtractWaveform: true,
        noOfSamples: 100,
      );
      //_waveformData = await _playerController.extractWaveformData(path: _tempFilePath);
      _playerController.setFinishMode(finishMode: FinishMode.pause);

      _playerController.onPlayerStateChanged.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state == PlayerState.playing;
          });
          if (state == PlayerState.stopped) {
            _playerController.seekTo(0);
          }
        }
      });

      setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      if (kDebugMode) {
        print('Error initializing audio: $e');
      }
    }
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _playerController.pausePlayer();
    } else {
      await _playerController.startPlayer();
    }
  }

  @override
  void dispose() {
    _playerController.dispose();
    try {
      File(_tempFilePath).delete();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting temp file: $e');
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 100,
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : GestureDetector(
                      onTapDown: (details) async {
                        final box = context.findRenderObject() as RenderBox;
                        final localPosition = details.localPosition;
                        final percent = localPosition.dx / box.size.width;
                        final durationMs = await _playerController.getDuration(DurationType.max);
                        final duration = Duration(milliseconds: durationMs);
                        final position = duration * percent;
                        await _playerController.seekTo(position.inMilliseconds.toInt());
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors:
                                Theme.of(context).brightness == Brightness.light
                                    ? [Colors.grey, Colors.brown]
                                    : [
                                      Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                      Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                    ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: AudioFileWaveforms(
                          size: Size(MediaQuery.of(context).size.width, 100),
                          playerController: _playerController,
                        ),
                      ),
                    ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              StreamBuilder<Duration>(
                stream: _playerController.onCurrentDurationChanged.map(
                  (ms) => Duration(milliseconds: ms),
                ),
                builder: (context, snapshot) {
                  final position = snapshot.data ?? Duration.zero;
                  return Text(
                    '${position.inMinutes}:${(position.inSeconds % 60).toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.bodySmall,
                  );
                },
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                iconSize: 36,
                onPressed: _togglePlayPause,
              ),
              const SizedBox(width: 16),
              FutureBuilder<Duration>(
                future: _playerController
                    .getDuration(DurationType.max)
                    .then((ms) => Duration(milliseconds: ms)),
                builder: (context, snapshot) {
                  final duration = snapshot.data ?? Duration.zero;
                  return Text(
                    '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.bodySmall,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
