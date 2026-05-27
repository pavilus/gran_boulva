// MediaRecorderWidget — inline voice / short-video recorder
// Used inside the argument-submit sheet and the reply sheet.
//
// Usage:
//   MediaRecorderWidget(
//     onMediaReady: (file, type, durationSec) { ... },
//     onClear: () { ... },
//   )
//
// When recording finishes or the user stops early, onMediaReady fires with
// the local File, type string ('audio'|'video'), and duration in seconds.
// Tapping the trash icon calls onClear so the parent can discard any
// previously recorded media.

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:video_player/video_player.dart';

import '../config/app_colors.dart';

typedef MediaReadyCallback = void Function(
    File file, String type, int durationSec);

class MediaRecorderWidget extends StatefulWidget {
  final MediaReadyCallback onMediaReady;
  final VoidCallback onClear;

  const MediaRecorderWidget({
    super.key,
    required this.onMediaReady,
    required this.onClear,
  });

  @override
  State<MediaRecorderWidget> createState() => _MediaRecorderWidgetState();
}

class _MediaRecorderWidgetState extends State<MediaRecorderWidget> {
  static const _maxSeconds = 30;

  // ── mode ──────────────────────────────────────────────────────────────────
  bool _isVideoMode = false; // false = audio, true = video

  // ── recording state ───────────────────────────────────────────────────────
  bool _isRecording = false;
  int _elapsed = 0; // seconds elapsed
  Timer? _timer;

  // ── audio ─────────────────────────────────────────────────────────────────
  final AudioRecorder _audioRecorder = AudioRecorder();

  // ── result ────────────────────────────────────────────────────────────────
  File? _resultFile;
  String? _resultType; // 'audio' | 'video'
  int _resultDuration = 0;

  // ── video preview ─────────────────────────────────────────────────────────
  VideoPlayerController? _videoController;
  bool _videoPlaying = false;

