import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class ExtractTextPage extends StatefulWidget {
  final String carrierUri;

  const ExtractTextPage({
    Key? key,
    required this.carrierUri,
  }) : super(key: key);

  @override
  State<ExtractTextPage> createState() => _ExtractTextPageState();
}

class _ExtractTextPageState extends State<ExtractTextPage> {
  static const platform = MethodChannel('com.example.stegoapp/UltraFastSteganography');
  bool _isProcessing = true;
  String? _extractedText;
  String? _errorMessage;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _extractData();
  }

  Future<void> _extractData() async {
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

      final result = await platform.invokeMethod('extractTextFromImage', {
        'carrierUri': widget.carrierUri,
      });

      if (result == null) {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'No hidden data found in this image';
        });
        return;
      }

      final Map<String, dynamic> convertedResult = Map<String, dynamic>.from(result);

      if (convertedResult['success'] == true) {
        setState(() {
          _isProcessing = false;
          _extractedText = convertedResult['text']?.toString() ?? '';
          _progress = 1.0;
        });
      } else {
        String errorMsg = convertedResult['error']?.toString() ?? '';
        if (errorMsg.contains("Invalid data length") || errorMsg.contains("This may not be a stego image")) {
          errorMsg = 'This image doesn\'t appear to contain any hidden data';
        }
        
        setState(() {
          _isProcessing = false;
          _errorMessage = errorMsg;
        });
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'This image doesn\'t appear to contain any hidden data';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Extracting Text'),
      ),
      body: Center(
        child: _isProcessing
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(strokeWidth: 3),
                  const SizedBox(height: 24),
                  Text(
                    'Extracting hidden text...',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: LinearProgressIndicator(
                      value: _progress,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
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
                      _extractData();
                    },
                  )
                : ExtractResultPage(extractedText: _extractedText!),
      ),
    );
  }
}

class ExtractImageFromImagePage extends StatefulWidget {
  final String carrierUri;

  const ExtractImageFromImagePage({
    Key? key,
    required this.carrierUri,
  }) : super(key: key);

  @override
  State<ExtractImageFromImagePage> createState() => _ExtractImageFromImagePageState();
}

class _ExtractImageFromImagePageState extends State<ExtractImageFromImagePage> {
  static const platform = MethodChannel('com.example.stegoapp/UltraFastSteganography');
  bool _isProcessing = true;
  String? _outputPath;
  String? _errorMessage;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _extractData();
  }

  Future<void> _extractData() async {
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

      final result = await platform.invokeMethod('extractImageFromImage', {
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
          _errorMessage = resultMap['error'] as String? ?? 'No hidden image found';
        });
      }
    } on PlatformException catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Failed to extract: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'This image doesn\'t contain hidden data';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Extracting Image'),
      ),
      body: Center(
        child: _isProcessing
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(strokeWidth: 3),
                  const SizedBox(height: 24),
                  Text(
                    'Extracting hidden image...',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: LinearProgressIndicator(
                      value: _progress,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
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
                      _extractData();
                    },
                  )
                : ImageResultPage(outputPath: _outputPath!),
      ),
    );
  }
}

class ExtractImageFromVideoPage extends StatefulWidget {
  final String carrierVideoUri;

  const ExtractImageFromVideoPage({
    Key? key,
    required this.carrierVideoUri,
  }) : super(key: key);

  @override
  State<ExtractImageFromVideoPage> createState() => _ExtractImageFromVideoPageState();
}

class _ExtractImageFromVideoPageState extends State<ExtractImageFromVideoPage> {
  static const platform = MethodChannel('com.example.stegoapp/UltraFastSteganography');
  bool _isProcessing = true;
  String? _outputPath;
  String? _errorMessage;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _extractData();
  }

  Future<void> _extractData() async {
    try {
      // Simulate progress updates (slower for video)
      for (int i = 0; i <= 100; i += 5) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          setState(() {
            _progress = i / 100.0;
          });
        }
      }

      final result = await platform.invokeMethod('extractImageFromVideo', {
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
          _errorMessage = resultMap['error'] as String? ?? 'No hidden image found';
        });
      }
    } on PlatformException catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Failed to extract: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'This video doesn\'t contain hidden data';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Extracting Image from Video'),
      ),
      body: Center(
        child: _isProcessing
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(strokeWidth: 3),
                  const SizedBox(height: 24),
                  Text(
                    'Extracting hidden image...',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: LinearProgressIndicator(
                      value: _progress,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
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
                      _extractData();
                    },
                  )
                : ImageResultPage(outputPath: _outputPath!),
      ),
    );
  }
}

