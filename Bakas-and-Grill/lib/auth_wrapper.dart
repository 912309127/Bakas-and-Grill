import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- IMPORT YOUR SCREENS ---
import 'pages/login_screen.dart';
import 'pages/kitchen.dart';
import 'pages/admin.dart';
import 'pages/cashier.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // 1. Listen to see if a user is logged in or out
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        
        // While checking login status, show a loader
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFFc00e22))));
        }

        // 2. A user is currently logged in!
        if (snapshot.hasData && snapshot.data != null) {
          
          // Fetch their specific account data from the Firestore 'users' collection
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(snapshot.data!.uid).get(),
            builder: (context, userSnap) {
              
              if (userSnap.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFFc00e22))));
              }

              if (userSnap.hasData && userSnap.data!.exists) {
                // Read the role from the database
                String role = userSnap.data!.get('role') ?? 'kitchen';
                String name = userSnap.data!.get('name') ?? snapshot.data!.email;
                String email = snapshot.data!.email!;

                // 3. ROUTE TO THE CORRECT SCREEN BASED ON ROLE
                if (role == 'admin') {
                  return const AdminAuthGuard(); 
                } else if (role == 'cashier') {
                  return CashierMainScreen(cashierName: name, cashierEmail: email); 
                } else {
                  return const KitchenDashboard(); 
                }
              }

              // Fallback: If user is logged in but has no database document, log them out.
              FirebaseAuth.instance.signOut();
              return const Scaffold(body: Center(child: Text("User profile not found in database. Contact Admin.")));
            },
          );
        }

        // 4. Nobody is logged in -> Show the Login Screen
        return const LoginScreen();
      },
    );
  }
}