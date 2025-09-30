import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:my_app/calender.dart';
import 'package:my_app/login_screen.dart';
import 'package:my_app/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final firestore = FirebaseFirestore.instance;
  final messaging = FirebaseMessaging.instance;
  bool _notificationsEnabled = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    final userDoc = await firestore.collection('users').doc(user?.uid).get();
    if (userDoc.exists) {
      setState(() {
        _notificationsEnabled = userDoc['notificationsEnabled'] ?? true;
      });
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      if (value) {
        // Enable notifications - get new FCM token
        await _enableNotifications();
      } else {
        // Disable notifications - COMPLETELY remove FCM token
        await _disableNotifications();
      }
      
      setState(() {
        _notificationsEnabled = value;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? 
            '🔔 Notifications enabled' : 
            '🔕 Notifications disabled - No notifications will be received'
          ),
          backgroundColor: value ? Colors.green : Colors.orange,
        ),
      );
      
    } catch (e) {
      print('❌ Error toggling notifications: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update notification settings'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _enableNotifications() async {
    try {
      // Request permission
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Get new FCM token
        String? token = await messaging.getToken();
        
        if (token != null && user != null) {
          await firestore.collection('users').doc(user!.uid).update({
            'notificationsEnabled': true,
            'fcmToken': token, // Store the token
            'updatedAt': FieldValue.serverTimestamp(),
          });
          print('✅ Notifications enabled with token: $token');
        }
      }
    } catch (e) {
      print('❌ Error enabling notifications: $e');
      rethrow;
    }
  }

  Future<void> _disableNotifications() async {
    try {
      if (user != null) {
        // COMPLETELY remove the FCM token from Firestore
        await firestore.collection('users').doc(user!.uid).update({
          'notificationsEnabled': false,
          'fcmToken': FieldValue.delete(), // This completely removes the token field
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        // Also delete the token from the device
        await messaging.deleteToken();
        
        print('✅ Notifications disabled - FCM token completely removed from server and device');
      }
    } catch (e) {
      print('❌ Error disabling notifications: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              _showLogoutDialog(context);
            },
          ),
           IconButton(
            icon: const Icon(Icons.home),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const HalfStaffCalendarScreen(),
            ),
          );
        },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome to Your Dashboard!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Hello, ${user?.email ?? 'User'}!',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Notification Toggle
            StreamBuilder<DocumentSnapshot>(
              stream: firestore.collection('users').doc(user?.uid).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const SizedBox.shrink();
                }

                var userData = snapshot.data!.data() as Map<String, dynamic>;
                bool hasToken = userData['fcmToken'] != null;

                return Card(
                  elevation: 3,
                  child: ListTile(
                    leading: _isLoading 
                      ? const CircularProgressIndicator()
                      : Icon(
                          _notificationsEnabled ? 
                            Icons.notifications_active : 
                            Icons.notifications_off,
                          color: _notificationsEnabled ? Colors.green : Colors.grey,
                        ),
                    title: const Text('Push Notifications'),
                    subtitle: Text(
                      _notificationsEnabled && hasToken ? 
                        'Enabled - You will receive notifications' :
                        'Disabled - No notifications will be shown',
                    ),
                    trailing: Switch(
                      value: _notificationsEnabled,
                      onChanged: _isLoading ? null : _toggleNotifications,
                      activeColor: Colors.deepPurple,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // User Data
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: firestore.collection('users').doc(user?.uid).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error loading data'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Center(child: Text('No user data'));
                  }

                  var userData = snapshot.data!.data() as Map<String, dynamic>;

                  return ListView(
                    children: [
                      _buildInfoCard(
                        'Notification Status',
                        _notificationsEnabled ? 'Enabled 🔔' : 'Disabled 🔕',
                        _notificationsEnabled ? Colors.green : Colors.red,
                      ),
                      _buildInfoCard(
                        'FCM Token Status',
                        userData['fcmToken'] != null ? 'Active ✅' : 'No Token ❌',
                        userData['fcmToken'] != null ? Colors.green : Colors.red,
                      ),
                      _buildInfoCard(
                        'Email',
                        userData['email'] ?? 'Not available',
                        Colors.blue,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildInfoCard(String title, String value, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(title),
        subtitle: Text(value, style: TextStyle(color: color)),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  //   Widget _buildThemeToggle(BuildContext context) {
  //   final themeProvider = Provider.of<ThemeProvider>(context);

  //   return Container(
  //     padding: const EdgeInsets.symmetric(vertical: 12),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //       children: [
  //         Text(
  //           'Dark Mode',
  //           style: TextStyle(
  //             fontSize: MediaQuery.of(context).size.width * 0.05,
  //             fontWeight: FontWeight.w600,
  //             color: const Color(0xFF3C3B6E),
  //           ),
  //         ),
  //         Switch(
  //           value: themeProvider.isDarkMode,
  //           onChanged: (value) async {
  //             themeProvider.setTheme(value ? ThemeMode.dark : ThemeMode.light);

  //             final prefs = await SharedPreferences.getInstance();
  //             await prefs.setBool('is_dark_mode', value);
  //           },
  //           activeColor: const Color(0xFFB22234),
  //           activeTrackColor: const Color(0xFF3C3B6E),
  //         ),
  //       ],
  //     ),
  //   );
  // }
}