import 'package:get/get.dart';
import 'package:wave_mercredi/app/services/firestore_services.dart';
import 'package:wave_mercredi/app/models/user_model.dart';
import 'package:wave_mercredi/app/models/transaction_model.dart' as custom;

class HomeController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  final RxBool isSoldeVisible = true.obs;
  final RxList<TransactionDisplay> transactions = <TransactionDisplay>[].obs;
  final Rx<User?> currentUser = Rx<User?>(null);
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    currentUser.value = Get.arguments;
    loadTransactions();
  }

  void toggleSoldeVisibility() {
    isSoldeVisible.toggle();
  }

  Future<void> loadTransactions() async {
    if (currentUser.value == null) return;
    
    try {
      isLoading.value = true;
      
      // Récupérer toutes les transactions où l'utilisateur est impliqué
      final allTransactions = await _firestoreService.getTransactionsByUser(currentUser.value!.id);
      
      // Trier les transactions par date décroissante
      allTransactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      // Convertir les transactions en TransactionDisplay
      final displayTransactions = await Future.wait(
        allTransactions.map((transaction) async {
          String description = '';
          String amount = '';
          String otherUserName = '';
          
          // Récupérer les informations de l'autre utilisateur si nécessaire
          User? otherUser;
          if (transaction.type == custom.TransactionType.transfer || 
              transaction.type == custom.TransactionType.payment) {
            if (transaction.senderId == currentUser.value!.id) {
              otherUser = await _firestoreService.getUserById(transaction.receiverId);
            } else {
              otherUser = await _firestoreService.getUserById(transaction.senderId);
            }
          }

          switch (transaction.type) {
            case custom.TransactionType.transfer:
              if (transaction.senderId == currentUser.value!.id) {
                description = 'Transfert envoyé';
                amount = '- ${transaction.amount}';
                otherUserName = 'à ${otherUser?.firstName ?? 'Inconnu'} ${otherUser?.lastName ?? ''}';
              } else {
                description = 'Transfert reçu';
                amount = '+ ${transaction.amount}';
                otherUserName = 'de ${otherUser?.firstName ?? 'Inconnu'} ${otherUser?.lastName ?? ''}';
              }
              break;
              
            case custom.TransactionType.payment:
              if (transaction.senderId == currentUser.value!.id) {
                description = 'Paiement effectué';
                amount = '- ${transaction.amount}';
                otherUserName = 'à ${otherUser?.firstName ?? 'Inconnu'} ${otherUser?.lastName ?? ''}';
              } else {
                description = 'Paiement reçu';
                amount = '+ ${transaction.amount}';
                otherUserName = 'de ${otherUser?.firstName ?? 'Inconnu'} ${otherUser?.lastName ?? ''}';
              }
              break;
              
            case custom.TransactionType.deposit:
              description = 'Dépôt';
              amount = '+ ${transaction.amount}';
              break;
              
            case custom.TransactionType.withdrawal:
              description = 'Retrait';
              amount = '- ${transaction.amount}';
              break;
          }

          return TransactionDisplay(
            type: transaction.type,
            description: description,
            amount: amount,
            otherUserName: otherUserName,
            timestamp: transaction.timestamp,
            isPositive: amount.contains('+'),
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
}

class TransactionDisplay {
  final custom.TransactionType type;
  final String description;
  final String amount;
  final String otherUserName;
  final DateTime timestamp;
  final bool isPositive;

  TransactionDisplay({
    required this.type,
    required this.description,
    required this.amount,
    required this.otherUserName,
    required this.timestamp,
    required this.isPositive,
  });
}