class ErrorDisplay extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;

  const ErrorDisplay({
    Key? key,
    required this.errorMessage,
    required this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.shade400,
            size: 64,
          ),
          const SizedBox(height: 24),
          Text(
            'Error Occurred',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.red.shade400,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            errorMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Go Back'),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ResultPage extends StatelessWidget {
  final String outputPath;

  const ResultPage({Key? key, required this.outputPath}) : super(key: key);

  Future<void> _saveImage(BuildContext context) async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final sdkInt = androidInfo.version.sdkInt;

        if (sdkInt < 30) {
          var status = await Permission.storage.request();
          if (!status.isGranted) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Storage permission denied'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            return;
          }
        }
      }

      Directory saveDir = Directory('/storage/emulated/0/Pictures/MyAppImages');
      if (!await saveDir.exists()) {
        await saveDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'stego_image_$timestamp.png';
      final savedPath = path.join(saveDir.path, fileName);

      final savedFile = await File(outputPath).copy(savedPath);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image saved to $fileName'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save image: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 64,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Success!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your data has been successfully hidden in the image.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 32),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(outputPath),
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.share, size: 20),
                label: const Text('Share'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade50,
                  foregroundColor: Colors.blue,
                ),
                onPressed: () {
                  Share.shareXFiles([XFile(outputPath)]);
                },
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.save_alt, size: 20),
                label: const Text('Save'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade50,
                  foregroundColor: Colors.green,
                ),
                onPressed: () => _saveImage(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('Back to Home'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class ImageResultPage extends StatelessWidget {
  final String outputPath;

  const ImageResultPage({Key? key, required this.outputPath}) : super(key: key);

  Future<void> _saveImage(BuildContext context) async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final sdkInt = androidInfo.version.sdkInt;

        if (sdkInt < 30) {
          var status = await Permission.storage.request();
          if (!status.isGranted) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Storage permission denied'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            return;
          }
        }
      }

      Directory saveDir = Directory('/storage/emulated/0/Pictures/MyAppImages');
      if (!await saveDir.exists()) {
        await saveDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'extracted_image_$timestamp.png';
      final savedPath = path.join(saveDir.path, fileName);

      final savedFile = await File(outputPath).copy(savedPath);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image saved to $fileName'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save image: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 64,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Image Extracted!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
          ),
          const SizedBox(height: 8),
          const Text(
            'The hidden image has been successfully extracted.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 32),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(outputPath),
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.share, size: 20),
                label: const Text('Share'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade50,
                  foregroundColor: Colors.blue,
                ),
                onPressed: () {
                  Share.shareXFiles([XFile(outputPath)]);
                },
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.save_alt, size: 20),
                label: const Text('Save'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade50,
                  foregroundColor: Colors.green,
                ),
                onPressed: () => _saveImage(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('Back to Home'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class VideoResultPage extends StatelessWidget {
  final String outputPath;

  const VideoResultPage({Key? key, required this.outputPath}) : super(key: key);

  Future<void> _saveVideo(BuildContext context) async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final sdkInt = androidInfo.version.sdkInt;

        if (sdkInt < 30) {
          var status = await Permission.storage.request();
          if (!status.isGranted) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Storage permission denied'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            return;
          }
        }
      }

      Directory saveDir = Directory('/storage/emulated/0/Movies/MyAppVideos');
      if (!await saveDir.exists()) {
        await saveDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'stego_video_$timestamp.mp4';
      final savedPath = path.join(saveDir.path, fileName);

      final savedFile = await File(outputPath).copy(savedPath);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Video saved to $fileName'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save video: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 64,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Success!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your image has been successfully hidden in the video.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 32),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                color: Colors.black,
                height: 200,
                child: const Center(
                  child: Icon(
                    Icons.play_circle_filled,
                    color: Colors.white,
                    size: 64,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.share, size: 20),
                label: const Text('Share'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade50,
                  foregroundColor: Colors.blue,
                ),
                onPressed: () {
                  Share.shareXFiles([XFile(outputPath)]);
                },
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.save_alt, size: 20),
                label: const Text('Save'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade50,
                  foregroundColor: Colors.green,
                ),
                onPressed: () => _saveVideo(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('Back to Home'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class ExtractResultPage extends StatelessWidget {
  final String extractedText;

  const ExtractResultPage({Key? key, required this.extractedText}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_open,
              color: Colors.green,
              size: 64,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Text Extracted!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
          ),
          const SizedBox(height: 8),
          const Text(
            'The hidden text has been successfully extracted.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 32),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.text_snippet, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Extracted Text',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      extractedText,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.content_copy, size: 20),
                label: const Text('Copy'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade50,
                  foregroundColor: Colors.blue,
                ),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: extractedText));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Text copied to clipboard'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.share, size: 20),
                label: const Text('Share'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade50,
                  foregroundColor: Colors.green,
                ),
                onPressed: () {
                  Share.share(extractedText);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('Back to Home'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}