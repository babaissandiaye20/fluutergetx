import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wave_mercredi/app/services/firestore_services.dart';
import 'package:wave_mercredi/app/models/user_model.dart';
import 'package:wave_mercredi/app/models/transaction_model.dart' as custom;
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';


class TransferController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
 final RxList<User> favoriteUsers = <User>[].obs;
  final RxBool showFavorites = false.obs;
  final Rx<User?> currentUser = Rx<User?>(null);
  final RxList<User> multipleReceivers = <User>[].obs;
  final RxList<ContactWithAvailability> contactsList = <ContactWithAvailability>[].obs;
  final RxBool payFeesBySender = true.obs;
  final RxDouble amount = RxDouble(0.0);
  final RxBool isLoading = false.obs;
  final RxBool isMultipleTransferMode = false.obs;
  final RxString phoneNumber = RxString('');
  final Rx<User?> receiverUser = Rx<User?>(null);

  @override
   @override
  void onInit() {
    super.onInit();
    currentUser.value = Get.arguments;
    loadAllContacts();
    _loadFavorites();
  }

  void _loadFavorites() {
    if (currentUser.value?.id != null) {
      _firestoreService
          .getFavoriteUsersStream(currentUser.value!.id)
          .listen((users) {
        favoriteUsers.value = users;
      });
    }
  }


  Future<void> loadAllContacts() async {
    try {
      // Demander la permission d'accès aux contacts
      if (!await FlutterContacts.requestPermission(readonly: true)) {
        _showErrorSnackbar('Erreur', 'Permission d\'accès aux contacts refusée');
        return;
      }

      isLoading.value = true;

      // Charger les contacts du téléphone
      final phoneContacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );

      // Charger les utilisateurs de la base de données
      final dbUsers = await _firestoreService.getAllUsers();
      
      // Créer une liste combinée
      final List<ContactWithAvailability> combinedContacts = [];

      for (final contact in phoneContacts) {
        if (contact.phones.isNotEmpty) {
          final phoneNumber = contact.phones.first.number.replaceAll(RegExp(r'\D'), '');
          final dbUser = dbUsers.firstWhereOrNull(
            (user) => user.phoneNumber.replaceAll(RegExp(r'\D'), '') == phoneNumber
          );

          combinedContacts.add(
            ContactWithAvailability(
              contact: contact,
              dbUser: dbUser,
              isAvailable: dbUser != null,
            ),
          );
        }
      }

      // Trier les contacts: disponibles en premier, puis par ordre alphabétique
      combinedContacts.sort((a, b) {
        if (a.isAvailable && !b.isAvailable) return -1;
        if (!a.isAvailable && b.isAvailable) return 1;
        return a.contact.displayName.compareTo(b.contact.displayName);
      });

      contactsList.value = combinedContacts;
    } catch (e) {
      _showErrorSnackbar('Erreur', 'Impossible de charger les contacts: $e');
    } finally {
      isLoading.value = false;
    }
  }
  Future<void> toggleFavorite(User user) async {
    if (currentUser.value == null) return;

    try {
      final isFav = await _firestoreService.isFavorite(
        currentUser.value!.id,
        user.id,
      );

      if (isFav) {
        await _firestoreService.removeFavorite(
          currentUser.value!.id,
          user.id,
        );
        _showSuccessSnackbar('Favori supprimé', 'Contact retiré des favoris');
      } else {
        await _firestoreService.addFavorite(
          currentUser.value!.id,
          user.id,
        );
        _showSuccessSnackbar('Favori ajouté', 'Contact ajouté aux favoris');
      }
    } catch (e) {
      _showErrorSnackbar('Erreur', 'Impossible de modifier les favoris');
    }
  }
  void toggleShowFavorites() {
    showFavorites.toggle();
  }


  // Méthode pour mettre à jour l'utilisateur courant
  Future<void> updateCurrentUser() async {
    try {
      if (currentUser.value?.id != null) {
        final updatedUser = await _firestoreService.getUserById(currentUser.value!.id);
        if (updatedUser != null) {
          currentUser.value = updatedUser;
        }
      }
    } catch (e) {
      print('Erreur lors de la mise à jour de l\'utilisateur: $e');
    }
  }

  void setAmount(double newAmount) {
    amount.value = newAmount;
  }

  void toggleFeePaymentMethod() {
    payFeesBySender.toggle();
  }

  void searchUserByPhone(String phone) async {
    if (phone.isEmpty) {
      receiverUser.value = null;
      phoneNumber.value = '';
      return;
    }

    try {
      final cleanedPhone = phone.replaceAll(RegExp(r'\D'), '');
      
      if (cleanedPhone.length < 8) {
        receiverUser.value = null;
        phoneNumber.value = '';
        return;
      }

      final user = await _firestoreService.getUserByPhone(cleanedPhone);
      
      if (user != null) {
        if (isMultipleTransferMode.value) {
          addMultipleReceiver(user);
        } else {
          receiverUser.value = user;
          phoneNumber.value = user.phoneNumber ?? '';
        }
      } else {
        // Si l'utilisateur n'existe pas dans la base de données,
        // chercher dans les contacts du téléphone
        final matchingContact = contactsList.firstWhereOrNull(
          (contact) => contact.contact.phones.any(
            (phone) => phone.number.replaceAll(RegExp(r'\D'), '').endsWith(cleanedPhone)
          )
        );

        if (matchingContact != null) {
          // Créer un nouvel utilisateur temporaire
          _showSuccessSnackbar(
            'Contact trouvé',
            'Ce numéro sera enregistré automatiquement lors du premier transfert'
          );
        } else {
          receiverUser.value = null;
          phoneNumber.value = '';
          _showErrorSnackbar('Recherche', 'Aucun utilisateur trouvé pour ce numéro.');
        }
      }
    } catch (e) {
      receiverUser.value = null;
      phoneNumber.value = '';
      _showErrorSnackbar('Erreur de recherche', 'Impossible de rechercher l\'utilisateur');
    }
  }

  void selectReceiver(ContactWithAvailability contact) {
    if (contact.dbUser != null) {
      if (isMultipleTransferMode.value) {
        addMultipleReceiver(contact.dbUser!);
      } else {
        receiverUser.value = contact.dbUser;
        phoneNumber.value = contact.dbUser?.phoneNumber ?? '';
      }
    } else {
      // Gérer le cas d'un contact qui n'est pas dans la base de données
      _showSuccessSnackbar(
        'Contact sélectionné',
        'Ce contact sera enregistré automatiquement lors du premier transfert'
      );
      phoneNumber.value = contact.contact.phones.first.number;
    }
  }

  void clearReceiver() {
    receiverUser.value = null;
    phoneNumber.value = '';
    multipleReceivers.clear();
  }

  void addMultipleReceiver(User user) {
    if (!multipleReceivers.contains(user)) {
      multipleReceivers.add(user);
    }
  }

  void removeMultipleReceiver(User user) {
    multipleReceivers.remove(user);
  }

  void toggleMultipleTransferMode() {
    isMultipleTransferMode.toggle();
    if (!isMultipleTransferMode.value) {
      multipleReceivers.clear();
    }
  }

 Future<void> performTransfer() async {
    if (currentUser.value == null) {
      _showErrorSnackbar('Erreur', 'Utilisateur non identifié');
      return;
    }

    final receivers = isMultipleTransferMode.value 
      ? multipleReceivers 
      : [receiverUser.value!];

    if (receivers.isEmpty || amount.value <= 0) {
      _showErrorSnackbar('Erreur', 'Montant invalide ou destinataire manquant');
      return;
    }

    for (var receiver in receivers) {
      if (receiver.id == currentUser.value!.id) {
        _showErrorSnackbar(
          'Erreur', 
          'Vous ne pouvez pas effectuer un transfert vers vous-même'
        );
        return;
      }
    }

    try {
      isLoading.value = true;

      final receiversCount = receivers.length;
      const feePercentage = 0.01; // 1% de frais

      // Calcul du montant et des frais selon qui paie
      double totalAmount;
      double amountPerReceiver;
      
      if (payFeesBySender.value) {
        // L'expéditeur paie les frais
        amountPerReceiver = amount.value; // Montant complet pour le destinataire
        double feesPerTransfer = amount.value * feePercentage;
        totalAmount = (amount.value + feesPerTransfer) * receiversCount;
      } else {
        // Le destinataire paie les frais
        amountPerReceiver = amount.value * (1 - feePercentage); // Montant réduit pour le destinataire
        totalAmount = amount.value * receiversCount; // Montant total débité de l'expéditeur
      }

      // Vérification du solde
      User sender = User.fromMap(currentUser.value!.toMap(), currentUser.value!.id);
      if (sender.balance < totalAmount) {
        _showErrorSnackbar('Solde insuffisant', 
          'Votre solde actuel est de ${sender.balance.toStringAsFixed(2)} FCFA. '
          'Le transfert nécessite ${totalAmount.toStringAsFixed(2)} FCFA.');
        return;
      }

      // Mise à jour du solde de l'expéditeur
      sender.balance = (sender.balance - totalAmount).clamp(0.0, double.infinity);

      List<custom.Transaction> transactions = [];

      // Traitement pour chaque destinataire
      for (var receiver in receivers) {
        User receiverUser = User.fromMap(receiver.toMap(), receiver.id);
        
        // Mise à jour du solde du destinataire avec le montant approprié
        receiverUser.balance += amountPerReceiver;

        // Création de la transaction
       final transaction = custom.Transaction(
  id: '${DateTime.now().millisecondsSinceEpoch}_${receivers.indexOf(receiver)}',
  senderId: sender.id,
  receiverId: receiverUser.id,
  amount: amountPerReceiver,
  type: custom.TransactionType.transfer,
  feesPaidBySender: payFeesBySender.value // Ajouter cette information
);
        transactions.add(transaction);

        // Mise à jour du destinataire dans la base de données
        await _firestoreService.updateUser(receiverUser.id, receiverUser.toMap());
      }

      // Sauvegarde des transactions et mise à jour de l'expéditeur
      for (var transaction in transactions) {
        await _firestoreService.addTransaction(transaction);
      }
      await _firestoreService.updateUser(sender.id, sender.toMap());

      // Mise à jour de l'utilisateur courant
      await updateCurrentUser();

      // Réinitialisation après le transfert
      _showSuccessSnackbar('Succès', 'Transfert effectué');
      clearReceiver();
      amount.value = 0.0;
      
      // Redirection vers la page d'accueil
      Get.offNamed('/home', arguments: currentUser.value);
      
    } catch (e) {
      _showErrorSnackbar('Erreur', 'Une erreur est survenue : ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  }

  void _showErrorSnackbar(String title, String message) {
    Get.snackbar(
      title, 
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 3)
    );
  }

  void _showSuccessSnackbar(String title, String message) {
    Get.snackbar(
      title, 
      message,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 3)
    );
  }


// Nouvelle classe pour combiner les contacts du téléphone avec les informations de disponibilité
class ContactWithAvailability {
  final Contact contact;
  final User? dbUser;
  final bool isAvailable;

  ContactWithAvailability({
    required this.contact,
    required this.dbUser,
    required this.isAvailable,
  });
}
