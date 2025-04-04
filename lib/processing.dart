import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'extraction.dart';

class TextInputPage extends StatefulWidget {
  const TextInputPage({Key? key}) : super(key: key);

  @override
  State<TextInputPage> createState() => _TextInputPageState();
}

class _TextInputPageState extends State<TextInputPage> {
  final TextEditingController _textController = TextEditingController();
  bool _isTextTooLong = false;
  
  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _checkTextLength(String text) {
    const int maxLength = 100000;
    setState(() {
      _isTextTooLong = text.length > maxLength;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Text to Hide'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your secret message',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'This text will be hidden in the image you select',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _textController,
              maxLines: 8,
              minLines: 4,
              onChanged: _checkTextLength,
              decoration: InputDecoration(
                hintText: 'Type your secret message here...',
                border: const OutlineInputBorder(),
                errorText: _isTextTooLong ? 'Text may be too long for most images' : null,
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Characters: ${_textController.text.length}',
                  style: TextStyle(
                    color: _isTextTooLong ? Colors.red : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.image),
                label: const Text('Select Carrier Image'),
                onPressed: () async {
                  if (_textController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter text to hide'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                  
                  final XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery);
                  if (image != null && context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProcessTextInImagePage(
                          text: _textController.text,
                          carrierUri: image.path,
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Note',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'The carrier image should be large enough to hold your text. '
                      'Each character requires approximately 8 pixels. '
                      'For best results, use PNG format.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProcessTextInImagePage extends StatefulWidget {
  final String text;
  final String carrierUri;

  const ProcessTextInImagePage({
    Key? key,
    required this.text,
    required this.carrierUri,
  }) : super(key: key);

  @override
  State<ProcessTextInImagePage> createState() => _ProcessTextInImagePageState();
}

class _ProcessTextInImagePageState extends State<ProcessTextInImagePage> {
  static const platform = MethodChannel('com.example.stegoapp/UltraFastSteganography');
  bool _isProcessing = true;
  String? _outputPath;
  String? _errorMessage;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _processData();
  }

  Future<void> _processData() async {
    try {
      // Simulate progress updates
      for (int i = 0; i <= 100; i += 10) {
        await Future.delayed(const Duration(milliseconds: 200));
        if (mounted) {
          setState(() {
            _progress = i / 100.0;
          });
        }
      }

      final result = await platform.invokeMethod('hideTextInImage', {
        'text': widget.text,
        'carrierUri': widget.carrierUri,
      });

      final Map<String, dynamic> resultMap = Map<String, dynamic>.from(result);

      if (resultMap['success'] == true) {
        setState(() {
          _isProcessing = false;
          _outputPath = resultMap['path'] as String;
          _progress = 1.0;
        });
      } else {
        setState(() {
          _isProcessing = false;
          _errorMessage = resultMap['error'] as String? ?? 'Unknown error occurred';
        });
      }
    } on PlatformException catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Failed to process: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Unexpected error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Processing'),
      ),
      body: Center(
        child: _isProcessing
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(strokeWidth: 3),
                  const SizedBox(height: 24),
                  Text(
                    'Hiding your text in the image...',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: LinearProgressIndicator(
                      value: _progress,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Progress: ${(_progress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              )
            : _errorMessage != null
                ? ErrorDisplay(
                    errorMessage: _errorMessage!,
                    onRetry: () {
                      setState(() {
                        _isProcessing = true;
                        _errorMessage = null;
                        _progress = 0.0;
                      });
                      _processData();
                    },
                  )
                : ResultPage(outputPath: _outputPath!),
      ),
    );
  }
}

class ProcessImageInImagePage extends StatefulWidget {
  final String secretImageUri;
  final String carrierUri;

  const ProcessImageInImagePage({
    Key? key,
    required this.secretImageUri,
    required this.carrierUri,
  }) : super(key: key);

  @override
  State<ProcessImageInImagePage> createState() => _ProcessImageInImagePageState();
}

class _ProcessImageInImagePageState extends State<ProcessImageInImagePage> {
  static const platform = MethodChannel('com.example.stegoapp/UltraFastSteganography');
  bool _isProcessing = true;
  String? _outputPath;
  String? _errorMessage;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _processData();
  }

  Future<void> _processData() async {
    try {
      // Simulate progress updates
      for (int i = 0; i <= 100; i += 10) {
        await Future.delayed(const Duration(milliseconds: 200));
        if (mounted) {
          setState(() {
            _progress = i / 100.0;
          });
        }
      }

      final result = await platform.invokeMethod('hideImageInImage', {
        'secretImageUri': widget.secretImageUri,
        'carrierUri': widget.carrierUri,
      });

      final Map<String, dynamic> resultMap = Map<String, dynamic>.from(result);

      if (resultMap['success'] == true) {
        setState(() {
          _isProcessing = false;
          _outputPath = resultMap['path'] as String;
          _progress = 1.0;
        });
      } else {
        setState(() {
          _isProcessing = false;
          _errorMessage = resultMap['error'] as String? ?? 'Unknown error occurred';
        });
      }
    } on PlatformException catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Failed to process: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Unexpected error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hiding Image in Image'),
      ),
      body: Center(
        child: _isProcessing
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(strokeWidth: 3),
                  const SizedBox(height: 24),
                  Text(
                    'Hiding your image...',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: LinearProgressIndicator(
                      value: _progress,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Progress: ${(_progress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              )
            : _errorMessage != null
                ? ErrorDisplay(
                    errorMessage: _errorMessage!,
                    onRetry: () {
                      setState(() {
                        _isProcessing = true;
                        _errorMessage = null;
                        _progress = 0.0;
                      });
                      _processData();
                    },
                  )
                : ResultPage(outputPath: _outputPath!),
      ),
    );
  }
}

class ProcessImageInVideoPage extends StatefulWidget {
  final String secretImageUri;
  final String carrierVideoUri;

  const ProcessImageInVideoPage({
    Key? key,
    required this.secretImageUri,
    required this.carrierVideoUri,
  }) : super(key: key);

  @override
  State<ProcessImageInVideoPage> createState() => _ProcessImageInVideoPageState();
}

class _ProcessImageInVideoPageState extends State<ProcessImageInVideoPage> {
  static const platform = MethodChannel('com.example.stegoapp/UltraFastSteganography');
  bool _isProcessing = true;
  String? _outputPath;
  String? _errorMessage;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _processData();
  }

  Future<void> _processData() async {
    try {
      // Simulate progress updates (slower for video processing)
      for (int i = 0; i <= 100; i += 5) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          setState(() {
            _progress = i / 100.0;
          });
        }
      }

      final result = await platform.invokeMethod('hideImageInVideo', {
        'secretImageUri': widget.secretImageUri,
        'carrierVideoUri': widget.carrierVideoUri,
      });

      final Map<String, dynamic> resultMap = Map<String, dynamic>.from(result);

      if (resultMap['success'] == true) {
        setState(() {
          _isProcessing = false;
          _outputPath = resultMap['path'] as String;
          _progress = 1.0;
        });
      } else {
        setState(() {
          _isProcessing = false;
          _errorMessage = resultMap['error'] as String? ?? 'Unknown error occurred';
        });
      }
    } on PlatformException catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Failed to process: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Unexpected error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hiding Image in Video'),
      ),
      body: Center(
        child: _isProcessing
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(strokeWidth: 3),
                  const SizedBox(height: 24),
                  Text(
                    'Hiding your image in video...',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: LinearProgressIndicator(
                      value: _progress,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Progress: ${(_progress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'This may take several minutes depending on video length',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            : _errorMessage != null
                ? ErrorDisplay(
                    errorMessage: _errorMessage!,
                    onRetry: () {
                      setState(() {
                        _isProcessing = true;
                        _errorMessage = null;
                        _progress = 0.0;
                      });
                      _processData();
                    },
                  )
                : VideoResultPage(outputPath: _outputPath!),
      ),
    );
  }
}