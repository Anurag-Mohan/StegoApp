import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home.dart';

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
            onChanged: (value) {},
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