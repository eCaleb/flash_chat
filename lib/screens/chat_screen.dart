import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart' as audio;
import 'package:permission_handler/permission_handler.dart';

// Cloudinary Configuration
const String cloudinaryUrl = 'https://api.cloudinary.com/v1_1/dnho1jy15/auto/upload';
const String uploadPreset = 'unsigned_upload';

final _firestore = FirebaseFirestore.instance;
firebase_auth.User? loggedInUser;

// Cloudinary Service Class
class CloudinaryService {
  static Future<String?> uploadToCloudinary(dynamic file, String fileName) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(cloudinaryUrl));
      
      if (file is File) {
        request.files.add(await http.MultipartFile.fromPath('file', file.path));
      } else if (file is Uint8List) {
        request.files.add(http.MultipartFile.fromBytes('file', file, filename: fileName));
      }
      
      request.fields['upload_preset'] = uploadPreset;
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        return jsonResponse['secure_url'];
      }
      return null;
    } catch (e) {
      print('Error uploading to Cloudinary: $e');
      return null;
    }
  }
}

class ChatScreen extends StatefulWidget {
  static const String id = 'chat_screen';

  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final messageTextController = TextEditingController();
  final _auth = firebase_auth.FirebaseAuth.instance;
  final FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();
  bool isRecording = false;
  bool isRecordingEnabled = true;
  String messageText = '';

  @override
  void initState() {
    super.initState();
    getCurrentUser();
    initRecorder();
  }

