import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wave_mercredi/app/services/firestore_services.dart';
import 'package:wave_mercredi/app/models/user_model.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wave_mercredi/app/models/scheduledTransfer_model.dart';
import 'package:wave_mercredi/app/models/transaction_model.dart' as custom;

class ScheduledTransferController extends GetxController {
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
  final Rx<DateTime> executionDate = Rx<DateTime>(DateTime.now());
  final Rx<TransferFrequency> frequency = Rx<TransferFrequency>(TransferFrequency.once);
  final Rx<User?> receiverUser = Rx<User?>(null);
  final RxString phoneNumber = RxString('');
   final RxList<ScheduledTransfer> scheduledTransfers = <ScheduledTransfer>[].obs;
    final Map<String, User> _receiversCache = {};
 void toggleFeePaymentMethod() {
    payFeesBySender.toggle();
  }

  // Ajout de la méthode setAmount
  void setAmount(double newAmount) {
    amount.value = newAmount;
  }
@override
void onInit() {
  super.onInit();
  currentUser.value = Get.arguments;
  loadAllContacts();
  _loadFavorites();
  _loadScheduledTransfers(); // Appel de la méthode
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

void _loadScheduledTransfers() { // Définition de la méthode
  if (currentUser.value?.id != null) {
    _firestoreService
        .getScheduledTransfersStream(currentUser.value!.id)
        .listen((transfers) {
      scheduledTransfers.value = transfers;
    });
  }
}

  Future<User?> getReceiverInfo(String receiverId) async {
    // Check cache first
    if (_receiversCache.containsKey(receiverId)) {
      return _receiversCache[receiverId];
    }

    try {
      // Fetch user from Firestore
      final user = await _firestoreService.getUserById(receiverId);
      if (user != null) {
        // Store in cache
        _receiversCache[receiverId] = user;
        return user;
      }
    } catch (e) {
      _showErrorSnackbar('Erreur', 'Impossible de récupérer les informations du destinataire');
    }
    return null;
  }

Future<void> deleteScheduledTransfer(ScheduledTransfer transfer) async {
  try {
    final bool? confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Confirmation'),
        content: const Text('Voulez-vous vraiment supprimer ce transfert planifié ?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      isLoading.value = true;
      
      // Passer l'ID complet du transfert
      print('ID du transfert à supprimer : ${transfer.id}');
      await _firestoreService.deleteScheduledTransfer(transfer.id);
      _showSuccessSnackbar('Succès', 'Transfert planifié supprimé avec succès');
    }
  } catch (e) {
    print('Erreur de suppression : $e');
    _showErrorSnackbar('Erreur', 'Impossible de supprimer le transfert planifié : $e');
  } finally {
    isLoading.value = false;
  }
}

  Future<void> loadAllContacts() async {
    try {
      if (!await FlutterContacts.requestPermission(readonly: true)) {
        _showErrorSnackbar('Erreur', 'Permission d\'accès aux contacts refusée');
        return;
      }

      isLoading.value = true;
      final phoneContacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );
      final dbUsers = await _firestoreService.getAllUsers();
      
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
        final matchingContact = contactsList.firstWhereOrNull(
          (contact) => contact.contact.phones.any(
            (phone) => phone.number.replaceAll(RegExp(r'\D'), '').endsWith(cleanedPhone)
          )
        );

        if (matchingContact != null) {
          _showSuccessSnackbar(
            'Contact trouvé',
            'Ce numéro sera enregistré automatiquement lors de la première planification'
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
      _showSuccessSnackbar(
        'Contact sélectionné',
        'Ce contact sera enregistré automatiquement lors de la première planification'
      );
      phoneNumber.value = contact.contact.phones.first.number;
    }
  }

  void toggleMultipleTransferMode() {
    isMultipleTransferMode.toggle();
    if (!isMultipleTransferMode.value) {
      multipleReceivers.clear();
    }
  }

  void addMultipleReceiver(User user) {
    if (!multipleReceivers.contains(user)) {
      multipleReceivers.add(user);
    }
  }

  void removeMultipleReceiver(User user) {
    multipleReceivers.remove(user);
  }

  void clearReceiver() {
    receiverUser.value = null;
    phoneNumber.value = '';
    multipleReceivers.clear();
  }

  void setExecutionDate(DateTime date) {
    executionDate.value = date;
  }

  void setFrequency(TransferFrequency newFrequency) {
    frequency.value = newFrequency;
  }

Future<void> scheduleTransfer() async {
    if (currentUser.value == null ||
        ((!isMultipleTransferMode.value && receiverUser.value == null) ||
        (isMultipleTransferMode.value && multipleReceivers.isEmpty)) ||
        amount.value <= 0) {
      _showErrorSnackbar('Erreur', 'Informations manquantes');
      return;
    }

    // Vérification de la date
    if (executionDate.value.isBefore(DateTime.now())) {
      _showErrorSnackbar('Erreur', 'La date d\'exécution ne peut pas être dans le passé');
      return;
    }

    try {
      isLoading.value = true;

      final receivers = isMultipleTransferMode.value 
        ? multipleReceivers 
        : [receiverUser.value!];

      // Calcul du montant total nécessaire
      const feePercentage = 0.01; // 1% de frais
      double totalAmount = 0;
      
      if (payFeesBySender.value) {
        double feesPerTransfer = amount.value * feePercentage;
        totalAmount = (amount.value + feesPerTransfer) * receivers.length;
      } else {
        totalAmount = amount.value * receivers.length;
      }

      // Vérification du solde
      if (currentUser.value!.balance < totalAmount) {
        _showErrorSnackbar(
          'Solde insuffisant', 
          'Votre solde actuel est de ${currentUser.value!.balance.toStringAsFixed(2)} FCFA. '
          'Le transfert nécessite ${totalAmount.toStringAsFixed(2)} FCFA.'
        );
        return;
      }

      for (var receiver in receivers) {
        final scheduledTransfer = ScheduledTransfer(
          id: '${DateTime.now().millisecondsSinceEpoch}_${receivers.indexOf(receiver)}',
          senderId: currentUser.value!.id,
          receiverId: receiver.id,
          amount: amount.value,
          executionDate: executionDate.value,
          frequency: frequency.value,
          feesPaidBySender: payFeesBySender.value,
        );
        
        final transaction = custom.Transaction(
          id: '${DateTime.now().millisecondsSinceEpoch}_${receivers.indexOf(receiver)}',
          senderId: currentUser.value!.id,
          receiverId: receiver.id,
          amount: amount.value,
          type: custom.TransactionType.transfer,
          timestamp: executionDate.value,
          status: 'scheduled',
          feesPaidBySender: payFeesBySender.value,
        );

        await _firestoreService.addScheduledTransfer(scheduledTransfer);
        await _firestoreService.addTransaction(transaction);
      }

      clearReceiver();
      amount.value = 0.0;
      executionDate.value = DateTime.now();
      frequency.value = TransferFrequency.once;
      
      _showSuccessSnackbar('Succès', 'Transfert planifié avec succès');
    } catch (e) {
      _showErrorSnackbar('Erreur', 'Impossible de planifier le(s) transfert(s): $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _showErrorSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  void _showSuccessSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }
}

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