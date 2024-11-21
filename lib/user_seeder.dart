import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserSeeder {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> seedUsers() async {
    try {
      // Informations utilisateur
      const String firstName = 'Baba Issa';
      const String lastName = 'Ndiaye';
      const String phoneNumber = '786559422'; // Numéro sans indicatif
      const String domain = 'votre-domaine.com'; // Remplacez par votre domaine
      const String role = 'agent';
      const String password = '196920'; // Remplacez par un mot de passe sécurisé

      // Formater le numéro comme email
      final String email = '$phoneNumber@$domain';

      // Créer l'utilisateur dans Firebase Authentication
   UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
  email: email,
  password: password,
);
print('UserCredential: ${userCredential.toString()}');


      // Récupérer l'ID utilisateur
      String? userId = userCredential.user?.uid;

      // Créer le document utilisateur dans Firestore
      if (userId != null) {
        await _firestore.collection('compte').doc(userId).set({
          'id': userId,
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'phoneNumber': phoneNumber,
          'role': role,
          'displayName': '$firstName $lastName',
        });

        print('Utilisateur créé avec succès : $firstName $lastName');
      } else {
        print('Erreur : ID utilisateur introuvable.');
      }
    } catch (e) {
      print('Erreur lors de la création de l\'utilisateur : $e');
    }
  }
}
