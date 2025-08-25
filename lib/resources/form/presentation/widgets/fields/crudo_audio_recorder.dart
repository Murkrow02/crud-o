import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:crud_o_core/configuration/rest_client_configuration.dart';
import 'package:crud_o_core/networking/rest/rest_client.dart';
import 'package:crud_o_core/resources/crudo_resource.dart';
import 'package:crud_o/resources/form/data/crudo_file.dart';
import 'package:crud_o/resources/form/data/crudo_form_context.dart';
import 'package:crud_o/resources/form/presentation/widgets/crudo_view_field.dart';
import 'package:crud_o_core/resources/resource_context.dart';
import 'package:crud_o_core/resources/resource_operation_type.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:futuristic/futuristic.dart';
import 'package:permission_handler/permission_handler.dart';
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
  Uint8List? _audioBytes;
  String? _audioPath;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isPlaying = false;
  bool _isLoading = true;


  @override
  void initState() {
    super.initState();
    _bindAudioPlayerEvents();
    _loadExistingAudio();
  }


  @override
  void dispose() {
    _recorderController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CrudoField(
      config: widget.config,
      editModeBuilder: (context, onChanged) => CrudoFieldWrapper(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_audioBytes != null || _audioPath != null)
                _buildAudioControls()
              else
                _buildRecorderControls(),
            ],
          ),
        ),
      ),
      viewModeBuilder: (context) => CrudoViewField(
        config: widget.config,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : (_audioBytes != null || _audioPath != null)
            ? _buildAudioControls()
            : const Text("Nessun audio"),
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
            if (context.readResourceContext().getCurrentOperationType() == ResourceOperationType.edit)
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
            _recorderController.isRecording
                ? "Ferma registrazione"
                : "Registra",
          ),
        ),
      ],
    );
  }

  Future<void> _loadExistingAudio() async {
    setState(() => _isLoading = true);
    final formContext = context.readFormContext();
    final files = formContext.getFiles(widget.config.name);

    if (files != null && files.isNotEmpty) {
      _audioBytes = files.first.data;
    } else {
      final audioUrl = formContext.get(widget.config.name);
      if (audioUrl != null && audioUrl.isNotEmpty) {
        try {
          _audioBytes = await RestClient().downloadFileBytesFromUri(Uri.parse(audioUrl));
        } catch (e) {
          debugPrint('Error loading audio: $e');
          _audioBytes = null;
        }
      }
    }

    if (_audioBytes != null) {
      try {
        await _audioPlayer.setSourceBytes(_audioBytes!);
        _audioPlayer.onDurationChanged.first.then((duration) {
          if (mounted) setState(() => _totalDuration = duration);
        });
      } catch (e) {
        debugPrint('Error setting audio source: $e');
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _toggleRecording() async {
    if (!await _checkOrRequestPermission()) return;

    if (_recorderController.isRecording) {
      await _recorderController.stopRecording();
      final audioFile = _recorderController.file;
      if (audioFile != null) {
        final fileBytes = await audioFile.readAsBytes();
        _audioBytes = fileBytes;
        _audioPath = audioFile.path;

        context.readFormContext().setFiles(
          widget.config.name,
          [
            CrudoFile(
              data: fileBytes,
              source: FileSource.picker,
              type: FileType.audio,
//              localPath: audioFile.path,
            ),
          ],
        );

        widget.onAudioRecorded?.call(_audioPath, _updateFieldState);
        await _updateDuration();
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
      if (_audioBytes != null) {
        await _audioPlayer.setSourceBytes(_audioBytes!);
        await _audioPlayer.resume();
      } else if (_audioPath != null) {
        final source = DeviceFileSource(_audioPath!);
        await _audioPlayer.setSource(source);
        await _audioPlayer.resume();
      } else {
        return;
      }
    }
    setState(() => _isPlaying = !_isPlaying);
  }

  void _removeAudio() {
    _audioBytes = null;
    _audioPath = null;
    context.readFormContext().setFiles(widget.config.name, []);
    widget.onAudioRemoved?.call();
    _updateFieldState();
  }

  void _updateFieldState() => setState(() {});

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  Future<bool> _checkOrRequestPermission() async {
    return await Permission.microphone.request().isGranted;
  }

  void _bindAudioPlayerEvents() {
    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) setState(() => _currentPosition = position);
    });
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted)
        setState(() {
          _isPlaying = false;
          _currentPosition = Duration.zero;
        });
    });
  }

  Future<void> _updateDuration() async {
    if (_audioBytes == null) return;
    try {
      await _audioPlayer.setSourceBytes(_audioBytes!);
      _audioPlayer.onDurationChanged.first.then((duration) {
        if (mounted) setState(() => _totalDuration = duration);
      });
    } catch (e) {
      debugPrint('Error updating duration: $e');
    }
  }

  void _resetAudioState() {
    if (mounted) {
      setState(() {
        _audioBytes = null;
        _audioPath = null;
        _totalDuration = Duration.zero;
      });
    }
  }
}
