import 'dart:convert';
import 'package:flutter/material.dart';
import 'register_screen.dart';
import 'home_screen.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Simple debug helper inline
class DebugHelper {
  static void analyzeResponse(Map<String, dynamic> data) {
    print("=== SERVER RESPONSE ANALYSIS ===");
    print("Full response: $data");
    print("Response keys: ${data.keys.toList()}");
    
    // Check for user data in common locations
    if (data['user'] != null) print("Found 'user': ${data['user']}");
    if (data['data'] != null) print("Found 'data': ${data['data']}");
    if (data['userData'] != null) print("Found 'userData': ${data['userData']}");
    
    // Check direct user fields
    if (data['id'] != null) print("Found direct 'id': ${data['id']}");
    if (data['email'] != null) print("Found direct 'email': ${data['email']}");
    if (data['name'] != null) print("Found direct 'name': ${data['name']}");
    print("=== END ANALYSIS ===");
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); // Add form key for validation

  bool _isLoading = false;
  String? _error;
  bool _passwordVisible = false;

  // Test server connection
  Future<void> _testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('https://ecowaste-1013759214686.us-central1.run.app/api/test'),
        headers: {"Content-Type": "application/json"},
      ).timeout(Duration(seconds: 5));
      
      print("Server test response: ${response.statusCode} - ${response.body}");
    } catch (e) {
      print("Server connection test failed: $e");
    }
  }

  // Save session to SharedPreferences
  Future<void> _saveSession(int id, String email, String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('id', id);
      await prefs.setString('email', email);
      await prefs.setString('name', name);
      print("Session saved: ID=$id, Email=$email, Name=$name");
    } catch (e) {
      print("Error saving session: $e");
    }
  }

  // Login method with improved error handling
  Future<void> _login() async {
    // Validate form first
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final url = 'https://ecowaste-1013759214686.us-central1.run.app/api/login';

    try {
      print("Attempting login with email: ${_emailController.text.trim()}");
      
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": _emailController.text.trim(),
          "password": _passwordController.text,
        }),
      );

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Parsed response: $data");
        
        // Analyze response structure for debugging
        DebugHelper.analyzeResponse(data);

        if (data['success'] == true) {
          print("Login successful, checking user data...");
          
          // Handle different possible response structures
          Map<String, dynamic>? user;
          
          if (data['user'] != null) {
            user = data['user'];
          } else if (data['data'] != null) {
            user = data['data'];
          } else {
            // Maybe user data is directly in the response
            if (data['id'] != null || data['email'] != null || data['name'] != null) {
              user = data;
            }
          }
          
          print("User data found: $user");
          
          if (user != null) {
            // Extract user information with fallbacks
            final userId = user['id'] ?? user['user_id'] ?? 0;
            final userEmail = user['email'] ?? _emailController.text.trim();
            final userName = user['name'] ?? user['username'] ?? user['full_name'] ?? 'User';
            
            print("Extracted data - ID: $userId, Email: $userEmail, Name: $userName");
            
            if (userEmail.isNotEmpty && userName.isNotEmpty) {
              // Save session data locally
              await _saveSession(userId, userEmail, userName);
              
              print("Navigating to HomeScreen...");
              
              // Navigate to HomeScreen with proper error handling
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomeScreen(
                      name: userName, 
                      email: userEmail
                    ),
                  ),
                );
              }
            } else {
              setState(() {
                _error = 'Incomplete user data: Email or name is missing';
              });
            }
          } else {
            setState(() {
              _error = 'No user data found in server response';
            });
          }
        } else {
          setState(() {
            _error = data['message'] ?? data['error'] ?? 'Login failed - Invalid credentials';
          });
        }
      } else {
        setState(() {
          _error = 'Server error: ${response.statusCode}';
        });
      }
    } catch (e) {
      print("Login error: $e");
      setState(() {
        _error = "Connection error: Please check your internet connection";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Input validation
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeGreen = const Color(0xFF4CAF50);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: themeGreen,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.eco, size: 80, color: themeGreen),
              const SizedBox(height: 20),
              Text(
                'Login to EcoWaste',
                style: TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.bold, 
                  color: themeGreen
                ),
              ),
              const SizedBox(height: 30),
              Form(
                key: _formKey, // Add form key
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      validator: _validateEmail,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: Icon(Icons.email, color: themeGreen),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.red),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      validator: _validatePassword,
                      obscureText: !_passwordVisible,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: Icon(Icons.lock, color: themeGreen),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.red),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _passwordVisible ? Icons.visibility_off : Icons.visibility,
                            color: themeGreen,
                          ),
                          onPressed: () {
                            setState(() {
                              _passwordVisible = !_passwordVisible;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeGreen,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: themeGreen.withOpacity(0.6),
                      ),
                      child: _isLoading
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Logging in...', style: TextStyle(fontSize: 16)),
                              ],
                            )
                          : const Text('Login', style: TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(height: 12),
                    
                    // Debug button (remove in production)
                    if (true) // Set to false in production
                      TextButton(
                        onPressed: _testConnection,
                        child: Text(
                          'Test Server Connection',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ),
                    
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: _isLoading ? null : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const RegisterScreen()),
                        );
                      },
                      child: Text(
                        'Don\'t have an account? Register here',
                        style: TextStyle(
                          color: _isLoading ? Colors.grey : themeGreen,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red, width: 1),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                  color: Colors.red, 
                                  fontWeight: FontWeight.w500
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}