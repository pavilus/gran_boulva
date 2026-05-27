// MediaPlayerWidget — displays a recorded audio pill or a tappable video thumbnail
// on argument cards and reply rows.
//
// Usage:
//   MediaPlayerWidget(
//     url: argument.mediaUrl!,
//     type: argument.mediaType!,   // 'audio' | 'video'
//     duration: argument.mediaDuration,
//   )

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../config/app_colors.dart';

class MediaPlayerWidget extends StatefulWidget {
  final String url;
  final String type; // 'audio' | 'video'
  final int? duration; // seconds, for display only

  const MediaPlayerWidget({
    super.key,
    required this.url,
    required this.type,
    this.duration,
  });

  @override
  State<MediaPlayerWidget> createState() => _MediaPlayerWidgetState();
}

class _MediaPlayerWidgetState extends State<MediaPlayerWidget> {
  // ── audio ─────────────────────────────────────────────────────────────────
  final AudioPlayer _audio = AudioPlayer();
  bool _audioPlaying = false;
  int _audioElapsed = 0; // seconds
  StreamSubscription? _positionSub;

  // ── video ─────────────────────────────────────────────────────────────────
  VideoPlayerController? _videoCtrl;
  bool _videoReady = false;
  bool _videoPlaying = false;

  @override
  void initState() {
    super.initState();
    if (widget.type == 'video') _initVideo();
    if (widget.type == 'audio') _initAudio();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _audio.dispose();
    _videoCtrl?.dispose();
    super.dispose();
  }

  // ── audio setup ───────────────────────────────────────────────────────────

  void _initAudio() {
    _positionSub = _audio.onPositionChanged.listen((pos) {
      if (mounted) setState(() => _audioElapsed = pos.inSeconds);
    });
    _audio.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _audioPlaying = false;
          _audioElapsed = 0;
        });
      }
    });
  }

  Future<void> _toggleAudio() async {
    if (_audioPlaying) {
      await _audio.pause();
      setState(() => _audioPlaying = false);
    } else {
      await _audio.play(UrlSource(widget.url));
      setState(() => _audioPlaying = true);
    }
  }

  // ── video setup ───────────────────────────────────────────────────────────

  Future<void> _initVideo() async {
    final ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    await ctrl.initialize();
    ctrl.addListener(() {
      if (!mounted) return;
      final playing = ctrl.value.isPlaying;
      if (playing != _videoPlaying) setState(() => _videoPlaying = playing);
      if (!playing &&
          ctrl.value.position >= ctrl.value.duration &&
          ctrl.value.duration > Duration.zero) {
        ctrl.seekTo(Duration.zero);
      }
    });
    if (mounted) {
      setState(() {
        _videoCtrl = ctrl;
        _videoReady = true;
      });
    }
  }

  Future<void> _toggleVideo() async {
    if (_videoCtrl == null) return;
    if (_videoPlaying) {
      await _videoCtrl!.pause();
    } else {
      await _videoCtrl!.play();
    }
  }

  // ── formatters ────────────────────────────────────────────────────────────

  String _fmt(int? sec) {
    final s = sec ?? 0;
    final m = s ~/ 60;
    final r = s % 60;
    return '${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}';
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (widget.type == 'audio') return _buildAudioPill();
    return _buildVideoThumbnail();
  }

  // ── audio pill ────────────────────────────────────────────────────────────

  Widget _buildAudioPill() {
    final total = widget.duration ?? 0;
    final elapsed = _audioElapsed.clamp(0, total);

    return GestureDetector(
      onTap: _toggleAudio,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(25),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.primary.withAlpha(80)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // play/pause icon
            Icon(
              _audioPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
              color: AppColors.primary,
              size: 26,
            ),
            const SizedBox(width: 8),

            // waveform bars (decorative, static)
            _WaveformBars(playing: _audioPlaying),
            const SizedBox(width: 8),

            // elapsed / total
            Text(
              _audioPlaying ? _fmt(elapsed) : _fmt(total),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── video thumbnail ───────────────────────────────────────────────────────

  Widget _buildVideoThumbnail() {
    if (!_videoReady || _videoCtrl == null) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.cardLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final aspect = _videoCtrl!.value.aspectRatio;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: aspect > 0 ? aspect : 16 / 9,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(_videoCtrl!),

            // dim overlay when paused
            if (!_videoPlaying)
              Container(color: Colors.black.withAlpha(80)),

            // play/pause button
            GestureDetector(
              onTap: _toggleVideo,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withAlpha(140),
                ),
                child: Icon(
                  _videoPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),

            // duration badge (bottom-right, shown when paused)
            if (!_videoPlaying && widget.duration != null)
              Positioned(
                bottom: 6,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(160),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _fmt(widget.duration),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Waveform bars (decorative animated equaliser) ─────────────────────────────

class _WaveformBars extends StatefulWidget {
  final bool playing;
  const _WaveformBars({required this.playing});

  @override
  State<_WaveformBars> createState() => _WaveformBarsState();
}

class _WaveformBarsState extends State<_WaveformBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    if (widget.playing) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_WaveformBars old) {
    super.didUpdateWidget(old);
    if (widget.playing && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.playing && _ctrl.isAnimating) {
      _ctrl.stop();
      _ctrl.value = 0.3;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const heights = [8.0, 14.0, 10.0, 16.0, 8.0];
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(heights.length, (i) {
            final t = (_ctrl.value + i * 0.15) % 1.0;
            final h = widget.playing
                ? heights[i] * (0.4 + 0.6 * (i.isEven ? t : 1 - t))
                : heights[i] * 0.4;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.5),
              child: Container(
                width: 3,
                height: h,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(200),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
