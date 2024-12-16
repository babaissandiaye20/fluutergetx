import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:wave_mercredi/app/services/firestore_services.dart';
import 'package:wave_mercredi/app/models/user_model.dart';

class LoginController {
  final FirestoreService _firestoreService = FirestoreService();
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<User?> login({
    String? phoneNumber,
    String? password,
    Function(String)? onError,
    Function(User)? onSuccess,
  }) async {
    try {
      auth.User? firebaseUser;
      User? appUser;

      if (phoneNumber != null && password != null) {
        final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
        final firestoreUser =
            await _firestoreService.getUserByPhone(cleanPhone);

        if (firestoreUser == null) {
          onError?.call('Utilisateur non trouvé');
          return null;
        }

        final userCredential = await _auth.signInWithEmailAndPassword(
          email: firestoreUser.email,
          password: password,
        );

        firebaseUser = userCredential.user;
        appUser = firestoreUser;
      }

      if (appUser != null && firebaseUser != null) {
        onSuccess?.call(appUser);
        return appUser;
      }
    } catch (e) {
      onError?.call(_handleGoogleSignInError(e));
    }
    return null;
  }

  Future<User?> signInWithGoogle({
    Function(String)? onError,
    Function(User, bool)? onSuccess,
  }) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        onError?.call('Connexion Google annulée');
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final auth.OAuthCredential credential =
          auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        var existingUser =
            await _firestoreService.getUserByEmail(firebaseUser.email!);
        bool isFirstLogin = existingUser == null;

        if (isFirstLogin) {
          existingUser = User(
            id: firebaseUser.uid,
            firstName: '',
            lastName: '',
            email: firebaseUser.email!,
            phoneNumber: '',
            role: '',
            displayName: firebaseUser.displayName ?? '',
            balance: 0.0,
          );

          await _firestoreService.setUser(firebaseUser.uid, existingUser);
        }

        onSuccess?.call(existingUser, isFirstLogin);
        return existingUser;
      }
    } catch (e) {
      print('Google Sign-In Error: $e'); // Add detailed logging
      onError?.call(_handleGoogleSignInError(e));
    }
    return null;
  }

  String _handleGoogleSignInError(dynamic e) {
    if (e is auth.FirebaseAuthException) {
      switch (e.code) {
        case 'account-exists-with-different-credential':
          return 'Ce compte existe déjà avec un autre mode de connexion';
        case 'invalid-credential':
          return 'Identifiants de connexion invalides';
        default:
          return 'Erreur de connexion Google: ${e.message}';
      }
    }
    return 'Erreur inattendue lors de la connexion Google';
  }
}
