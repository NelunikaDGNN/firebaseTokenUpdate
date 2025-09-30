// code_verification_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:my_app/reset.dart';

class CodeVerificationScreen extends StatefulWidget {
  final String email;

  const CodeVerificationScreen({super.key, required this.email});

  @override
  State<CodeVerificationScreen> createState() => _CodeVerificationScreenState();
}

class _CodeVerificationScreenState extends State<CodeVerificationScreen> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  int _resendCooldown = 0;
  bool _canResend = true;
  final FocusNode _emailFocusNode = FocusNode();

  void _unfocusKeyboard() {
    FocusScope.of(context).unfocus();
  }

  Future<void> _verifyCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://192.168.8.159:3000/api/auth/verify-reset-code'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': widget.email,
          'code': _codeController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        // Code verified - navigate to reset password
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => ResetPasswordScreen(
                  email: widget.email,
                  resetToken:
                      json.decode(
                        response.body,
                      )['resetToken'], // Get token from backend
                ),
          ),
        );
      } else {
        final errorData = json.decode(response.body);
        _showSnackBar(
          errorData['message'] ?? 'Invalid verification code',
          isError: true,
        );
      }
    } catch (e) {
      _showSnackBar('Network error: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resendCode() async {
    if (!_canResend) return;

    setState(() {
      _canResend = false;
      _resendCooldown = 60; // 60 seconds cooldown
    });

    // Start countdown
    _startCooldown();

    try {
      final response = await http.post(
        Uri.parse('http://192.168.8.159:3000/api/auth/resend-reset-code'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': widget.email}),
      );

      if (response.statusCode == 200) {
        _showSnackBar('Verification code sent!');
      } else {
        final errorData = json.decode(response.body);
        _showSnackBar(
          errorData['message'] ?? 'Failed to resend code',
          isError: true,
        );
      }
    } catch (e) {
      _showSnackBar('Network error: $e', isError: true);
    }
  }

  void _startCooldown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_resendCooldown > 0) {
        setState(() {
          _resendCooldown--;
        });
        _startCooldown();
      } else {
        setState(() {
          _canResend = true;
        });
      }
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF3C3B6E),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _unfocusKeyboard,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: true,
        // appBar: AppBar(
        //   title: const Text('Enter Verification Code'),
        //   backgroundColor: Colors.deepPurple,
        //   foregroundColor: Colors.white,
        //   leading: IconButton(
        //     icon: const Icon(Icons.arrow_back),
        //     onPressed: () => Navigator.pop(context),
        //   ),
        // ),
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/background.jpeg'),
              fit: BoxFit.cover,
              // colorFilter: ColorFilter.mode(
              //   Colors.black.withOpacity(0.6),
              //   BlendMode.darken,
              // ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    Center(child: Icon(Icons.verified_user, size: 70, color: Colors.white)),
                    const SizedBox(height: 20),
                    Center(
                      child: const Text(
                        'Enter Verification Code',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          // color: Colors.deepPurple,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                        children: [
                          const TextSpan(text: 'We sent a 6-digit code to '),
                          TextSpan(
                            text: widget.email,
                            style: const TextStyle(
                              fontWeight: FontWeight.w400,
                              // color: Colors.deepPurple,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    TextFormField(
                      controller: _codeController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Verification Code',
                        labelStyle: TextStyle(color: Colors.white),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),

                        hintText: 'Enter 6-digit code',

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        prefixIcon: Icon(Icons.code, color: Colors.white),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the verification code';
                        }
                        if (value.length != 6) {
                          return 'Code must be 6 digits';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Didn't receive the code?",
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(width: 5),
                        _canResend
                            ? TextButton(
                              onPressed: () {
                                _resendCode();
                                _unfocusKeyboard();
                              },
                              child: const Text(
                                'Resend Code',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                            : Text(
                              'Resend in $_resendCooldown s',
                              style: const TextStyle(color: Colors.white70),
                            ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    _isLoading
                        ? const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            // onPressed: _verifyCode,
                               onPressed: () {
                                 _verifyCode();
                                _unfocusKeyboard();
                              },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff002D72),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: const Text(
                              'Verify Code',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }
}
