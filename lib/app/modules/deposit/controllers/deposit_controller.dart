import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:wave_mercredi/app/models/user_model.dart';
import 'package:wave_mercredi/app/models/transaction_model.dart';
import 'package:wave_mercredi/app/services/firestore_services.dart';
import 'package:uuid/uuid.dart';
import 'package:fluttertoast/fluttertoast.dart';

class DepositController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  final amount = 0.0.obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final Rx<User?> sender = Rx<User?>(null);
  final Rx<User?> receiver = Rx<User?>(null);
  
  // Ajout du TextEditingController
  final TextEditingController amountTextController = TextEditingController();
  
  // Constantes pour l'incrémentation/décrémentation
  static const double stepAmount = 1000.0;
  static const double minAmount = 0.0;
  static const double maxAmount = 1000000.0;

  late final String senderId;
  late final String receiverPhone;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>;
    senderId = args['senderId'];
    receiverPhone = args['receiverPhone'];
    
    // Initialiser le TextEditingController
    amountTextController.text = amount.value.toString();
    
    // Écouter les changements de amount pour mettre à jour le TextField
    ever(amount, (double value) {
      if (value >= 0) {
        if (amountTextController.text != value.toString()) {
          amountTextController.text = value.toString();
        }
      }
    });
    
    _loadUsers();
  }

  @override
  void onClose() {
    amountTextController.dispose();
    super.onClose();
  }

  Future<void> _loadUsers() async {
    isLoading(true);
    try {
      final senderData = await _firestoreService.getUserById(senderId);
      final receiverData = await _firestoreService.getUserByPhone(receiverPhone);
      
      if (senderData == null || receiverData == null) {
        errorMessage('Utilisateur non trouvé');
        return;
      }
      sender.value = senderData;
      receiver.value = receiverData;
    } catch (e) {
      errorMessage('Erreur lors du chargement: $e');
    } finally {
      isLoading(false);
    }
  }

  void incrementAmount() {
    if (amount.value + stepAmount <= maxAmount) {
      if (sender.value != null && amount.value + stepAmount <= sender.value!.balance) {
        amount(amount.value + stepAmount);
        errorMessage('');
      } else {
        errorMessage('Solde insuffisant');
      }
    } else {
      errorMessage('Montant maximum atteint');
    }
  }

  void decrementAmount() {
    if (amount.value - stepAmount >= minAmount) {
      amount(amount.value - stepAmount);
      errorMessage('');
    } else {
      errorMessage('Montant minimum atteint');
    }
  }

  void updateAmount(String value) {
    if (value.isEmpty) {
      amount(0.0);
      errorMessage('');
      return;
    }

    try {
      final newAmount = double.parse(value);
      if (newAmount < minAmount) {
        errorMessage('Le montant doit être supérieur à 0');
        return;
      }
      if (newAmount > maxAmount) {
        errorMessage('Montant maximum dépassé');
        return;
      }
      if (sender.value != null && newAmount > sender.value!.balance) {
        errorMessage('Solde insuffisant');
        return;
      }
      amount(newAmount);
      errorMessage('');
    } catch (e) {
      errorMessage('Montant invalide');
    }
  }

  Future<void> processDeposit() async {
    if (receiver.value == null || sender.value == null) {
      errorMessage('Utilisateurs non trouvés');
      return;
    }
    if (amount <= 0) {
      errorMessage('Montant invalide');
      return;
    }
    if (amount.value > sender.value!.balance) {
      errorMessage('Solde insuffisant');
      return;
    }

    isLoading(true);
    try {
      final transaction = Transaction(
        id: const Uuid().v4(),
        senderId: senderId,
        receiverId: receiver.value!.id,
        amount: amount.value,
        type: TransactionType.deposit,
        timestamp: DateTime.now(),
        feesPaidBySender: true,
      );

      final updatedSenderBalance = sender.value!.balance - amount.value;
      final updatedReceiverBalance = receiver.value!.balance + amount.value;

      await _firestoreService.updateUser(
        sender.value!.id,
        {'balance': updatedSenderBalance},
      );
      await _firestoreService.updateUser(
        receiver.value!.id,
        {'balance': updatedReceiverBalance},
      );
      
      await _firestoreService.addTransaction(transaction);
      
      Fluttertoast.showToast(
        msg: "Dépôt effectué avec succès!",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0
      );

      final updatedSender = await _firestoreService.getUserById(senderId);
      Get.offNamed('/home', arguments: updatedSender);
      
    } catch (e) {
      errorMessage('Erreur lors du dépôt: $e');
      Fluttertoast.showToast(
        msg: "Erreur lors du dépôt: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0
      );
    } finally {
      isLoading(false);
    }
  }
}