  @override
  void dispose() {
    _timer?.cancel();
    _audioRecorder.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  String get _timeLabel {
    final rem = _maxSeconds - _elapsed;
    final m = rem ~/ 60;
    final s = rem % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _startTimer() {
    _timer?.cancel();
    _elapsed = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed++);
      if (_elapsed >= _maxSeconds) _stopRecording();
    });
  }

  // ── audio recording ───────────────────────────────────────────────────────

  Future<void> _startAudio() async {
    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) return;

    final path = '${Directory.systemTemp.path}'
        '/gb_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _audioRecorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000),
      path: path,
    );
    setState(() => _isRecording = true);
    _startTimer();
  }

  Future<void> _stopAudio() async {
    final path = await _audioRecorder.stop();
    _timer?.cancel();
    if (path == null) return;

    final file = File(path);
    final dur = _elapsed;
    setState(() {
      _isRecording = false;
      _resultFile = file;
      _resultType = 'audio';
      _resultDuration = dur;
    });
    widget.onMediaReady(file, 'audio', dur);
  }

  // ── video recording ───────────────────────────────────────────────────────

  Future<void> _startVideo() async {
    // ImagePicker handles the camera + mic permissions prompt itself.
    setState(() => _isRecording = true);
    _startTimer();

    final picker = ImagePicker();
    final xfile = await picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(seconds: _maxSeconds),
    );

    // pickVideo returns after the user finishes — stop the timer
    _timer?.cancel();
    if (!mounted) return;

    if (xfile == null) {
      setState(() => _isRecording = false);
      return;
    }

    final file = File(xfile.path);
    final dur = _elapsed.clamp(1, _maxSeconds);

    // Build video preview controller
    final ctrl = VideoPlayerController.file(file);
    await ctrl.initialize();

    setState(() {
      _isRecording = false;
      _resultFile = file;
      _resultType = 'video';
      _resultDuration = dur;
      _videoController = ctrl;
    });
    widget.onMediaReady(file, 'video', dur);
  }

  // ── combined start / stop ─────────────────────────────────────────────────

  Future<void> _startRecording() async {
    if (_isVideoMode) {
      await _startVideo();
    } else {
      await _startAudio();
    }
  }

  Future<void> _stopRecording() async {
    if (_isVideoMode) {
      // video is stopped by the OS camera UI; nothing to call here
      _timer?.cancel();
      setState(() => _isRecording = false);
    } else {
      await _stopAudio();
    }
  }

  void _clear() {
    _timer?.cancel();
    _videoController?.dispose();
    setState(() {
      _isRecording = false;
      _elapsed = 0;
      _resultFile = null;
      _resultType = null;
      _resultDuration = 0;
      _videoController = null;
      _videoPlaying = false;
    });
    widget.onClear();
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // If we have a result, show the preview
    if (_resultFile != null) return _buildPreview();

    // Otherwise show the recorder controls
    return _buildRecorder();
  }

  Widget _buildRecorder() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── mode toggle (only when not recording) ──────────────────────
          if (!_isRecording)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ModeChip(
                  icon: Icons.mic_rounded,
                  label: 'Vwa',
                  active: !_isVideoMode,
                  onTap: () => setState(() => _isVideoMode = false),
                ),
                const SizedBox(width: 8),
                _ModeChip(
                  icon: Icons.videocam_rounded,
                  label: 'Videyo',
                  active: _isVideoMode,
                  onTap: () => setState(() => _isVideoMode = true),
                ),
              ],
            ),

          const SizedBox(height: 10),

          // ── timer + record button ─────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isRecording) ...[
                // pulsing red dot
                _PulsingDot(),
                const SizedBox(width: 8),
                Text(
                  _timeLabel,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(width: 16),
              ],
              // record / stop button
              GestureDetector(
                onTap: _isRecording ? _stopRecording : _startRecording,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isRecording
                        ? Colors.redAccent
                        : AppColors.primary.withAlpha(200),
                  ),
                  child: Icon(
                    _isRecording
                        ? Icons.stop_rounded
                        : (_isVideoMode
                            ? Icons.videocam_rounded
                            : Icons.mic_rounded),
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ],
          ),

          if (!_isRecording) ...[
            const SizedBox(height: 6),
            Text(
              _isVideoMode
                  ? 'Tape pou anregistre yon videyo (maks 30s)'
                  : 'Tape pou anregistre yon mesaj vwa (maks 30s)',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withAlpha(100)),
      ),
      child: Row(
        children: [
          // Left: play button
          GestureDetector(
            onTap: _togglePlayback,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withAlpha(200),
              ),
              child: Icon(
                _videoPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Middle: label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _resultType == 'video' ? '🎬 Videyo anregistre' : '🎤 Vwa anregistre',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  '$_resultDuration s',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),

          // Right: re-record / discard
          GestureDetector(
            onTap: _clear,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.withAlpha(30),
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: Colors.redAccent, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _togglePlayback() async {
    if (_resultType == 'video' && _videoController != null) {
      if (_videoPlaying) {
        await _videoController!.pause();
        setState(() => _videoPlaying = false);
      } else {
        await _videoController!.play();
        setState(() => _videoPlaying = true);
        _videoController!.addListener(() {
          if (_videoController!.value.position >=
              _videoController!.value.duration) {
            if (mounted) setState(() => _videoPlaying = false);
          }
        });
      }
    }
    // Audio playback handled by MediaPlayerWidget on the card; preview just
    // shows the file is ready. Could add audioplayer here later.
  }
}

// ── small helpers ─────────────────────────────────────────────────────────────

class _ModeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ModeChip({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: active
              ? AppColors.primary.withAlpha(200)
              : AppColors.cardLight,
          border: Border.all(
            color: active ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 14,
                color: active ? Colors.white : AppColors.textMuted),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _ctrl,
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.redAccent,
        ),
      ),
    );
  }
}
