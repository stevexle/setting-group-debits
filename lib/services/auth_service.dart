import 'package:firebase_auth/firebase_auth.dart';
import 'package:setting_group_debits/services/log_service.dart';
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
      log.info("Starting Google Sign In...");
      await _ensureInitialized();
      final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();
      if (googleUser == null) {
        log.info("Google Sign In cancelled by user");
        return null;
      }

      final authorizedUser = await googleUser.authorizationClient.authorizeScopes([]);
      final accessToken = authorizedUser.accessToken;
      final googleAuth = googleUser.authentication;
      
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      log.info("Google Sign In successful for ${userCredential.user?.email}");
      return userCredential.user;
    } catch (e, s) {
      log.error('Google Auth Error', e, s);
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      log.info("Signing out...");
      await _ensureInitialized();
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e, s) {
      log.error('Sign Out Error', e, s);
    }
  }
}
