import 'dart:async';
import 'package:get/get.dart';
import 'package:wave_mercredi/app/services/firestore_services.dart';
import 'package:wave_mercredi/app/models/user_model.dart';
import 'package:wave_mercredi/app/models/transaction_model.dart' as custom;
import 'package:flutter/material.dart';


class TransactionDisplay {
  final custom.TransactionType type;
  final String description;
  final String amount;
  final String otherUserName;
  final DateTime timestamp;
  final bool isPositive;
  final String status;
  final bool canCancel;

  TransactionDisplay({
    required this.type,
    required this.description,
    required this.amount,
    required this.otherUserName,
    required this.timestamp,
    required this.isPositive,
    this.status = 'completed',
    this.canCancel = false,
  });
}
class HomeController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  final RxBool isSoldeVisible = true.obs;
  final RxList<TransactionDisplay> transactions = <TransactionDisplay>[].obs;
  final Rx<User?> currentUser = Rx<User?>(null);
  final RxBool isLoading = false.obs;

  StreamSubscription? _userSubscription;
  StreamSubscription? _transactionSubscription;

  @override
  void onInit() {
    super.onInit();
    currentUser.value = Get.arguments;

    _initializeStreams();
    loadTransactions();
  }

  @override
  void onClose() {
    _userSubscription?.cancel();
    _transactionSubscription?.cancel();
    super.onClose();
  }

  void _initializeStreams() {
    if (currentUser.value?.id != null) {
      _userSubscription = _firestoreService
          .getUserStream(currentUser.value!.id)
          .listen((updatedUser) {
        if (updatedUser != null) {
          currentUser.value = updatedUser;
        }
      });

      _transactionSubscription = _firestoreService
          .getTransactionStreamByUser(currentUser.value!.id)
          .listen((_) {
        loadTransactions();
      });
    }
  }

  Future<void> refreshData() async {
    await updateCurrentUser();
    await loadTransactions();
  }

  Future<void> updateCurrentUser() async {
    try {
      if (currentUser.value?.id != null) {
        final updatedUser =
            await _firestoreService.getUserById(currentUser.value!.id);
        if (updatedUser != null) {
          currentUser.value = updatedUser;
        }
      }
    } catch (e) {
      print('Erreur lors de la mise à jour de l\'utilisateur: $e');
    }
  }

  void toggleSoldeVisibility() {
    isSoldeVisible.toggle();
  }

   Future<void> loadTransactions() async {
    if (currentUser.value == null) return;

    try {
      isLoading.value = true;

      final allTransactions =
          await _firestoreService.getTransactionsByUser(currentUser.value!.id);

      allTransactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      final displayTransactions = await Future.wait(
        allTransactions.map((transaction) async {
          String description = '';
          String amount = '';
          String otherUserName = '';
          bool canCancel = false;

          User? otherUser;
          if (transaction.type == custom.TransactionType.transfer ||
              transaction.type == custom.TransactionType.payment) {
            if (transaction.senderId == currentUser.value!.id) {
              otherUser =
                  await _firestoreService.getUserById(transaction.receiverId);
            } else {
              otherUser =
                  await _firestoreService.getUserById(transaction.senderId);
            }
          }

          canCancel = transaction.type == custom.TransactionType.transfer &&
              transaction.senderId == currentUser.value!.id &&
              DateTime.now().difference(transaction.timestamp).inMinutes <= 30 &&
              transaction.status != 'cancelled';

          switch (transaction.type) {
            case custom.TransactionType.transfer:
              if (transaction.status == 'cancelled') {
                description = 'Transaction annulée';
                amount = transaction.senderId == currentUser.value!.id
                    ? '- ${transaction.amount}'
                    : '+ ${transaction.amount}';
                otherUserName = transaction.senderId == currentUser.value!.id
                    ? 'à ${otherUser?.firstName ?? 'Inconnu'} ${otherUser?.lastName ?? ''}'
                    : 'de ${otherUser?.firstName ?? 'Inconnu'} ${otherUser?.lastName ?? ''}';
              } else {
                if (transaction.senderId == currentUser.value!.id) {
                  description = 'Transfert envoyé';
                  amount = '- ${transaction.amount}';
                  otherUserName =
                      'à ${otherUser?.firstName ?? 'Inconnu'} ${otherUser?.lastName ?? ''}';
                } else {
                  description = 'Transfert reçu';
                  amount = '+ ${transaction.amount}';
                  otherUserName =
                      'de ${otherUser?.firstName ?? 'Inconnu'} ${otherUser?.lastName ?? ''}';
                }
              }
              break;

            case custom.TransactionType.payment:
              if (transaction.senderId == currentUser.value!.id) {
                description = 'Paiement effectué';
                amount = '- ${transaction.amount}';
                otherUserName =
                    'à ${otherUser?.firstName ?? 'Inconnu'} ${otherUser?.lastName ?? ''}';
              } else {
                description = 'Paiement reçu';
                amount = '+ ${transaction.amount}';
                otherUserName =
                    'de ${otherUser?.firstName ?? 'Inconnu'} ${otherUser?.lastName ?? ''}';
              }
              break;

            case custom.TransactionType.deposit:
              description = 'Dépôt';
              amount = '+ ${transaction.amount}';
              otherUserName = '';
              break;

            case custom.TransactionType.withdrawal:
              description = 'Retrait';
              amount = '- ${transaction.amount}';
              otherUserName = '';
              break;
          }

          return TransactionDisplay(
            type: transaction.type,
            description: description,
            amount: amount,
            otherUserName: otherUserName,
            timestamp: transaction.timestamp,
            isPositive: amount.contains('+'),
            status: transaction.status,
            canCancel: canCancel,
          );
        }),
      );

      transactions.value = displayTransactions;
    } catch (e) {
      print('Erreur lors du chargement des transactions: $e');
    } finally {
      isLoading.value = false;
    }
  }
 Future<void> cancelTransfer(TransactionDisplay transaction) async {
  try {
    final allTransactions = 
        await _firestoreService.getTransactionsByUser(currentUser.value!.id);
    
    // Trouve la transaction à annuler
    final transactionToCancel = allTransactions.firstWhere(
      (t) => t.type == custom.TransactionType.transfer &&
          t.timestamp == transaction.timestamp &&
          t.status != 'cancelled'
    );

    // Récupérer les utilisateurs impliqués
    final sender = await _firestoreService.getUserById(transactionToCancel.senderId);
    final receiver = await _firestoreService.getUserById(transactionToCancel.receiverId);

    if (sender == null || receiver == null) {
      throw Exception('Utilisateur non trouvé');
    }

    // Constantes
    const feePercentage = 0.01; // 1%
    final originalAmount = transactionToCancel.amount;

    if (transactionToCancel.feesPaidBySender) {
      // Le sender récupère le montant + frais qu'il a payé
      final totalWithFees = originalAmount + (originalAmount * feePercentage);
      sender.balance += totalWithFees;
      // Le receiver perd le montant qu'il a reçu
      receiver.balance -= originalAmount;
    } else {
      // Le sender récupère le montant envoyé
      sender.balance += originalAmount;
      // Le receiver perd le montant reçu (déjà réduit des frais)
      receiver.balance -= (originalAmount * (1 - feePercentage));
    }

    // Mettre à jour le statut de la transaction
    await _firestoreService.cancelTransaction(transactionToCancel, currentUser.value!.id);
    
    // Mettre à jour les soldes des utilisateurs
    await _firestoreService.updateUser(sender.id, sender.toMap());
    await _firestoreService.updateUser(receiver.id, receiver.toMap());
    
    // Rafraîchir les données
    await refreshData();
    
    Get.snackbar(
      'Succès',
      'La transaction a été annulée avec succès',
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  } catch (e) {
    Get.snackbar(
      'Erreur',
      'Impossible d\'annuler la transaction: ${e.toString()}',
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }
}

  
}
