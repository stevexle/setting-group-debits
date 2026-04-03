import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _isInitialized = false;

  Stream<User?> get user => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await _googleSignIn.initialize();
      _isInitialized = true;
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      await _ensureInitialized();
      final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();
      if (googleUser == null) return null;

      final authorizedUser = await googleUser.authorizationClient.authorizeScopes([]);
      final accessToken = authorizedUser.accessToken;
      final googleAuth = googleUser.authentication;
      
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      print('Google Auth Error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _ensureInitialized();
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      print('Sign Out Error: $e');
    }
  }
}