  void getCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        loggedInUser = user;
      });
      print('Logged in as: ${loggedInUser!.email}');
    } else {
      print('No user is currently logged in.');
    }
  }

  Future<bool> _requestMicrophonePermission() async {
    PermissionStatus status = await Permission.microphone.request();
    return status == PermissionStatus.granted;
  }

  Future<void> initRecorder() async {
    bool permissionGranted = await _requestMicrophonePermission();
    if (!permissionGranted) {
      setState(() {
        isRecordingEnabled = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission is required')),
      );
      return;
    }

    try {
      await _audioRecorder.openRecorder();
      await _audioRecorder.setSubscriptionDuration(const Duration(milliseconds: 500));
      setState(() {
        isRecordingEnabled = true;
      });
    } catch (e) {
      print('Error initializing recorder: $e');
    }
  }

  @override
  void dispose() {
    _audioRecorder.closeRecorder();
    super.dispose();
  }

  Future<void> uploadFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null && result.files.isNotEmpty) {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );

        String fileName = result.files.first.name;
        String fileType = result.files.first.extension ?? '';
        String? cloudinaryUrl;

        if (result.files.first.path != null) {
          File file = File(result.files.first.path!);
          cloudinaryUrl = await CloudinaryService.uploadToCloudinary(file, fileName);
        } else if (result.files.first.bytes != null) {
          cloudinaryUrl = await CloudinaryService.uploadToCloudinary(
            result.files.first.bytes!,
            fileName,
          );
        }

        // Hide loading indicator
        Navigator.pop(context);

        if (cloudinaryUrl != null) {
          await _firestore.collection('messages').add({
            'fileName': fileName,
            'fileType': fileType,
            'fileUrl': cloudinaryUrl,
            'sender': loggedInUser?.email ?? 'Unknown',
            'timestamp': FieldValue.serverTimestamp(),
          });
          print('File uploaded successfully.');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload file')),
          );
        }
      }
    } catch (e) {
      print('Error uploading file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error uploading file')),
      );
    }
  }

  Future<void> startRecording() async {
    try {
      if (!await Permission.microphone.isGranted) {
        print('Microphone permission not granted');
        return;
      }
      final directory = await getTemporaryDirectory();
      final audioPath = '${directory.path}/${const Uuid().v4()}.aac';
      await _audioRecorder.startRecorder(toFile: audioPath);
      setState(() {
        isRecording = true;
      });
    } catch (e) {
      print('Error starting recording: $e');
    }
  }

  Future<void> stopRecording() async {
    try {
      final audioPath = await _audioRecorder.stopRecorder();
      setState(() {
        isRecording = false;
      });

      if (audioPath != null) {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );

        File audioFile = File(audioPath);
        String audioFileName = '${const Uuid().v4()}.aac';
        
        // Upload to Cloudinary
        String? cloudinaryUrl = await CloudinaryService.uploadToCloudinary(
          audioFile,
          audioFileName,
        );

        // Hide loading indicator
        Navigator.pop(context);

        if (cloudinaryUrl != null) {
          await _firestore.collection('messages').add({
            'audioFileName': audioFileName,
            'audioUrl': cloudinaryUrl,
            'sender': loggedInUser?.email ?? 'Unknown',
            'timestamp': FieldValue.serverTimestamp(),
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload audio')),
          );
        }
      }
    } catch (e) {
      print('Error stopping recording: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error uploading audio')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              _auth.signOut();
              Navigator.pop(context);
            },
          ),
        ],
        title: const Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const MessageStream(),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    onPressed: uploadFile,
                  ),
                  IconButton(
                    icon: Icon(
                      isRecording ? Icons.mic_off : Icons.mic,
                      color: isRecording ? Colors.red : Colors.grey,
                    ),
                    onPressed: isRecording ? stopRecording : startRecording,
                  ),
                  Expanded(
                    child: TextField(
                      controller: messageTextController,
                      onChanged: (value) {
                        messageText = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      if (loggedInUser != null && messageText.isNotEmpty) {
                        messageTextController.clear();

                        _firestore.collection('messages').add({
                          'text': messageText,
                          'sender': loggedInUser!.email,
                          'timestamp': FieldValue.serverTimestamp(),
                        });

                        setState(() {
                          messageText = '';
                        });
                      }
                    },
                    child: const Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}



class MessageStream extends StatelessWidget {
  const MessageStream({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('messages').orderBy('timestamp').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              backgroundColor: Colors.lightBlueAccent,
            ),
          );
        }

        final messages = snapshot.data!.docs.reversed;
        List<MessageBubble> messageBubbles = [];
        for (var message in messages) {
          final messageData = message.data() as Map<String, dynamic>;
          final messageText = messageData['text'] ?? '';
          final messageSender = messageData['sender'] ?? '';
          final fileUrl = messageData['fileUrl'] ?? '';
          final fileType = messageData['fileType'] ?? '';
          final audioUrl = messageData['audioUrl'] ?? '';
          final currentUser = loggedInUser?.email;

          messageBubbles.add(
            MessageBubble(
              text: messageText,
              sender: messageSender,
              fileUrl: fileUrl,
              fileType: fileType,
              audioUrl: audioUrl,
              isMe: messageSender == currentUser,
            ),
          );
        }

        return Expanded(
          child: ListView(
            reverse: true,
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
            children: messageBubbles,
          ),
        );
      },
    );
  }
}

class MessageBubble extends StatelessWidget {
  final String text;
  final String sender;
  final String fileUrl;
  final String fileType;
  final String audioUrl;
  final bool isMe;

