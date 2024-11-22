import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:typed_data';

final _firestore = FirebaseFirestore.instance;
firebase_auth.User? loggedInUser;

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

  /// Fetch Firebase Authenticated User
  void getCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      loggedInUser = user;
      print('Logged in as: ${loggedInUser!.email}');
    } else {
      print('No user is currently logged in.');
    }
  }

  /// Request Microphone Permission
  Future<bool> _requestMicrophonePermission() async {
    PermissionStatus status = await Permission.microphone.request();
    return status == PermissionStatus.granted;
  }

  /// Initialize Recorder
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
      await _audioRecorder
          .setSubscriptionDuration(const Duration(milliseconds: 500));
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

  /// Upload File (No Supabase functionality)
  Future<void> uploadFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null) {
        Uint8List fileBytes = result.files.first.bytes!;
        String fileName = result.files.first.name;
        String fileType = result.files.first.extension ?? '';

        // Upload file to Firebase Firestore (without Supabase)
        await _firestore.collection('messages').add({
          'fileName': fileName,
          'fileType': fileType,
          'sender': loggedInUser?.email ?? 'Unknown',
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error uploading file: $e');
    }
  }

  /// Start Recording Audio
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

  /// Stop Recording Audio
  Future<void> stopRecording() async {
    try {
      final audioPath = await _audioRecorder.stopRecorder();
      setState(() {
        isRecording = false;
      });

      if (audioPath != null) {
        File audioFile = File(audioPath);
        Uint8List audioBytes = await audioFile.readAsBytes();
        String audioFileName = '${const Uuid().v4()}.aac';

        // Upload audio to Firebase Firestore (without Supabase)
        await _firestore.collection('messages').add({
          'audioFileName': audioFileName,
          'sender': loggedInUser?.email ?? 'Unknown',
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error stopping recording: $e');
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
                        // Clear the input field
                        messageTextController.clear();

                        // Add the message to Firestore
                        _firestore.collection('messages').add({
                          'text': messageText,
                          'sender': loggedInUser!.email,
                          'timestamp': FieldValue.serverTimestamp(),
                        });

                        setState(() {
                          messageText =
                              ''; // This will clear the message variable
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
      stream:
          _firestore.collection('messages').orderBy('timestamp').snapshots(),
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
    final AudioPlayer audioPlayer = AudioPlayer();

    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            sender,
            style: const TextStyle(color: Colors.black54, fontSize: 12.0),
          ),
          if (fileType == 'jpg' || fileType == 'png')
            Image.network(fileUrl, height: 150, width: 150),
          if (audioUrl.isNotEmpty)
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: () {
                    audioPlayer.play(UrlSource(audioUrl));
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.stop),
                  onPressed: () {
                    audioPlayer.stop();
                  },
                ),
              ],
            ),
          if (text.isNotEmpty)
            Material(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isMe ? 30.0 : 0.0),
                topRight: Radius.circular(isMe ? 0.0 : 30.0),
                bottomLeft: const Radius.circular(30.0),
                bottomRight: const Radius.circular(30.0),
              ),
              color: isMe
                  ? Colors.lightBlueAccent
                  : Colors.white, // This applies the background color
              elevation: 5.0,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 10.0,
                  horizontal: 12.0,
                ),
                child: Text(
                  text,
                  style: TextStyle(
                    color: isMe
                        ? Colors.white
                        : Colors.black, // Text color contrast
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
