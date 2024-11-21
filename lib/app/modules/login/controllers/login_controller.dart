import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:wave_mercredi/app/services/firestore_services.dart';
import 'package:wave_mercredi/app/models/user_model.dart';

class LoginController {
  final FirestoreService _firestoreService = FirestoreService();
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  Future<User?> login({
    required String phoneNumber,
    required String password,
    required Function(String) onError,
    required Function(User) onSuccess,
  }) async {
    try {
      // Nettoyage du numéro de téléphone
      final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

      // Vérifier d'abord si l'utilisateur existe dans Firestore
      final firestoreUser = await _firestoreService.getUserByPhone(cleanPhone);

      if (firestoreUser == null) {
        onError('Utilisateur non trouvé');
        return null;
      }

      // Connexion avec Firebase Auth
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: firestoreUser.email, // Utiliser l'email stocké
        password: password,
      );

      if (userCredential.user != null) {
        // Mettre à jour le displayName si nécessaire
        if (userCredential.user?.displayName != firestoreUser.displayName) {
          await userCredential.user?.updateDisplayName(
              '${firestoreUser.firstName} ${firestoreUser.lastName}');
        }

        onSuccess(firestoreUser);
        return firestoreUser;
      }
    } catch (e) {
      onError(_handleAuthError(e));
    }
    return null;
  }

  String _handleAuthError(dynamic e) {
    if (e is auth.FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'Numéro de téléphone non trouvé';
        case 'wrong-password':
          return 'Mot de passe incorrect';
        case 'user-disabled':
          return 'Ce compte a été désactivé';
        default:
          return 'Une erreur s\'est produite: ${e.message}';
      }
    }
    return e.toString();
  }
}
