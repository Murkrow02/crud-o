import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:waveform_recorder/waveform_recorder.dart';
import 'package:crud_o/resources/form/presentation/widgets/fields/crudo_field.dart';
import 'package:crud_o/resources/form/presentation/widgets/wrappers/crudo_field_wrapper.dart';

class CrudoAudioRecorder extends StatefulWidget {
  final CrudoFieldConfiguration config;
  final AudioRecordedCallback? onAudioRecorded;
  final AudioRemovedCallback? onAudioRemoved;

  const CrudoAudioRecorder({
    super.key,
    required this.config,
    this.onAudioRecorded,
    this.onAudioRemoved,
  });

  @override
  State<CrudoAudioRecorder> createState() => _CrudoAudioRecorderState();
}

typedef AudioRecordedCallback = void Function(
    String? audioPath, void Function() updateFieldState);
typedef AudioRemovedCallback = void Function();

class _CrudoAudioRecorderState extends State<CrudoAudioRecorder> {
  final WaveformRecorderController _recorderController =
  WaveformRecorderController(interval: const Duration(milliseconds: 50));
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _audioPath;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _loadExistingAudio();
    _audioPlayer.onPositionChanged.listen((position) {
      setState(() {
        _currentPosition = position;
      });
    });
    _audioPlayer.onDurationChanged.listen((duration) {
      setState(() {
        _totalDuration = duration;
      });
    });
    _audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        _isPlaying = false;
        _currentPosition = Duration.zero;
      });
    });
  }

  @override
  void dispose() {
    _recorderController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _loadExistingAudio() {
    setState(() {});
  }

  Future<void> _toggleRecording() async {
    if (_recorderController.isRecording) {
      await _recorderController.stopRecording();
      final audioFile = _recorderController.file;
      if (audioFile != null) {
        _audioPath = audioFile.path;
        widget.onAudioRecorded?.call(_audioPath, _updateFieldState);
      }
    } else {
      await _recorderController.startRecording();
    }
    setState(() {});
  }

  Future<void> _togglePlayAudio() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      if (_audioPath == null) return;
      try {
        final source = kIsWeb ? UrlSource(_audioPath!) : DeviceFileSource(_audioPath!);
        await _audioPlayer.setSource(source);
        await _audioPlayer.resume();
      } catch (e) {
        debugPrint('Error playing audio: $e');
      }
    }
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  void _removeAudio() {
    _audioPath = null;
    widget.onAudioRemoved?.call();
    _updateFieldState();
  }

  void _updateFieldState() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return CrudoField(
      config: widget.config,
      editModeBuilder: (context, onChanged) => CrudoFieldWrapper(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_audioPath != null) ...[
                _buildAudioControls(),
              ] else ...[
                _buildRecorderControls(),
              ]
            ],
          ),
        ),
      ),
      viewModeBuilder: (context) => CrudoFieldWrapper(
        child: _audioPath != null
            ? Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _togglePlayAudio,
              icon: const Icon(Icons.play_arrow),
              label: const Text("Riproduci"),
            ),
          ],
        )
            : const Text('Nessun audio registrato'),
      ),
    );
  }

  Widget _buildAudioControls() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: _togglePlayAudio,
              icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
              label: Text(_isPlaying ? "Ferma" : "Riproduci"),
            ),
            ElevatedButton.icon(
              onPressed: _removeAudio,
              icon: const Icon(Icons.delete),
              label: const Text("Elimina"),
            ),
          ],
        ),
        if (_isPlaying || _currentPosition != Duration.zero)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              "${_formatDuration(_currentPosition)} / ${_formatDuration(_totalDuration)}",
              style: const TextStyle(fontSize: 14),
            ),
          ),
      ],
    );
  }

  Widget _buildRecorderControls() {
    return Column(
      children: [
        if (_recorderController.isRecording)
          WaveformRecorder(
            height: 64,
            controller: _recorderController,
          ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _toggleRecording,
          icon: Icon(
            _recorderController.isRecording ? Icons.stop : Icons.mic,
          ),
          label: Text(
            _recorderController.isRecording ? "Ferma registrazione" : "Registra",
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }
}
