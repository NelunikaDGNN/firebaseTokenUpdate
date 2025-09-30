// // // 

// // import 'package:flutter/material.dart';
// // import 'package:firebase_auth/firebase_auth.dart';
// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:firebase_messaging/firebase_messaging.dart';
// // import 'package:my_app/home_screen.dart';

// // class LoginScreen extends StatefulWidget {
// //   const LoginScreen({super.key});

// //   @override
// //   State<LoginScreen> createState() => _LoginScreenState();
// // }

// // class _LoginScreenState extends State<LoginScreen> {
// //   final _formKey = GlobalKey<FormState>();
// //   final _emailController = TextEditingController();
// //   final _passwordController = TextEditingController();
// //   final _auth = FirebaseAuth.instance;
// //   final _firestore = FirebaseFirestore.instance;
// //   final _firebaseMessaging = FirebaseMessaging.instance;
// //   bool _isLoading = false;
// //   bool _isLogin = true;
// //   bool _obscurePassword = true;

// //   Future<void> _submit() async {
// //     if (!_formKey.currentState!.validate()) return;

// //     setState(() {
// //       _isLoading = true;
// //     });

// //     try {
// //       if (_isLogin) {
// //         // Login existing user - FCM token is OPTIONAL
// //         UserCredential userCredential = await _auth.signInWithEmailAndPassword(
// //           email: _emailController.text.trim(),
// //           password: _passwordController.text.trim(),
// //         );

// //         // Update user data in Firestore (FCM token is optional - preserve existing settings)
// //         await _updateUserOnLogin(userCredential.user!);
        
// //         _showSnackBar('Login successful!');
// //         _navigateToHome();
// //       } else {
// //         // Register new user - FCM token is UPDATED
// //         UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
// //           email: _emailController.text.trim(),
// //           password: _passwordController.text.trim(),
// //         );

// //         // Send email verification
// //         await userCredential.user!.sendEmailVerification();

// //         // Save user data to Firestore with FCM token (enabled by default for new users)
// //         await _saveUserOnRegister(userCredential.user!);
        
// //         _showSnackBar('Account created successfully! Please check your email for verification.');
// //         _clearForm();
// //         setState(() {
// //           _isLogin = true;
// //         });
// //       }
// //     } on FirebaseAuthException catch (e) {
// //       _handleAuthError(e);
// //     } catch (e) {
// //       _showSnackBar('An error occurred: $e', isError: true);
// //     } finally {
// //       setState(() {
// //         _isLoading = false;
// //       });
// //     }
// //   }

// //   void _navigateToHome() {
// //     Navigator.pushReplacement(
// //       context,
// //       MaterialPageRoute(builder: (context) => const HomeScreen()),
// //     );
// //   }

// //   void _clearForm() {
// //     _emailController.clear();
// //     _passwordController.clear();
// //   }

// //   Future<String?> _getFCMToken() async {
// //     try {
// //       await _firebaseMessaging.requestPermission(
// //         alert: true,
// //         badge: true,
// //         sound: true,
// //       );

// //       String? token = await _firebaseMessaging.getToken();
// //       print('📱 FCM Token available: ${token != null}');
// //       return token;
// //     } catch (e) {
// //       print('❌ Error getting FCM token: $e');
// //       return null;
// //     }
// //   }

// //   // For REGISTRATION - always update FCM token (enabled by default)
// //   Future<void> _saveUserOnRegister(User user) async {
// //     try {
// //       String? fcmToken = await _getFCMToken();
      
// //       await _firestore.collection('users').doc(user.uid).set({
// //         'uid': user.uid,
// //         'email': user.email,
// //         'displayName': user.displayName ?? '',
// //         'photoURL': user.photoURL ?? '',
// //         'fcmToken': fcmToken, // Set token for new users
// //         'notificationsEnabled': true, // Enable by default for new users
// //         'createdAt': FieldValue.serverTimestamp(),
// //         'updatedAt': FieldValue.serverTimestamp(),
// //         'lastLoginAt': FieldValue.serverTimestamp(),
// //         'isEmailVerified': user.emailVerified,
// //         'accountType': 'user',
// //         'status': 'active',
// //       }, SetOptions(merge: true));
      
