import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../main.dart'; // serverUrl

const storage = FlutterSecureStorage();

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

  final List<String> _availableUsers = ['pattie', 'melanie', 'robbins', 'home'];

  @override
  void initState() {
    super.initState();
    _checkSavedUser();
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
      setState(() => _errorMessage = 'Select a screen and enter PIN');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$serverUrl/auth/$_selectedUser'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'pin': _enteredPin}),
      );

      print('DEBUG [login] Auth response status: ${response.statusCode}');
      print('DEBUG [login] Auth response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String token = data['token']?.toString() ?? '';

        print('DEBUG [login] Received raw token (length ${token.length}):');
        print(
          '  → starts with: ${token.substring(0, token.length > 30 ? 30 : token.length)}',
        );

        // Clean before saving
        token = token.trim();
        token = token.replaceAll('"', '');

        await storage.write(key: 'auth_token', value: token);
        await storage.write(key: 'selected_screen', value: _selectedUser);

        print('DEBUG [login] Token saved (cleaned, length ${token.length})');

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
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Choose Your Screen',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w300),
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
                  items: _availableUsers
                      .map(
                        (user) => DropdownMenuItem(
                          value: user,
                          child: Text(user.toUpperCase()),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _selectedUser = value),
                ),
                const SizedBox(height: 48),
                const Text('Enter PIN', style: TextStyle(fontSize: 20)),
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
                    activeColor: const Color(0xFF05ADED),
                    inactiveColor: Colors.white30,
                    selectedColor: const Color(0xFF9F00E7),
                  ),
                  cursorColor: const Color(0xFF05ADED),
                  animationDuration: const Duration(milliseconds: 300),
                  backgroundColor: Colors.transparent,
                  enableActiveFill: true,
                  onChanged: (value) => _enteredPin = value,
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
                            child: CircularProgressIndicator(strokeWidth: 3),
                          )
                        : const Text('Connect', style: TextStyle(fontSize: 20)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
