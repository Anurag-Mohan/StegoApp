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

class _PinEntryDialogState extends State<PinEntryDialog>
    with SingleTickerProviderStateMixin {
  final String _pin = '';
  final List<bool> _pinFilled = [false, false, false, false];
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _updatePin(String value) {
    if (_error) {
      setState(() {
        _error = false;
        for (int i = 0; i < 4; i++) {
          _pinFilled[i] = false;
        }
      });
    }

    setState(() {
      for (int i = 0; i < 4; i++) {
        if (i < value.length) {
          _pinFilled[i] = true;
        } else {
          _pinFilled[i] = false;
        }
      }
    });


    if (value.isNotEmpty && value.length <= 4) {
      _animationController.reset();
      _animationController.forward();
    }


    if (value.length == 4) {
      Future.delayed(const Duration(milliseconds: 300), () {
        Navigator.pop(context, value);
      });
    }
  }

  void _showError() {
    setState(() {
      _error = true;
    });
    _animationController.reset();
    _animationController.repeat(reverse: true);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _animationController.stop();
        setState(() {
          _error = false;
          for (int i = 0; i < 4; i++) {
            _pinFilled[i] = false;
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        widget.isSetup ? 'Set Up PIN' : 'Enter PIN',
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              return AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  final scale = (_pinFilled[index] && 
                               index == _pinFilled.where((e) => e).length - 1) 
                               ? _scaleAnimation.value : 1.0;
                  return TweenAnimationBuilder<Color?>(
                    tween: ColorTween(
                      begin: _error ? Colors.red : Colors.grey.shade300,
                      end: _pinFilled[index]
                          ? (_error ? Colors.red : Theme.of(context).primaryColor)
                          : Colors.grey.shade300,
                    ),
                    duration: const Duration(milliseconds: 200),
                    builder: (context, color, _) {
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            }),
          ),
          const SizedBox(height: 30),
          TextField(
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 4,
            onChanged: _updatePin,
            decoration: InputDecoration(
              hintText: 'Enter 4-digit PIN',
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              prefixIcon: const Icon(Icons.lock_outline),
              errorText: _error ? 'Invalid PIN' : null,
            ),
          ),
          if (widget.isSetup)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                'Remember this PIN. You will need it to access the app.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: () => _showError(),
              child: const Text('Ok'),
            ),
          ], 
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