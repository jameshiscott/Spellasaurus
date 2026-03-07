import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../../core/theme/app_colors.dart';

class AudioPlayerButton extends StatefulWidget {
  const AudioPlayerButton({
    super.key,
    required this.audioUrl,
    this.size = 48,
    this.autoPlay = false,
  });

  final String audioUrl;
  final double size;
  final bool autoPlay;

  @override
  State<AudioPlayerButton> createState() => _AudioPlayerButtonState();
}

class _AudioPlayerButtonState extends State<AudioPlayerButton> {
  late final AudioPlayer _player;
  bool _loading = false;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _player.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _playing = state.playing;
          _loading = state.processingState == ProcessingState.loading ||
              state.processingState == ProcessingState.buffering;
        });
      }
    });
    if (widget.autoPlay) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _play());
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _play() async {
    try {
      await _player.setUrl(widget.audioUrl);
      await _player.play();
    } catch (_) {
      // ignore audio errors gracefully
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _loading ? null : _play,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: _loading
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Icon(
                _playing
                    ? Icons.volume_up_rounded
                    : Icons.play_arrow_rounded,
                color: Colors.white,
                size: widget.size * 0.55,
              ),
      ),
    );
  }
}
