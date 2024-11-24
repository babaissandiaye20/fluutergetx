import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:wave_mercredi/app/models/transaction_model.dart';
import 'package:wave_mercredi/app/models/user_model.dart';
import 'package:wave_mercredi/app/services/firestore_services.dart';
import 'package:uuid/uuid.dart';
import 'package:fluttertoast/fluttertoast.dart';

class WithdrawalController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  final amount = 0.0.obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final Rx<User?> sender = Rx<User?>(null);
  final Rx<User?> receiver = Rx<User?>(null);
  
  final TextEditingController amountTextController = TextEditingController();
  
  static const double stepAmount = 1000.0;
  static const double minAmount = 0.0;
  static const double maxAmount = 1000000.0;

  late final String senderId;
  late final String receiverId;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>;
    senderId = args['senderPhone'];  // From QR code
    receiverId = args['receiverId']; // Connected user
    
    amountTextController.text = amount.value.toString();
    
    ever(amount, (double value) {
      if (value >= 0 && amountTextController.text != value.toString()) {
        amountTextController.text = value.toString();
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
      final senderData = await _firestoreService.getUserByPhone(senderId);
      final receiverData = await _firestoreService.getUserById(receiverId);
      
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

  Future<void> processWithdrawal() async {
    if (sender.value == null || receiver.value == null) {
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
      // Créer la transaction
      final transaction = Transaction(
        id: const Uuid().v4(),
        senderId: sender.value!.id,
        receiverId: receiverId,
        amount: amount.value,
        type: TransactionType.withdrawal,
        timestamp: DateTime.now(),
        feesPaidBySender: true,
      );

      // Calculer les nouveaux soldes
      final updatedSenderBalance = sender.value!.balance - amount.value;
      final updatedReceiverBalance = receiver.value!.balance + amount.value;

      // Mettre à jour les soldes des utilisateurs
      await _firestoreService.updateUser(
        sender.value!.id,
        {'balance': updatedSenderBalance},
      );
      await _firestoreService.updateUser(
        receiverId,
        {'balance': updatedReceiverBalance},
      );
      
      // Ajouter la transaction dans Firestore
      await _firestoreService.addTransaction(transaction);
      
      // Afficher le message de succès
      Fluttertoast.showToast(
        msg: "Retrait effectué avec succès!",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0
      );

      // Récupérer l'utilisateur mis à jour
      final updatedUser = await _firestoreService.getUserById(receiverId);
      
      // Rediriger vers la page d'accueil avec l'utilisateur mis à jour
      Get.offNamed('/home', arguments: updatedUser);
      
    } catch (e) {
      errorMessage('Erreur lors du retrait: $e');
      Fluttertoast.showToast(
        msg: "Erreur lors du retrait: $e",
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