  const MessageBubble({
    super.key,
    required this.text,
    required this.sender,
    this.fileUrl = '',
    this.fileType = '',
    this.audioUrl = '',
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            sender,
            style: const TextStyle(color: Colors.black54, fontSize: 12.0),
          ),
          if (fileUrl.isNotEmpty)
            GestureDetector(
              onTap: () {
                if (fileType.toLowerCase() == 'pdf') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PdfViewerScreen(pdfUrl: fileUrl),
                    ),
                  );
                }
              },
              child: Container(
                margin: const EdgeInsets.only(top: 5.0, bottom: 5.0),
                child: fileType.toLowerCase() == 'pdf'
                    ? Container(
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.picture_as_pdf, color: Colors.red),
                            SizedBox(width: 8.0),
                            Text('View PDF'),
                          ],
                        ),
                      )
                    : Image.network(
                        fileUrl,
                        height: 150,
                        width: 150,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(child: CircularProgressIndicator());
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.error);
                        },
                      ),
              ),
            ),
          if (audioUrl.isNotEmpty)
            AudioMessageBubble(
              audioUrl: audioUrl,
              isMe: isMe,
            ),
          if (text.isNotEmpty)
            Material(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isMe ? 30.0 : 0.0),
                topRight: Radius.circular(isMe ? 0.0 : 30.0),
                bottomLeft: const Radius.circular(30.0),
                bottomRight: const Radius.circular(30.0),
              ),
              color: isMe ? Colors.lightBlueAccent : Colors.white,
              elevation: 5.0,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 10.0,
                  horizontal: 12.0,
                ),
                child: Text(
                  text,
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black,
                    fontSize: 15.0,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class AudioMessageBubble extends StatefulWidget {
  final String audioUrl;
  final bool isMe;

  const AudioMessageBubble({
    super.key,
    required this.audioUrl,
    required this.isMe,
  });

  @override
  State<AudioMessageBubble> createState() => _AudioMessageBubbleState();
}

class _AudioMessageBubbleState extends State<AudioMessageBubble> {
  final audio.AudioPlayer _audioPlayer = audio.AudioPlayer();
  audio.PlayerState _playerState = audio.PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
  }

  Future<void> _initAudioPlayer() async {
    try {
      // Configure audio player
      await _audioPlayer.setReleaseMode(audio.ReleaseMode.stop);
      
      // Set up event listeners
      _audioPlayer.onPlayerStateChanged.listen((audio.PlayerState state) {
        print('Player State Changed: $state');
        setState(() => _playerState = state);
      });

      _audioPlayer.onDurationChanged.listen((Duration d) {
        print('Duration Changed: ${d.inSeconds} seconds');
        setState(() => _duration = d);
      });

      _audioPlayer.onPositionChanged.listen((Duration p) {
        print('Position Changed: ${p.inSeconds} seconds');
        setState(() => _position = p);
      });

      _audioPlayer.onPlayerComplete.listen((_) {
        print('Playback Completed');
        setState(() {
          _position = Duration.zero;
          _playerState = audio.PlayerState.stopped;
        });
      });

      // Pre-load the audio source
      setState(() => _isLoading = true);
      
      print('Setting source URL: ${widget.audioUrl}');
      await _audioPlayer.setSource(audio.UrlSource(widget.audioUrl));
      
      setState(() {
        _isLoading = false;
        _isInitialized = true;
      });
      print('Audio player initialized successfully');
    } catch (e) {
      print('Error initializing audio player: $e');
      setState(() {
        _isLoading = false;
        _isInitialized = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading audio: $e')),
        );
      }
    }
  }

  Future<void> _playPause() async {
    try {
      if (!_isInitialized) {
        print('Player not initialized, reinitializing...');
        await _initAudioPlayer();
        return;
      }

      if (_playerState == audio.PlayerState.playing) {
        print('Pausing playback');
        await _audioPlayer.pause();
      } else {
        print('Starting playback from URL: ${widget.audioUrl}');
        await _audioPlayer.play(audio.UrlSource(widget.audioUrl));
        
        // Set volume to maximum
        await _audioPlayer.setVolume(1.0);
        print('Playback started');
      }
    } catch (e) {
      print('Error during playback: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error playing audio: $e')),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    print('Disposing audio player');
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: widget.isMe ? Colors.lightBlueAccent.withOpacity(0.2) : Colors.grey[200],
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isLoading)
            const SizedBox(
              width: 40,
              height: 40,
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: Icon(
                _playerState == audio.PlayerState.playing
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_filled,
                size: 40,
                color: widget.isMe ? Colors.lightBlueAccent : Colors.grey[700],
              ),
              onPressed: _playPause,
            ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _playerState == audio.PlayerState.playing 
                    ? 'Playing...' 
                    : 'Voice Message',
                style: TextStyle(
                  color: widget.isMe ? Colors.lightBlueAccent : Colors.grey[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                style: TextStyle(
                  color: widget.isMe ? Colors.lightBlueAccent : Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PdfViewerScreen extends StatelessWidget {
  final String pdfUrl;

  const PdfViewerScreen({super.key, required this.pdfUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Viewer'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SfPdfViewer.network(pdfUrl),
    );
  }
}
