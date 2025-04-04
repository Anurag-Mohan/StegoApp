import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  

  final authEnabled = await AuthSettings.isAuthEnabled();
  
  runApp(SteganographyApp(
    initialRoute: authEnabled ? '/auth' : '/home',
  ));
}

class SteganographyApp extends StatelessWidget {
  final String initialRoute;
  
  const SteganographyApp({
    Key? key,
    required this.initialRoute,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Steganography App',
      debugShowCheckedModeBanner: false,
      initialRoute: initialRoute,
      routes: {
        '/auth': (context) => const AuthGate(),
        '/home': (context) => const HomePage(),
        '/setup': (context) => const AuthSetupScreen(),
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 32, 1, 87),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 2,
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          iconTheme: IconThemeData(
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class AuthSettings {
  static const _keyAuthEnabled = 'auth_enabled';
  static const _keyAuthMethod = 'auth_method';
  static const _keyPin = 'auth_pin';

  static Future<bool> isAuthEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAuthEnabled) ?? false;
  }

  static Future<void> setAuthEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAuthEnabled, enabled);
  }

  static Future<String?> getAuthMethod() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAuthMethod);
  }

  static Future<void> setAuthMethod(String method) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAuthMethod, method);
  }

  static Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPin, pin);
  }

  static Future<String?> getPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPin);
  }
}

class AuthService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> shouldAuthenticate() async {
    return await AuthSettings.isAuthEnabled();
  }

  static Future<bool> authenticate(BuildContext context) async {
    if (!await shouldAuthenticate()) return true;

    final method = await AuthSettings.getAuthMethod();
    
    switch (method) {
      case 'FaceID':
      case 'Fingerprint':
        return _authenticateWithBiometrics();
      case 'PIN':
        return _authenticateWithPin(context);
      default:
        return true;
    }
  }

  static Future<bool> _authenticateWithBiometrics() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Authenticate to access the app',
        options: const AuthenticationOptions(
          biometricOnly: true,
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      print('Biometric auth error: $e');
      return false;
    }
  }

  static Future<bool> _authenticateWithPin(BuildContext context) async {
    final enteredPin = await showDialog<String>(
      context: context,
      builder: (context) => const PinEntryDialog(isSetup: false),
    );
    
    final storedPin = await AuthSettings.getPin();
    return enteredPin == storedPin;
  }
}

class PinEntryDialog extends StatefulWidget {
  final bool isSetup;

  const PinEntryDialog({
    Key? key,
    this.isSetup = false,
  }) : super(key: key);

  @override
  _PinEntryDialogState createState() => _PinEntryDialogState();
}

class _PinEntryDialogState extends State<PinEntryDialog> {
  final TextEditingController _pinController = TextEditingController();
  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _pinController.addListener(_updateButtonState);
  }

  @override
  void dispose() {
    _pinController.removeListener(_updateButtonState);
    _pinController.dispose();
    super.dispose();
  }

  void _updateButtonState() {
    setState(() {
      _isButtonEnabled = _pinController.text.length == 4;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isSetup ? 'Set Up PIN' : 'Enter PIN'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _pinController,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 4,
            decoration: const InputDecoration(
              hintText: 'Enter 4-digit PIN',
              counterText: '',
            ),
            onChanged: (value) {
              
            },
          ),
          if (widget.isSetup)
            const Text(
              'Remember this PIN. You will need it to access the app.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isButtonEnabled
              ? () => Navigator.pop(context, _pinController.text)
              : null,
          child: const Text('OK'),
        ),
      ],
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService.authenticate(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (snapshot.data == true) {
          return const HomePage();
        } else {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock, size: 64, color: Colors.red),
                  const SizedBox(height: 20),
                  const Text('Authentication failed'),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const AuthSetupScreen()),
                    ),
                    child: const Text('Change authentication method'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const HomePage()),
                    ),
                    child: const Text('Continue without authentication'),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}

class AuthSetupScreen extends StatefulWidget {
  const AuthSetupScreen({Key? key}) : super(key: key);

  @override
  _AuthSetupScreenState createState() => _AuthSetupScreenState();
}

