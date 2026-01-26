import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'star_field.dart';
import '../main.dart'; // for serverUrl and MainScreen

const storage = FlutterSecureStorage();

const Map<String, String> _displayNames = {
  'home': 'Preston & Willoh',
  'pattie': 'Pattie',
  'melanie': 'Rob & Melanie',
  'robbins': 'Arwyn & Bella',
  'brufam': 'Douglas & Shari',
};

class UserSelectorScreen extends StatefulWidget {
  const UserSelectorScreen({super.key});

  @override
  State<UserSelectorScreen> createState() => _UserSelectorScreenState();
}

class _UserSelectorScreenState extends State<UserSelectorScreen> {
  String? _selectedUser;
  String _enteredPin = '';
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasSubmitted = false; // Only true after failed attempt

  final List<String> _availableUsers = [
    'pattie',
    'melanie',
    'robbins',
    'home',
    'brufam',
  ];

  @override
  void initState() {
    super.initState();
    _checkSavedUser();
  }

  String _getDisplayName(String rawUser) {
    return _displayNames[rawUser] ??
        (rawUser.isNotEmpty
            ? rawUser[0].toUpperCase() + rawUser.substring(1)
            : rawUser);
  }

  Future<void> _checkSavedUser() async {
    final savedUser = await storage.read(key: 'selected_screen');
    if (savedUser != null && _availableUsers.contains(savedUser)) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    }
  }

  Future<void> _tryConnect() async {
    if (_selectedUser == null || _enteredPin.isEmpty) {
      setState(() {
        _errorMessage = 'Select a screen and enter PIN';
        _hasSubmitted = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasSubmitted = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$serverUrl/auth/$_selectedUser'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'pin': _enteredPin}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String token = (data['token'] as String?)?.trim() ?? '';

        token = token.replaceAll('"', '');

        await storage.write(key: 'auth_token', value: token);
        await storage.write(key: 'selected_screen', value: _selectedUser);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainScreen()),
          );
        }
      } else {
        setState(() => _errorMessage = 'Wrong PIN — try again');
      }
    } catch (e) {
      print('Login error: $e');
      setState(() => _errorMessage = 'Connection issue — check network');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasError = _errorMessage != null && _hasSubmitted;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const StarField(opacity: 0.35),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Choose Your Screen',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(height: 40),
                    DropdownButton<String>(
                      value: _selectedUser,
                      hint: const Text('Select screen'),
                      isExpanded: true,
                      underline: Container(
                        height: 2,
                        color: const Color(0xFF05ADED),
                      ),
                      items: _availableUsers.map((user) {
                        final display = _getDisplayName(user);
                        return DropdownMenuItem(
                          value: user,
                          child: Text(display),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => _selectedUser = value),
                    ),
                    const SizedBox(height: 48),
                    Text(
                      _selectedUser != null
                          ? 'Enter PIN for ${_getDisplayName(_selectedUser!)}'
                          : 'Enter PIN',
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 16),
                    PinCodeTextField(
                      length: 4,
                      obscureText: true,
                      animationType: AnimationType.scale,
                      pinTheme: PinTheme(
                        shape: PinCodeFieldShape.box,
                        borderRadius: BorderRadius.circular(8),
                        fieldHeight: 60,
                        fieldWidth: 60,

                        // Borders (as before, red only on real error)
                        activeColor: hasError
                            ? Colors.redAccent
                            : const Color(0xFF05ADED).withOpacity(0.8),
                        inactiveColor: hasError
                            ? Colors.redAccent.withOpacity(0.5)
                            : Colors.white.withOpacity(0.35),
                        selectedColor: hasError
                            ? Colors.redAccent
                            : const Color(0xFF9F00E7).withOpacity(0.9),
                        errorBorderColor: Colors.redAccent,
                        borderWidth: 2,

                        // ── New: Explicit fill/background colors ──
                        // Neutral dark-transparent fill by default
                        activeFillColor: hasError
                            ? Colors.redAccent.withOpacity(
                                0.15,
                              ) // light red tint on error
                            : Colors.black.withOpacity(
                                0.25,
                              ), // subtle dark fill (matches dark theme)

                        inactiveFillColor: hasError
                            ? Colors.redAccent.withOpacity(0.10)
                            : Colors.black.withOpacity(
                                0.15,
                              ), // very subtle when empty/unfocused

                        selectedFillColor: hasError
                            ? Colors.redAccent.withOpacity(0.20)
                            : const Color(0xFF05ADED).withOpacity(
                                0.12,
                              ), // gentle cyan tint when typing
                        // Ensures fill is used
                      ),
                      cursorColor: const Color(0xFF05ADED),
                      animationDuration: const Duration(milliseconds: 300),
                      backgroundColor: Colors.transparent,
                      enableActiveFill: true,
                      onChanged: (value) {
                        setState(() {
                          _enteredPin = value;
                          if (_hasSubmitted && _errorMessage != null) {
                            _hasSubmitted =
                                false; // Reset error visuals when user corrects
                          }
                        });
                      },
                      appContext: context,
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ],
                    const SizedBox(height: 48),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _tryConnect,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 16,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Connect',
                                style: TextStyle(fontSize: 20),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
