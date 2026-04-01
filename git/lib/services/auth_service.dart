import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart' as fs;

/// AuthService supports Firebase Auth if available, else falls back to local storage.
class AuthService extends ChangeNotifier {
  bool _isLoggedIn = false;
  String? _email;
  String? _phone;
  String? _name;
  bool _firebaseReady = false;

  bool get isLoggedIn => _isLoggedIn;
  String? get email => _email;
  String? get phone => _phone;
  String? get name => _name;
  bool get firebaseReady => _firebaseReady;

  Future<void> restore() async {
    try {
      await Firebase.initializeApp();
      _firebaseReady = true;
      final user = fb.FirebaseAuth.instance.currentUser;
      if (user != null) {
        _isLoggedIn = true;
        _email = user.email;
        _name = user.displayName;
        
        // Fetch additional user data from Firestore including phone
        await _fetchUserDataFromFirestore(user.uid);
      }
    } catch (_) {
      _firebaseReady = false;
    }
    if (!_isLoggedIn) {
      final prefs = await SharedPreferences.getInstance();
      _isLoggedIn = prefs.getBool('logged_in') ?? false;
      _email = prefs.getString('email');
      _phone = prefs.getString('phone');
      _name = prefs.getString('name');
    }
    notifyListeners();
  }

  Future<String?> register({required String name, required String email, required String phone, required String password}) async {
    if (_firebaseReady) {
      try {
        final cred = await fb.FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
        await cred.user?.updateDisplayName(name);
        // Create user profile in Firestore for quick lookups
        try {
          await fs.FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
            'uid': cred.user!.uid,
            'name': name,
            'email': email,
            'phone': phone,
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          }, fs.SetOptions(merge: true));
          print('User profile created in Firestore with phone: $phone');
        } catch (e) {
          print('Error creating user profile in Firestore: $e');
        }
        _isLoggedIn = true;
        _email = email;
        _phone = phone;
        _name = name;
        notifyListeners();
        return null;
      } catch (e) {
        return e.toString();
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('name', name);
      await prefs.setString('email', email);
      await prefs.setString('phone', phone);
      await prefs.setString('password', password);
      await prefs.setBool('logged_in', true);
      _isLoggedIn = true;
      _email = email;
      _phone = phone;
      _name = name;
      notifyListeners();
      return null;
    }
  }

  Future<String?> login({required String id, required String password}) async {
    if (_firebaseReady && id.contains('@')) {
      try {
        await fb.FirebaseAuth.instance.signInWithEmailAndPassword(email: id, password: password);
        final user = fb.FirebaseAuth.instance.currentUser;
        if (user != null) {
          _isLoggedIn = true;
          _email = id;
          _name = user.displayName;
          
          // Fetch additional user data from Firestore including phone
          await _fetchUserDataFromFirestore(user.uid);
        }
        notifyListeners();
        return null;
      } catch (e) {
        return e.toString();
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString('email') ?? prefs.getString('phone');
      final savedPwd = prefs.getString('password');
      if ((savedId == id || prefs.getString('phone') == id) && savedPwd == password) {
        _isLoggedIn = true;
        _email = prefs.getString('email');
        _phone = prefs.getString('phone');
        _name = prefs.getString('name');
        notifyListeners();
        return null;
      }
      return 'Invalid credentials';
    }
  }

  Future<void> logout() async {
    // Update state immediately for instant logout
    _isLoggedIn = false;
    _email = null;
    _phone = null;
    _name = null;
    notifyListeners();
    
    // Clean up in background (non-blocking)
    if (_firebaseReady) {
      try { 
        fb.FirebaseAuth.instance.signOut(); // Remove await for instant logout
      } catch (_) {}
    }
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('logged_in', false);
      prefs.remove('password');
    });
  }

  Future<String?> deleteAccount() async {
    try {
      if (_firebaseReady) {
        final user = fb.FirebaseAuth.instance.currentUser;
        if (user != null) {
          await user.delete();
        }
      }
    } catch (e) {
      return e.toString();
    } finally {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      _isLoggedIn = false;
      _email = null;
      _phone = null;
      _name = null;
      notifyListeners();
    }
    return null;
  }

  Future<String?> sendPasswordReset(String id) async {
    if (_firebaseReady && id.contains('@')) {
      try {
        await fb.FirebaseAuth.instance.sendPasswordResetEmail(email: id);
        return null;
      } catch (e) { return e.toString(); }
    }
    // Local fallback: simply clear saved password
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('password');
    return null;
  }

  Future<String?> updateProfile({String? name, String? email, String? phone}) async {
    try {
      if (_firebaseReady) {
        final user = fb.FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Update display name in Firebase Auth
          if (name != null && name != _name) {
            await user.updateDisplayName(name);
          }
          
          // Update email if provided and different
          if (email != null && email != _email) {
            await user.updateEmail(email);
          }
          
          // Update user profile in Firestore
          try {
            final updates = <String, dynamic>{};
            if (name != null) updates['name'] = name;
            if (email != null) updates['email'] = email;
            if (phone != null) updates['phone'] = phone;
            updates['updatedAt'] = DateTime.now().toIso8601String();
            
            await fs.FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .set(updates, fs.SetOptions(merge: true));
          } catch (_) {
            // Firestore update failed, but Auth update succeeded
          }
        }
      } else {
        // Local storage update
        final prefs = await SharedPreferences.getInstance();
        if (name != null) await prefs.setString('name', name);
        if (email != null) await prefs.setString('email', email);
        if (phone != null) await prefs.setString('phone', phone);
      }
      
      // Update local state
      if (name != null) _name = name;
      if (email != null) _email = email;
      if (phone != null) _phone = phone;
      
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
  
  /// Helper method to fetch user data from Firestore
  Future<void> _fetchUserDataFromFirestore(String uid) async {
    try {
      final doc = await fs.FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Update local state with Firestore data
        if (data['name'] != null) _name = data['name'];
        if (data['phone'] != null) _phone = data['phone'];
        if (data['email'] != null && _email == null) _email = data['email'];
        
        print('Fetched user data from Firestore: name=$_name, phone=$_phone, email=$_email');
      } else {
        print('User document not found in Firestore for uid: $uid');
      }
    } catch (e) {
      print('Error fetching user data from Firestore: $e');
      // Don't throw error, just log it - app should continue working without Firestore data
    }
  }
}