class _AuthSetupScreenState extends State<AuthSetupScreen> {
  final LocalAuthentication _auth = LocalAuthentication();
  List<BiometricType> availableBiometrics = [];
  bool _isBiometricAvailable = false;
  String? _selectedMethod;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
    _loadCurrentSettings();
  }

  Future<void> _loadCurrentSettings() async {
    final currentMethod = await AuthSettings.getAuthMethod();
    setState(() {
      _selectedMethod = currentMethod ?? 'None';
    });
  }

  Future<void> _checkBiometrics() async {
    try {
      final bool canAuthenticate = await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
      final List<BiometricType> biometrics = await _auth.getAvailableBiometrics();

      setState(() {
        _isBiometricAvailable = canAuthenticate;
        availableBiometrics = biometrics;
      });
    } catch (e) {
      print('Error checking biometrics: $e');
    }
  }

  Future<void> _setupPin() async {
    final pin = await showDialog<String>(
      context: context,
      builder: (context) => const PinEntryDialog(isSetup: true),
    );
    
    if (pin != null && pin.length == 4) {
      await AuthSettings.setPin(pin);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN set successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Protection'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Protect your app with:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            if (_isBiometricAvailable) ...[
              if (availableBiometrics.contains(BiometricType.face))
                _buildAuthOption(
                  'Face ID',
                  Icons.face,
                  'FaceID',
                ),
              if (availableBiometrics.contains(BiometricType.fingerprint))
                _buildAuthOption(
                  'Fingerprint',
                  Icons.fingerprint,
                  'Fingerprint',
                ),
            ],
            _buildAuthOption(
              'PIN Code',
              Icons.lock,
              'PIN',
              onTap: _selectedMethod == 'PIN' ? _setupPin : null,
            ),
            _buildAuthOption(
              'None',
              Icons.no_encryption,
              'None',
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _selectedMethod == null
                  ? null
                  : () async {
                      await AuthSettings.setAuthEnabled(_selectedMethod != 'None');
                      if (_selectedMethod != 'None') {
                        await AuthSettings.setAuthMethod(_selectedMethod!);
                        if (_selectedMethod == 'PIN') {
                          await _setupPin();
                        }
                      }
                      Navigator.of(context).pop();
                    },
              child: const Text('Save Settings'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthOption(String title, IconData icon, String method, {VoidCallback? onTap}) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: _selectedMethod == method
            ? const Icon(Icons.check_circle, color: Colors.green)
            : null,
        onTap: () {
          setState(() => _selectedMethod = method);
          if (onTap != null) onTap();
        },
      ),
    );
  }
}