// //       print('✅ New user registered with UID: ${user.uid}');
// //       print('🔔 Notifications: ENABLED (default for new users)');
// //       print('📱 FCM Token: ${fcmToken != null ? "SET" : "NOT SET"}');
// //     } catch (e) {
// //       print('❌ Error saving new user: $e');
// //     }
// //   }

// //   // For LOGIN - FCM token is OPTIONAL, preserve existing settings
// //   Future<void> _updateUserOnLogin(User user) async {
// //     try {
// //       // Get current user data to check notification settings
// //       DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      
// //       bool notificationsEnabled = true;
// //       String? existingFcmToken;
      
// //       if (userDoc.exists) {
// //         // Preserve existing notification settings
// //         notificationsEnabled = userDoc['notificationsEnabled'] ?? true;
// //         existingFcmToken = userDoc['fcmToken'];
// //         print('🔔 Existing notification setting: ${notificationsEnabled ? "ENABLED" : "DISABLED"}');
// //       }
      
// //       // Prepare basic update data
// //       Map<String, dynamic> updateData = {
// //         'lastLoginAt': FieldValue.serverTimestamp(),
// //         'updatedAt': FieldValue.serverTimestamp(),
// //         'isEmailVerified': user.emailVerified,
// //         'notificationsEnabled': notificationsEnabled, // Preserve existing setting
// //       };
      
// //       // Only update FCM token if notifications are enabled
// //       if (notificationsEnabled) {
// //         String? newFcmToken = await _getFCMToken();
// //         if (newFcmToken != null) {
// //           updateData['fcmToken'] = newFcmToken;
// //           print('📱 FCM Token updated on login: $newFcmToken');
// //         }
// //       } else {
// //         // Notifications disabled - ensure no FCM token
// //         updateData['fcmToken'] = FieldValue.delete();
// //         print('📱 FCM Token removed (notifications disabled)');
// //       }
      
// //       // Update user document
// //       await _firestore.collection('users').doc(user.uid).set(updateData, SetOptions(merge: true));
      
// //       print('✅ User updated on login: ${user.uid}');
// //       print('🔔 Final notification setting: ${notificationsEnabled ? "ENABLED" : "DISABLED"}');
      
// //     } catch (e) {
// //       print('❌ Error updating user on login: $e');
// //       // If document doesn't exist, create it (shouldn't happen for login)
// //       if (e.toString().contains('No document to update')) {
// //         await _saveUserOnRegister(user);
// //       }
// //     }
// //   }

// //   void _handleAuthError(FirebaseAuthException e) {
// //     String message = 'An error occurred';
// //     if (e.code == 'user-not-found') {
// //       message = 'No user found with this email';
// //     } else if (e.code == 'wrong-password') {
// //       message = 'Wrong password provided';
// //     } else if (e.code == 'email-already-in-use') {
// //       message = 'Email already in use';
// //     } else if (e.code == 'weak-password') {
// //       message = 'Password is too weak';
// //     } else if (e.code == 'invalid-email') {
// //       message = 'Invalid email address';
// //     }
// //     _showSnackBar(message, isError: true);
// //   }

