import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> registerUser({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String dob,
  }) async {
    try {
      // Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      // Firestore user data
      await _firestore.collection('users').doc(user!.uid).set({
        'uid': user.uid,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'dob': dob,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return null; // success
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Something went wrong. Please try again.';
    }
  }
}
