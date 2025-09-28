import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_app/login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final firestore = FirebaseFirestore.instance;

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
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Force refresh the page
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
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
                    const SizedBox(height: 5),
                    Text(
                      'UID: ${user?.uid ?? 'N/A'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // User Data from Firestore
            StreamBuilder<DocumentSnapshot>(
              stream: firestore.collection('users').doc(user?.uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const InfoCard(
                    icon: Icons.error,
                    title: 'Error',
                    value: 'Failed to load user data',
                    isError: true,
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const InfoCard(
                    icon: Icons.warning,
                    title: 'No Data',
                    value: 'User data not found in Firestore',
                    isWarning: true,
                  );
                }

                var userData = snapshot.data!.data() as Map<String, dynamic>;
                
                return Column(
                  children: [
                    InfoCard(
                      icon: Icons.email,
                      title: 'Email',
                      value: userData['email'] ?? 'Not available',
                    ),
                    InfoCard(
                      icon: Icons.verified_user,
                      title: 'Email Verified',
                      value: userData['isEmailVerified'] == true ? 'Yes ✅' : 'No ❌',
                      isWarning: userData['isEmailVerified'] != true,
                    ),
                    InfoCard(
                      icon: Icons.notifications,
                      title: 'FCM Token Status',
                      value: userData['fcmToken'] != null 
                          ? 'Token Set ✅' 
                          : 'Not Set ❌',
                      isWarning: userData['fcmToken'] == null,
                    ),
                    if (userData['fcmToken'] != null) ...[
                      InfoCard(
                        icon: Icons.code,
                        title: 'FCM Token (First 20 chars)',
                        value: userData['fcmToken'].toString().substring(0, 20) + '...',
                      ),
                      InfoCard(
                        icon: Icons.data_array,
                        title: 'FCM Token Length',
                        value: '${userData['fcmToken'].toString().length} characters',
                      ),
                    ],
                    InfoCard(
                      icon: Icons.calendar_today,
                      title: 'Account Created',
                      value: userData['createdAt'] != null 
                          ? _formatTimestamp(userData['createdAt'])
                          : 'Unknown',
                    ),
                    InfoCard(
                      icon: Icons.login,
                      title: 'Last Login',
                      value: userData['lastLoginAt'] != null 
                          ? _formatTimestamp(userData['lastLoginAt'])
                          : 'Unknown',
                    ),
                    InfoCard(
                      icon: Icons.update,
                      title: 'Last Updated',
                      value: userData['updatedAt'] != null 
                          ? _formatTimestamp(userData['updatedAt'])
                          : 'Unknown',
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    return 'Unknown';
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
              onPressed: () {
                Navigator.of(context).pop();
              },
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
}

// Enhanced InfoCard Widget
class InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool isError;
  final bool isWarning;

  const InfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.isError = false,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    Color iconColor = Colors.deepPurple;
    if (isError) iconColor = Colors.red;
    if (isWarning) iconColor = Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: isError ? Colors.red[50] : (isWarning ? Colors.orange[50] : null),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(title),
        subtitle: Text(value),
        trailing: isError || isWarning 
            ? Icon(
                isError ? Icons.error : Icons.warning,
                color: iconColor,
              )
            : null,
      ),
    );
  }
}