import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:madtrack/models/auth_result.dart';

class AuthManager {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<AuthResult> registerWithEmailAndPassword(
      String email, String password, String username) async {
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
     await userCredential.user?.updateDisplayName(username);
      DatabaseReference userRef = FirebaseDatabase.instance
          .ref()
          .child('Users/${userCredential.user?.uid}');
      await userRef.set({'username': username});
      return AuthResult(success: true);
    } on FirebaseAuthException catch (e) {
      String errorMessage = '';
      if (e.code == 'weak-password') {
        errorMessage = 'La contraseña es demasiado débil.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'Ya hay una cuenta registrada con este email.';
      }
      return AuthResult(success: false, errorMessage: errorMessage);
    }
  }

  Future<AuthResult> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return AuthResult(success: true);
    } on FirebaseAuthException catch (e) {
      String errorMessage = '';
      if (e.code == 'user-not-found') {
        errorMessage = 'No existe cuenta para este email.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Contraseña de usuario incorrecta.';
      }

      return AuthResult(success: false, errorMessage: errorMessage);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  User? getCurrentUser() {
    print(_auth.currentUser.toString());
    return _auth.currentUser;
  }
}