// //   void _showSnackBar(String message, {bool isError = false}) {
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(
// //         content: Text(message),
// //         backgroundColor: isError ? Colors.red : Colors.green,
// //         behavior: SnackBarBehavior.floating,
// //       ),
// //     );
// //   }

// //   void _togglePasswordVisibility() {
// //     setState(() {
// //       _obscurePassword = !_obscurePassword;
// //     });
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: Text(_isLogin ? 'Login' : 'Sign Up'),
// //         backgroundColor: Colors.deepPurple,
// //         foregroundColor: Colors.white,
// //       ),
// //       body: SingleChildScrollView(
// //         child: Padding(
// //           padding: const EdgeInsets.all(20.0),
// //           child: Form(
// //             key: _formKey,
// //             child: Column(
// //               mainAxisAlignment: MainAxisAlignment.center,
// //               children: [
// //                 const SizedBox(height: 40),
// //                 Icon(
// //                   Icons.person,
// //                   size: 80,
// //                   color: Colors.deepPurple,
// //                 ),
// //                 const SizedBox(height: 20),
// //                 Text(
// //                   _isLogin ? 'Welcome Back!' : 'Create Account',
// //                   style: const TextStyle(
// //                     fontSize: 28,
// //                     fontWeight: FontWeight.bold,
// //                     color: Colors.deepPurple,
// //                   ),
// //                 ),
// //                 const SizedBox(height: 10),
// //                 Text(
// //                   _isLogin 
// //                       ? 'Sign in to continue your journey'
// //                       : 'Join us and get started',
// //                   style: const TextStyle(
// //                     fontSize: 16,
// //                     color: Colors.grey,
// //                   ),
// //                 ),
// //                 const SizedBox(height: 40),
// //                 TextFormField(
// //                   controller: _emailController,
// //                   decoration: const InputDecoration(
// //                     labelText: 'Email',
// //                     border: OutlineInputBorder(
// //                       borderRadius: BorderRadius.all(Radius.circular(12)),
// //                     ),
// //                     prefixIcon: Icon(Icons.email, color: Colors.deepPurple),
// //                     focusedBorder: OutlineInputBorder(
// //                       borderSide: BorderSide(color: Colors.deepPurple),
// //                       borderRadius: BorderRadius.all(Radius.circular(12)),
// //                     ),
// //                   ),
// //                   keyboardType: TextInputType.emailAddress,
// //                   validator: (value) {
// //                     if (value == null || value.isEmpty) {
// //                       return 'Please enter your email';
// //                     }
// //                     if (!value.contains('@')) {
// //                       return 'Please enter a valid email';
// //                     }
// //                     return null;
// //                   },
// //                 ),
// //                 const SizedBox(height: 20),
// //                 TextFormField(
// //                   controller: _passwordController,
// //                   decoration: InputDecoration(
// //                     labelText: 'Password',
// //                     border: const OutlineInputBorder(
// //                       borderRadius: BorderRadius.all(Radius.circular(12)),
// //                     ),
// //                     prefixIcon: const Icon(Icons.lock, color: Colors.deepPurple),
// //                     suffixIcon: IconButton(
// //                       icon: Icon(
// //                         _obscurePassword ? Icons.visibility : Icons.visibility_off,
// //                         color: Colors.grey,
// //                       ),
// //                       onPressed: _togglePasswordVisibility,
// //                       splashRadius: 20,
// //                     ),
// //                     focusedBorder: const OutlineInputBorder(
// //                       borderSide: BorderSide(color: Colors.deepPurple),
// //                       borderRadius: BorderRadius.all(Radius.circular(12)),
// //                     ),
// //                   ),
// //                   obscureText: _obscurePassword,
// //                   validator: (value) {
// //                     if (value == null || value.isEmpty) {
// //                       return 'Please enter your password';
// //                     }
// //                     if (value.length < 6) {
// //                       return 'Password must be at least 6 characters';
// //                     }
// //                     return null;
// //                   },
// //                 ),
                
// //                 // Email verification notice for sign up
// //                 if (!_isLogin) ...[
// //                   const SizedBox(height: 15),
// //                   Container(
// //                     padding: const EdgeInsets.all(12),
// //                     decoration: BoxDecoration(
// //                       color: Colors.blue[50],
// //                       borderRadius: BorderRadius.circular(8),
// //                       border: Border.all(color: Colors.blue),
// //                     ),
// //                     child: Row(
// //                       children: [
// //                         Icon(Icons.info, color: Colors.blue[700]),
// //                         const SizedBox(width: 10),
// //                         Expanded(
// //                           child: Text(
// //                             'We will send you an email verification link',
// //                             style: TextStyle(
// //                               color: Colors.blue[800],
// //                               fontSize: 14,
// //                             ),
// //                           ),
// //                         ),
// //                       ],
// //                     ),
// //                   ),
// //                 ],
                
// //                 const SizedBox(height: 30),
// //                 _isLoading
// //                     ? const CircularProgressIndicator(
// //                         valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
// //                       )
// //                     : SizedBox(
// //                         width: double.infinity,
// //                         height: 55,
// //                         child: ElevatedButton(
// //                           onPressed: _submit,
// //                           style: ElevatedButton.styleFrom(
// //                             backgroundColor: Colors.deepPurple,
// //                             foregroundColor: Colors.white,
// //                             shape: RoundedRectangleBorder(
// //                               borderRadius: BorderRadius.circular(12),
// //                             ),
// //                             elevation: 2,
// //                           ),
// //                           child: Text(
// //                             _isLogin ? 'Login' : 'Sign Up',
// //                             style: const TextStyle(
// //                               fontSize: 18,
// //                               fontWeight: FontWeight.bold,
// //                             ),
// //                           ),
// //                         ),
// //                       ),
// //                 const SizedBox(height: 20),
// //                 Row(
// //                   mainAxisAlignment: MainAxisAlignment.center,
// //                   children: [
// //                     Text(
// //                       _isLogin
// //                           ? "Don't have an account?"
// //                           : "Already have an account?",
// //                       style: const TextStyle(
// //                         color: Colors.grey,
// //                       ),
// //                     ),
// //                     const SizedBox(width: 5),
// //                     GestureDetector(
// //                       onTap: () {
// //                         setState(() {
// //                           _isLogin = !_isLogin;
// //                           _clearForm();
// //                         });
// //                       },
// //                       child: Text(
// //                         _isLogin ? "Sign Up" : "Login",
// //                         style: const TextStyle(
// //                           color: Colors.deepPurple,
// //                           fontWeight: FontWeight.bold,
// //                         ),
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }

