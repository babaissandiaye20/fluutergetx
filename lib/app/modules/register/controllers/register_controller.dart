import 'dart:io';
import 'package:wave_mercredi/app/services/firestore_services.dart';
import 'package:wave_mercredi/app/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

class RegisterController {
  final FirestoreService _firestoreService = FirestoreService();
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  Future<User?> registerUser({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String password,
    required String role,
    File? photoFile,
    required void Function(String error) onError,
    required void Function(User user) onSuccess,
  }) async {
    try {
      // Vérification du numéro de téléphone existant
      final existingUser = await _firestoreService.getUserByPhone(phoneNumber);
      if (existingUser != null) {
        onError('Ce numéro de téléphone est déjà utilisé');
        return null;
      }

      // Vérification de l'email existant
      try {
        final emailExists = await _auth.fetchSignInMethodsForEmail(email);
        if (emailExists.isNotEmpty) {
          onError('Cet email est déjà utilisé');
          return null;
        }
      } catch (e) {
        print('Erreur lors de la vérification de l\'email : $e');
      }

      // Création de l'utilisateur dans Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final userId = userCredential.user!.uid;

        // Définir le nom d'affichage
        await userCredential.user!.updateDisplayName('$firstName $lastName');

        // Créer l'utilisateur dans Firestore
        final user = User(
          id: userId,
          firstName: firstName,
          lastName: lastName,
          email: email,
          phoneNumber: phoneNumber,
          role: role,
          displayName: '$firstName $lastName',
          balance: 0.0, // Solde initial à 0
        );

        // Insérer l'utilisateur dans Firestore
        await _firestoreService.setUser(userId, user);

        onSuccess(user);
        return user;
      }
    } catch (e) {
      onError(_handleAuthError(e));
    }
    return null;
  }

  String _handleAuthError(dynamic e) {
    if (e is auth.FirebaseAuthException) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'Cet email est déjà utilisé';
        case 'weak-password':
          return 'Le mot de passe doit contenir au moins 6 caractères';
        default:
          return 'Une erreur s\'est produite: ${e.message}';
      }
    }
    return e.toString();
  }
}