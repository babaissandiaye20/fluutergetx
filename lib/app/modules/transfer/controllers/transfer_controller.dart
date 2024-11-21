import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wave_mercredi/app/services/firestore_services.dart';
import 'package:wave_mercredi/app/models/user_model.dart';
import 'package:wave_mercredi/app/models/transaction_model.dart' as custom;

class TransferController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();

  final Rx<User?> currentUser = Rx<User?>(null);
  final RxList<User> multipleReceivers = <User>[].obs;
  final RxList<User> contactsList = <User>[].obs;
  final RxBool payFeesBySender = true.obs;
  final RxDouble amount = RxDouble(0.0);
  final RxBool isLoading = false.obs;
  final RxBool isMultipleTransferMode = false.obs;
  final RxString phoneNumber = RxString('');
  final Rx<User?> receiverUser = Rx<User?>(null);

  @override
  void onInit() {
    super.onInit();
    currentUser.value = Get.arguments;
    loadContacts();
  }

  void loadContacts() async {
    try {
      final users = await _firestoreService.getAllUsers();
      contactsList.value = users.where((user) => 
        user.id != currentUser.value?.id && 
        user.phoneNumber != null && 
        user.phoneNumber!.isNotEmpty
      ).toList();
    } catch (e) {
      _showErrorSnackbar('Erreur de chargement des contacts', e.toString());
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
      
      if (user != null && user.phoneNumber != null) {
        if (isMultipleTransferMode.value) {
          addMultipleReceiver(user);
        } else {
          receiverUser.value = user;
          phoneNumber.value = user.phoneNumber ?? '';
        }
      } else {
        receiverUser.value = null;
        phoneNumber.value = '';
        if (phone.isNotEmpty) {
          _showErrorSnackbar('Recherche', 'Aucun utilisateur trouvé pour ce numéro.');
        }
      }
    } catch (e) {
      receiverUser.value = null;
      phoneNumber.value = '';
      _showErrorSnackbar('Erreur de recherche', 'Impossible de rechercher l\'utilisateur');
    }
  }

  void selectReceiver(User user) {
    if (isMultipleTransferMode.value) {
      addMultipleReceiver(user);
    } else {
      receiverUser.value = user;
      phoneNumber.value = user.phoneNumber ?? '';
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

    try {
      isLoading.value = true;

      final receiversCount = receivers.length;

      // Calculate total amount with fees
      double totalAmount;
      double amountPerReceiver;
      
      if (payFeesBySender.value) {
        // Full amount to each receiver, plus 1% fee on total
        amountPerReceiver = amount.value;
        totalAmount = amount.value * receiversCount + (amount.value * receiversCount * 0.01);
      } else {
        // Slightly reduced amount per receiver to account for fees
        amountPerReceiver = amount.value;
        totalAmount = amount.value * receiversCount;
      }

      // Strict balance check
      User sender = User.fromMap(currentUser.value!.toMap(), currentUser.value!.id);
      if (sender.balance < totalAmount) {
        _showErrorSnackbar('Solde insuffisant', 
          'Votre solde actuel est de ${sender.balance.toStringAsFixed(2)} FCFA. '
          'Le transfert nécessite ${totalAmount.toStringAsFixed(2)} FCFA.');
        return;
      }

      // Update sender's balance
      sender.balance = (sender.balance - totalAmount).clamp(0.0, double.infinity);

      List<custom.Transaction> transactions = [];

      // Process each receiver
      for (var receiver in receivers) {
        User receiverUser = User.fromMap(receiver.toMap(), receiver.id);
        
        // Update receiver's balance with full amount
        receiverUser.balance += amountPerReceiver;

        // Create transaction
        final transaction = custom.Transaction(
          id: DateTime.now().millisecondsSinceEpoch.toString() + '_${receivers.indexOf(receiver)}',
          senderId: sender.id,
          receiverId: receiverUser.id,
          amount: amountPerReceiver,
          type: custom.TransactionType.transfer
        );

        transactions.add(transaction);

        // Update receiver in database
        await _firestoreService.updateUser(receiverUser.id, receiverUser.toMap());
      }

      // Save transactions and update sender
      for (var transaction in transactions) {
        await _firestoreService.addTransaction(transaction);
      }
      await _firestoreService.updateUser(sender.id, sender.toMap());

      // Reset after transfer
      _showSuccessSnackbar('Succès', 'Transfert effectué');
      clearReceiver();
      amount.value = 0.0;
      
    } catch (e) {
      _showErrorSnackbar('Erreur', 'Une erreur est survenue : ${e.toString()}');
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
}