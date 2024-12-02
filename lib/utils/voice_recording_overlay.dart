import 'dart:async';
import 'package:flutter/material.dart';

class VoiceRecordingIndicator extends StatefulWidget {
  final VoidCallback onCancel;
  final VoidCallback onSend;

  const VoiceRecordingIndicator({
    super.key,
    required this.onCancel,
    required this.onSend,
  });

  @override
  _VoiceRecordingIndicatorState createState() => _VoiceRecordingIndicatorState();
}

class _VoiceRecordingIndicatorState extends State<VoiceRecordingIndicator> {
  late DateTime _startTime;
  late Timer _timer;
  Duration _recordingDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _recordingDuration = DateTime.now().difference(_startTime);
        });
      } else {
        timer.cancel();
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
    decoration: BoxDecoration(
      color: Colors.lightBlue.shade50,
      border: Border(
        top: BorderSide(
          color: Colors.lightBlue.shade200,
          width: 1,
        ),
      ),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.mic, color: Colors.lightBlue.shade300, size: 20),
            const SizedBox(width: 5),
            Text(
              _formatDuration(_recordingDuration),
              style: TextStyle(
                color: Colors.lightBlue.shade500,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
              padding: EdgeInsets.zero,
              icon: Icon(Icons.delete, color: Colors.lightBlue.shade300, size: 20),
              onPressed: () {
                widget.onCancel();
                
              },
            ),
            IconButton(
              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
              padding: EdgeInsets.zero,
              icon: Icon(Icons.send, color: Colors.lightBlue.shade300, size: 20),
              onPressed: () {
                widget.onSend();
              },
            ),
          ],
        ),
      ],
    ),
            );
  }
}