class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Steganography App'),
        actions: [
          IconButton(
  icon: const Icon(Icons.security),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AuthSetupScreen()),
    );
  },
),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showAboutDialog(
                context: context,
                applicationName: 'Steganography App',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2023 Steganography App',
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'Hide and extract secret messages in images and videos using advanced steganography techniques.',
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'Steganography Operations',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Choose an operation to begin',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 1.0,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  OperationCard(
                    icon: Icons.lock,
                    title: 'Hide Text',
                    subtitle: 'Text in an image',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TextInputPage(),
                        ),
                      );
                    },
                  ),
                  OperationCard(
                    icon: Icons.lock_open,
                    title: 'Extract Text',
                    subtitle: 'Text from image',
                    color: Colors.green,
                    onTap: () async {
                      final XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery);
                      if (image != null && context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ExtractTextPage(
                              carrierUri: image.path,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  OperationCard(
                    icon: Icons.image,
                    title: 'Hide Image',
                    subtitle: 'Image in Image',
                    color: Colors.orange,
                    onTap: () async {
                      final XFile? secretImage = await ImagePicker().pickImage(source: ImageSource.gallery);
                      if (secretImage != null && context.mounted) {
                        final XFile? carrierImage = await ImagePicker().pickImage(source: ImageSource.gallery);
                        if (carrierImage != null && context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProcessImageInImagePage(
                                secretImageUri: secretImage.path,
                                carrierUri: carrierImage.path,
                              ),
                            ),
                          );
                        }
                      }
                    },
                  ),
                  OperationCard(
                    icon: Icons.image_search,
                    title: 'Extract Image',
                    subtitle: 'image from image',
                    color: Colors.purple,
                    onTap: () async {
                      final XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery);
                      if (image != null && context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ExtractImageFromImagePage(
                              carrierUri: image.path,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  OperationCard(
                    icon: Icons.video_library,
                    title: 'Hide in Video',
                    subtitle: 'Image in video',
                    color: Colors.red,
                    onTap: () async {
                      final XFile? secretImage = await ImagePicker().pickImage(source: ImageSource.gallery);
                      if (secretImage != null && context.mounted) {
                        final XFile? carrierVideo = await ImagePicker().pickVideo(source: ImageSource.gallery);
                        if (carrierVideo != null && context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProcessImageInVideoPage(
                                secretImageUri: secretImage.path,
                                carrierVideoUri: carrierVideo.path,
                              ),
                            ),
                          );
                        }
                      }
                    },
                  ),
                  OperationCard(
                    icon: Icons.video_settings,
                    title: 'Extract  Video',
                    subtitle: 'Image from video',
                    color: Colors.teal,
                    onTap: () async {
                      final XFile? video = await ImagePicker().pickVideo(source: ImageSource.gallery);
                      if (video != null && context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ExtractImageFromVideoPage(
                              carrierVideoUri: video.path,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class OperationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const OperationCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis, 
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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

  @override
  void initState() {
    super.initState();
    _processData();
  }

  Future<void> _processData() async {
    try {
      final result = await platform.invokeMethod('hideTextInImage', {
        'text': widget.text,
        'carrierUri': widget.carrierUri,
      });

      final Map<String, dynamic> resultMap = Map<String, dynamic>.from(result);

      if (resultMap['success'] == true) {
        setState(() {
          _isProcessing = false;
          _outputPath = resultMap['path'] as String;
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
                  const Text(
                    'This may take a few moments',
                    style: TextStyle(color: Colors.grey),
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
                      });
                      _processData();
                    },
                  )
                : ResultPage(outputPath: _outputPath!),
      ),
    );
  }
}

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

  @override
  void initState() {
    super.initState();
    _extractData();
  }

  Future<void> _extractData() async {
    try {
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
                  const Text(
                    'This may take a few moments',
                    style: TextStyle(color: Colors.grey),
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
                      });
                      _extractData();
                    },
                  )
                : ExtractResultPage(extractedText: _extractedText!),
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

  @override
  void initState() {
    super.initState();
    _processData();
  }

  Future<void> _processData() async {
    try {
      final result = await platform.invokeMethod('hideImageInImage', {
        'secretImageUri': widget.secretImageUri,
        'carrierUri': widget.carrierUri,
      });

      final Map<String, dynamic> resultMap = Map<String, dynamic>.from(result);

      if (resultMap['success'] == true) {
        setState(() {
          _isProcessing = false;
          _outputPath = resultMap['path'] as String;
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
                  const Text(
                    'This may take a few moments',
                    style: TextStyle(color: Colors.grey),
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
                      });
                      _processData();
                    },
                  )
                : ResultPage(outputPath: _outputPath!),
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

  @override
  void initState() {
    super.initState();
    _extractData();
  }

  Future<void> _extractData() async {
    try {
      final result = await platform.invokeMethod('extractImageFromImage', {
        'carrierUri': widget.carrierUri,
      });

      final Map<String, dynamic> resultMap = Map<String, dynamic>.from(result);

      if (resultMap['success'] == true) {
        setState(() {
          _isProcessing = false;
          _outputPath = resultMap['path'] as String;
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
                  const Text(
                    'This may take a few moments',
                    style: TextStyle(color: Colors.grey),
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
                      });
                      _extractData();
                    },
                  )
                : ImageResultPage(outputPath: _outputPath!),
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

  @override
  void initState() {
    super.initState();
    _processData();
  }

  Future<void> _processData() async {
    try {
      final result = await platform.invokeMethod('hideImageInVideo', {
        'secretImageUri': widget.secretImageUri,
        'carrierVideoUri': widget.carrierVideoUri,
      });

      final Map<String, dynamic> resultMap = Map<String, dynamic>.from(result);

      if (resultMap['success'] == true) {
        setState(() {
          _isProcessing = false;
          _outputPath = resultMap['path'] as String;
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
                      });
                      _processData();
                    },
                  )
                : VideoResultPage(outputPath: _outputPath!),
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

  @override
  void initState() {
    super.initState();
    _extractData();
  }

  Future<void> _extractData() async {
    try {
      final result = await platform.invokeMethod('extractImageFromVideo', {
        'carrierVideoUri': widget.carrierVideoUri,
      });

      final Map<String, dynamic> resultMap = Map<String, dynamic>.from(result);

      if (resultMap['success'] == true) {
        setState(() {
          _isProcessing = false;
          _outputPath = resultMap['path'] as String;
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