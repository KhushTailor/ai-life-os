import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Ensure Firestore keeps data cached locally for offline resilience
  static Future<void> enablePersistence() async {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  // Stream of User Auth State
  Stream<User?> get user => _auth.authStateChanges();

  // AI Categorization
  Future<String> getAIExpenseCategory(String description) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedKey = prefs.getString('gemini_api_key');
      const defaultKey = 'AIzaSyAYfXmUGpvbzT5k_NFPaDOmsm9-WJsjebo';
      final apiKey = (savedKey != null && savedKey.isNotEmpty) ? savedKey : defaultKey;

      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
      
      final prompt = 'Categorize this expense description into ONE word from these options: Food, Transport, Shopping, Bills, Entertainment, Health, Other. Description: "$description"';
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      
      String result = response.text?.trim() ?? 'Other';
      // Clean up if AI returns more than one word
      if (result.contains(' ')) result = result.split(' ')[0];
      return result;
    } catch (e) {
      return 'Other';
    }
  }

  // Google Sign In
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      debugPrint("Google Sign-In Error: $e");
      return null;
    }
  }



  // Email/Password Sign Up
  Future<User?> signUpWithEmail(String email, String password, String name) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;
      if (user != null) {
        await user.updateDisplayName(name);
        await syncUserData(user.uid, {'name': name, 'email': email, 'createdAt': FieldValue.serverTimestamp()});
      }
      return user;
    } catch (e) {
      debugPrint("Email Sign-Up Error: $e");
      rethrow;
    }
  }

  // Email/Password Sign In
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      debugPrint("Email Sign-In Error: $e");
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
    } catch (e) {
      // Ignore google sign out errors if not signed in via google
    }
    await _auth.signOut();
  }

  // Sync Data to Firestore
  Future<void> syncUserData(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).set(data, SetOptions(merge: true));
  }

  // Specialized Sync for Modules
  Future<void> syncTasks(String uid, List<Map<String, dynamic>> tasks) async {
    await _db.collection('users').doc(uid).collection('tasks').doc('current').set({'list': tasks});
  }

  Future<void> syncHabits(String uid, List<Map<String, dynamic>> habits) async { // Renamed from syncGoals for clarity
    await _db.collection('users').doc(uid).collection('habits').doc('current').set({'list': habits});
  }

  Future<void> syncFinance(String uid, List<Map<String, dynamic>> txs) async {
    await _db.collection('users').doc(uid).collection('finance').doc('current').set({'list': txs});
  }

  // Streams for real-time UI
  Stream<List<Map<String, dynamic>>> streamTasks(String uid) {
    return _db.collection('users').doc(uid).collection('tasks').doc('current').snapshots().map((doc) {
      if (doc.exists && doc.data() != null && doc.data()!.containsKey('list')) {
        return List<Map<String, dynamic>>.from(doc.data()!['list']);
      }
      return [];
    });
  }

  Stream<List<Map<String, dynamic>>> streamHabits(String uid) {
    return _db.collection('users').doc(uid).collection('habits').doc('current').snapshots().map((doc) {
      if (doc.exists && doc.data() != null && doc.data()!.containsKey('list')) {
        return List<Map<String, dynamic>>.from(doc.data()!['list']);
      }
      return [];
    });
  }

  Stream<List<Map<String, dynamic>>> streamFinance(String uid) {
    return _db.collection('users').doc(uid).collection('finance').doc('current').snapshots().map((doc) {
      if (doc.exists && doc.data() != null && doc.data()!.containsKey('list')) {
        return List<Map<String, dynamic>>.from(doc.data()!['list']);
      }
      return [];
    });
  }

  // Fetch Data from Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }
}