// //   @override
// //   void dispose() {
// //     _emailController.dispose();
// //     _passwordController.dispose();
// //     super.dispose();
// //   }
// // }


// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:my_app/home_screen.dart';

// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _zipcodeController = TextEditingController();
//   final _auth = FirebaseAuth.instance;
//   final _firestore = FirebaseFirestore.instance;
//   final _firebaseMessaging = FirebaseMessaging.instance;
//   bool _isLoading = false;
//   bool _isLogin = true;
//   bool _obscurePassword = true;

//   Future<void> _submit() async {
//     if (!_formKey.currentState!.validate()) return;

//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       if (_isLogin) {
//         // Login existing user
//         UserCredential userCredential = await _auth.signInWithEmailAndPassword(
//           email: _emailController.text.trim(),
//           password: _passwordController.text.trim(),
//         );

//         await _updateUserOnLogin(userCredential.user!);
//         _showSnackBar('Login successful!');
//         _navigateToHome();
//       } else {
//         // Register new user
//         UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
//           email: _emailController.text.trim(),
//           password: _passwordController.text.trim(),
//         );

//         await userCredential.user!.sendEmailVerification();
//         await _saveUserOnRegister(userCredential.user!);
        
//         _showSnackBar('Account created successfully! Please check your email for verification.');
//         _clearForm();
//         setState(() {
//           _isLogin = true;
//         });
//       }
//     } on FirebaseAuthException catch (e) {
//       _handleAuthError(e);
//     } catch (e) {
//       _showSnackBar('An error occurred: $e', isError: true);
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   void _navigateToHome() {
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(builder: (context) => const HomeScreen()),
//     );
//   }

//   void _clearForm() {
//     _emailController.clear();
//     _passwordController.clear();
//     _zipcodeController.clear();
//   }

//   Future<String?> _getFCMToken() async {
//     try {
//       await _firebaseMessaging.requestPermission(
//         alert: true,
//         badge: true,
//         sound: true,
//       );

//       String? token = await _firebaseMessaging.getToken();
//       print('📱 FCM Token available: ${token != null}');
//       return token;
//     } catch (e) {
//       print('❌ Error getting FCM token: $e');
//       return null;
//     }
//   }

//   bool _isValidUSZipcode(String zipcode) {
//     if (zipcode.trim().isEmpty) return false;
//     RegExp usZipcode = RegExp(r'^\d{5}(-\d{4})?$');
//     return usZipcode.hasMatch(zipcode.trim());
//   }

//   // For REGISTRATION - always update FCM token and save zipcode
//   Future<void> _saveUserOnRegister(User user) async {
//     try {
//       String? fcmToken = await _getFCMToken();
//       String zipcode = _zipcodeController.text.trim();
      
//       // Validate zipcode for registration
//       if (!_isValidUSZipcode(zipcode)) {
//         throw Exception('Please enter a valid US zipcode');
//       }

//       await _firestore.collection('users').doc(user.uid).set({
//         'uid': user.uid,
//         'email': user.email,
//         'zipcode': zipcode,
//         'displayName': user.displayName ?? '',
//         'photoURL': user.photoURL ?? '',
//         'fcmToken': fcmToken,
//         'notificationsEnabled': true,
//         'createdAt': FieldValue.serverTimestamp(),
//         'updatedAt': FieldValue.serverTimestamp(),
//         'lastLoginAt': FieldValue.serverTimestamp(),
//         'isEmailVerified': user.emailVerified,
//         'accountType': 'user',
//         'status': 'active',
//       }, SetOptions(merge: true));
      
//       print('✅ New user registered with UID: ${user.uid}');
//       print('📍 Zipcode saved: $zipcode');
//       print('🔔 Notifications: ENABLED (default for new users)');
      
//     } catch (e) {
//       print('❌ Error saving new user: $e');
//       rethrow;
//     }
//   }

//   // For LOGIN - FCM token is OPTIONAL, preserve existing settings
//   Future<void> _updateUserOnLogin(User user) async {
//     try {
//       DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      
//       bool notificationsEnabled = true;
//       String? existingFcmToken;
      
//       if (userDoc.exists) {
//         notificationsEnabled = userDoc['notificationsEnabled'] ?? true;
//         existingFcmToken = userDoc['fcmToken'];
//         print('🔔 Existing notification setting: ${notificationsEnabled ? "ENABLED" : "DISABLED"}');
//       }
      
//       Map<String, dynamic> updateData = {
//         'lastLoginAt': FieldValue.serverTimestamp(),
//         'updatedAt': FieldValue.serverTimestamp(),
//         'isEmailVerified': user.emailVerified,
//         'notificationsEnabled': notificationsEnabled,
//       };
      
//       if (notificationsEnabled) {
//         String? newFcmToken = await _getFCMToken();
//         if (newFcmToken != null) {
//           updateData['fcmToken'] = newFcmToken;
//           print('📱 FCM Token updated on login: $newFcmToken');
//         }
//       } else {
//         updateData['fcmToken'] = FieldValue.delete();
//         print('📱 FCM Token removed (notifications disabled)');
//       }
      
//       await _firestore.collection('users').doc(user.uid).set(updateData, SetOptions(merge: true));
      
//       print('✅ User updated on login: ${user.uid}');
      
//     } catch (e) {
//       print('❌ Error updating user on login: $e');
//       if (e.toString().contains('No document to update')) {
//         await _saveUserOnRegister(user);
//       }
//     }
//   }

//   void _handleAuthError(FirebaseAuthException e) {
//     String message = 'An error occurred';
//     if (e.code == 'user-not-found') {
//       message = 'No user found with this email';
//     } else if (e.code == 'wrong-password') {
//       message = 'Wrong password provided';
//     } else if (e.code == 'email-already-in-use') {
//       message = 'Email already in use';
//     } else if (e.code == 'weak-password') {
//       message = 'Password is too weak';
//     } else if (e.code == 'invalid-email') {
//       message = 'Invalid email address';
//     }
//     _showSnackBar(message, isError: true);
//   }

//   void _showSnackBar(String message, {bool isError = false}) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: isError ? Colors.red : Colors.green,
//         behavior: SnackBarBehavior.floating,
//       ),
//     );
//   }

//   void _togglePasswordVisibility() {
//     setState(() {
//       _obscurePassword = !_obscurePassword;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(_isLogin ? 'Login' : 'Sign Up'),
//         backgroundColor: Colors.deepPurple,
//         foregroundColor: Colors.white,
//       ),
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.all(20.0),
//           child: Form(
//             key: _formKey,
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const SizedBox(height: 40),
//                 Icon(
//                   Icons.person,
//                   size: 80,
//                   color: Colors.deepPurple,
//                 ),
//                 const SizedBox(height: 20),
//                 Text(
//                   _isLogin ? 'Welcome Back!' : 'Create Account',
//                   style: const TextStyle(
//                     fontSize: 28,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.deepPurple,
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 Text(
//                   _isLogin 
//                       ? 'Sign in to continue your journey'
//                       : 'Join us and get started',
//                   style: const TextStyle(
//                     fontSize: 16,
//                     color: Colors.grey,
//                   ),
//                 ),
//                 const SizedBox(height: 40),
                
//                 // Email Field
//                 TextFormField(
//                   controller: _emailController,
//                   decoration: const InputDecoration(
//                     labelText: 'Email',
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.all(Radius.circular(12)),
//                     ),
//                     prefixIcon: Icon(Icons.email, color: Colors.deepPurple),
//                     focusedBorder: OutlineInputBorder(
//                       borderSide: BorderSide(color: Colors.deepPurple),
//                       borderRadius: BorderRadius.all(Radius.circular(12)),
//                     ),
//                   ),
//                   keyboardType: TextInputType.emailAddress,
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter your email';
//                     }
//                     if (!value.contains('@')) {
//                       return 'Please enter a valid email';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 20),
                
//                 // Password Field
//                 TextFormField(
//                   controller: _passwordController,
//                   decoration: InputDecoration(
//                     labelText: 'Password',
//                     border: const OutlineInputBorder(
//                       borderRadius: BorderRadius.all(Radius.circular(12)),
//                     ),
//                     prefixIcon: const Icon(Icons.lock, color: Colors.deepPurple),
//                     suffixIcon: IconButton(
//                       icon: Icon(
//                         _obscurePassword ? Icons.visibility : Icons.visibility_off,
//                         color: Colors.grey,
//                       ),
//                       onPressed: _togglePasswordVisibility,
//                       splashRadius: 20,
//                     ),
//                     focusedBorder: const OutlineInputBorder(
//                       borderSide: BorderSide(color: Colors.deepPurple),
//                       borderRadius: BorderRadius.all(Radius.circular(12)),
//                     ),
//                   ),
//                   obscureText: _obscurePassword,
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter your password';
//                     }
//                     if (value.length < 6) {
//                       return 'Password must be at least 6 characters';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 20),
                
//                 // Zipcode Field (Only for Sign Up)
//                 if (!_isLogin) ...[
//                   TextFormField(
//                     controller: _zipcodeController,
//                     decoration: const InputDecoration(
//                       labelText: 'Zip Code',
//                       hintText: 'e.g., 12345 or 12345-6789',
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.all(Radius.circular(12)),
//                       ),
//                       prefixIcon: Icon(Icons.location_on, color: Colors.deepPurple),
//                       focusedBorder: OutlineInputBorder(
//                         borderSide: BorderSide(color: Colors.deepPurple),
//                         borderRadius: BorderRadius.all(Radius.circular(12)),
//                       ),
//                     ),
//                     keyboardType: TextInputType.number,
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter your zip code';
//                       }
//                       if (!_isValidUSZipcode(value)) {
//                         return 'Please enter a valid US zip code';
//                       }
//                       return null;
//                     },
//                   ),
//                   const SizedBox(height: 15),
//                 ],
                
//                 // Email verification notice for sign up
//                 if (!_isLogin) ...[
//                   Container(
//                     padding: const EdgeInsets.all(12),
//                     decoration: BoxDecoration(
//                       color: Colors.blue[50],
//                       borderRadius: BorderRadius.circular(8),
//                       border: Border.all(color: Colors.blue),
//                     ),
//                     child: Row(
//                       children: [
//                         Icon(Icons.info, color: Colors.blue[700]),
//                         const SizedBox(width: 10),
//                         Expanded(
//                           child: Text(
//                             'We will send you an email verification link',
//                             style: TextStyle(
//                               color: Colors.blue[800],
//                               fontSize: 14,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 15),
//                 ],
                
//                 const SizedBox(height: 30),
                
//                 // Submit Button
//                 _isLoading
//                     ? const CircularProgressIndicator(
//                         valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
//                       )
//                     : SizedBox(
//                         width: double.infinity,
//                         height: 55,
//                         child: ElevatedButton(
//                           onPressed: _submit,
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.deepPurple,
//                             foregroundColor: Colors.white,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             elevation: 2,
//                           ),
//                           child: Text(
//                             _isLogin ? 'Login' : 'Sign Up',
//                             style: const TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                       ),
//                 const SizedBox(height: 20),
                
//                 // Toggle between Login and Sign Up
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Text(
//                       _isLogin
//                           ? "Don't have an account?"
//                           : "Already have an account?",
//                       style: const TextStyle(
//                         color: Colors.grey,
//                       ),
//                     ),
//                     const SizedBox(width: 5),
//                     GestureDetector(
//                       onTap: () {
//                         setState(() {
//                           _isLogin = !_isLogin;
//                           _clearForm();
//                         });
//                       },
//                       child: Text(
//                         _isLogin ? "Sign Up" : "Login",
//                         style: const TextStyle(
//                           color: Colors.deepPurple,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     _zipcodeController.dispose();
//     super.dispose();
//   }
// }

// login_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:my_app/forget_pw.dart';
import 'package:my_app/home_screen.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _zipcodeController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _firebaseMessaging = FirebaseMessaging.instance;
  bool _isLoading = false;
  bool _isLogin = true;
  bool _obscurePassword = true;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isLogin) {
        // Login existing user
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        await _updateUserOnLogin(userCredential.user!);
        _showSnackBar('Login successful!');
        _navigateToHome();
      } else {
        // Register new user
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        await userCredential.user!.sendEmailVerification();
        await _saveUserOnRegister(userCredential.user!);
        
        _showSnackBar('Account created successfully! Please check your email for verification.');
        _clearForm();
        setState(() {
          _isLogin = true;
        });
      }
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
    } catch (e) {
      _showSnackBar('An error occurred: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  void _clearForm() {
    _emailController.clear();
    _passwordController.clear();
    _zipcodeController.clear();
  }

  Future<String?> _getFCMToken() async {
    try {
      await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      String? token = await _firebaseMessaging.getToken();
      print('📱 FCM Token available: ${token != null}');
      return token;
    } catch (e) {
      print('❌ Error getting FCM token: $e');
      return null;
    }
  }

  bool _isValidUSZipcode(String zipcode) {
    if (zipcode.trim().isEmpty) return false;
    RegExp usZipcode = RegExp(r'^\d{5}(-\d{4})?$');
    return usZipcode.hasMatch(zipcode.trim());
  }

  // For REGISTRATION - always update FCM token and save zipcode
  Future<void> _saveUserOnRegister(User user) async {
    try {
      String? fcmToken = await _getFCMToken();
      String zipcode = _zipcodeController.text.trim();
      
      // Validate zipcode for registration
      if (!_isValidUSZipcode(zipcode)) {
        throw Exception('Please enter a valid US zipcode');
      }

      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'zipcode': zipcode,
        'displayName': user.displayName ?? '',
        'photoURL': user.photoURL ?? '',
        'fcmToken': fcmToken,
        'notificationsEnabled': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'isEmailVerified': user.emailVerified,
        'accountType': 'user',
        'status': 'active',
      }, SetOptions(merge: true));
      
      print('✅ New user registered with UID: ${user.uid}');
      print('📍 Zipcode saved: $zipcode');
      print('🔔 Notifications: ENABLED (default for new users)');
      
    } catch (e) {
      print('❌ Error saving new user: $e');
      rethrow;
    }
  }

  // For LOGIN - FCM token is OPTIONAL, preserve existing settings
  Future<void> _updateUserOnLogin(User user) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      bool notificationsEnabled = true;
      String? existingFcmToken;
      
      if (userDoc.exists) {
        notificationsEnabled = userDoc['notificationsEnabled'] ?? true;
        existingFcmToken = userDoc['fcmToken'];
        print('🔔 Existing notification setting: ${notificationsEnabled ? "ENABLED" : "DISABLED"}');
      }
      
      Map<String, dynamic> updateData = {
        'lastLoginAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isEmailVerified': user.emailVerified,
        'notificationsEnabled': notificationsEnabled,
      };
      
      if (notificationsEnabled) {
        String? newFcmToken = await _getFCMToken();
        if (newFcmToken != null) {
          updateData['fcmToken'] = newFcmToken;
          print('📱 FCM Token updated on login: $newFcmToken');
        }
      } else {
        updateData['fcmToken'] = FieldValue.delete();
        print('📱 FCM Token removed (notifications disabled)');
      }
      
      await _firestore.collection('users').doc(user.uid).set(updateData, SetOptions(merge: true));
      
      print('✅ User updated on login: ${user.uid}');
      
    } catch (e) {
      print('❌ Error updating user on login: $e');
      if (e.toString().contains('No document to update')) {
        await _saveUserOnRegister(user);
      }
    }
  }

  void _handleAuthError(FirebaseAuthException e) {
    String message = 'An error occurred';
    if (e.code == 'user-not-found') {
      message = 'No user found with this email';
    } else if (e.code == 'wrong-password') {
      message = 'Wrong password provided';
    } else if (e.code == 'email-already-in-use') {
      message = 'Email already in use';
    } else if (e.code == 'weak-password') {
      message = 'Password is too weak';
    } else if (e.code == 'invalid-email') {
      message = 'Invalid email address';
    }
    _showSnackBar(message, isError: true);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _navigateToForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Login' : 'Sign Up'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Icon(
                  Icons.person,
                  size: 80,
                  color: Colors.deepPurple,
                ),
                const SizedBox(height: 20),
                Text(
                  _isLogin ? 'Welcome Back!' : 'Create Account',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _isLogin 
                      ? 'Sign in to continue your journey'
                      : 'Join us and get started',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 40),
                
                // Email Field
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    prefixIcon: Icon(Icons.email, color: Colors.deepPurple),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.deepPurple),
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                
                // Password Field
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    prefixIcon: const Icon(Icons.lock, color: Colors.deepPurple),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: _togglePasswordVisibility,
                      splashRadius: 20,
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.deepPurple),
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                  obscureText: _obscurePassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                
                // Forgot Password (Only for Login)
                if (_isLogin) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _navigateToForgotPassword,
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                
                // Zipcode Field (Only for Sign Up)
                if (!_isLogin) ...[
                  TextFormField(
                    controller: _zipcodeController,
                    decoration: const InputDecoration(
                      labelText: 'Zip Code',
                      hintText: 'e.g., 12345 or 12345-6789',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      prefixIcon: Icon(Icons.location_on, color: Colors.deepPurple),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.deepPurple),
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your zip code';
                      }
                      if (!_isValidUSZipcode(value)) {
                        return 'Please enter a valid US zip code';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                ],
                
                // Email verification notice for sign up
                if (!_isLogin) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue[700]),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'We will send you an email verification link',
                            style: TextStyle(
                              color: Colors.blue[800],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                ],
                
                const SizedBox(height: 30),
                
                // Submit Button
                _isLoading
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                      )
                    : SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: Text(
                            _isLogin ? 'Login' : 'Sign Up',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                const SizedBox(height: 20),
                
                // Toggle between Login and Sign Up
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isLogin
                          ? "Don't have an account?"
                          : "Already have an account?",
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 5),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isLogin = !_isLogin;
                          _clearForm();
                        });
                      },
                      child: Text(
                        _isLogin ? "Sign Up" : "Login",
                        style: const TextStyle(
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _zipcodeController.dispose();
    super.dispose();
  }
}