import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import 'package:wave_mercredi/app/models/user_model.dart';
import 'package:intl/intl.dart';
import 'package:wave_mercredi/app/models/transaction_model.dart';

class HomeView extends StatelessWidget {
  HomeView({super.key});

  final HomeController controller = Get.put(HomeController());

  void _showQRModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Scanner pour payer',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1976D2),
                    ),
                  ),
                  IconButton(
                    icon: const FaIcon(FontAwesomeIcons.xmark),
                    onPressed: () => Navigator.pop(context),
                    color: const Color(0xFF1976D2),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: MediaQuery.of(context).size.width * 0.8,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 5,
                        blurRadius: 7,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const FaIcon(
                    FontAwesomeIcons.qrcode,
                    size: 250,
                    color: Color(0xFF1976D2),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'Présentez ce code à scanner',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1976D2),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Les autres utilisateurs peuvent scanner ce code pour effectuer un paiement',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelConfirmation(BuildContext context, TransactionDisplay transaction) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Annuler la transaction'),
          content: const Text(
            'Êtes-vous sûr de vouloir annuler cette transaction ? '
            'Cette action est irréversible.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Non'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                controller.cancelTransfer(transaction);
              },
              child: const Text('Oui'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2196F3),
        title: Obx(() => Text(
              controller.currentUser.value != null
                  ? 'Bonjour ${controller.currentUser.value?.firstName} ${controller.currentUser.value?.lastName}'
                  : 'Bonjour',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            )),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.rightFromBracket),
            onPressed: () => Get.offAllNamed('/login'),
            color: Colors.white,
          ),
        ],
        centerTitle: false,
        elevation: 0,
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => controller.refreshData(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text(
                            'Solde disponible',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF1976D2),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Obx(() => Text(
                                controller.isSoldeVisible.value
                                    ? '${controller.currentUser.value?.balance ?? 0} FCFA'
                                    : '••••••',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1976D2),
                                ),
                              )),
                          IconButton(
                            icon: const FaIcon(FontAwesomeIcons.eye),
                            onPressed: controller.toggleSoldeVisibility,
                            color: const Color(0xFF1976D2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 3,
                    mainAxisSpacing: 15,
                    crossAxisSpacing: 15,
                    childAspectRatio: 1.1,
                    children: [
                      ActionButton(
                        icon: FontAwesomeIcons.arrowDown,
                        label: 'Dépôt',
                        onPressed: () {},
                      ),
                      ActionButton(
                        icon: FontAwesomeIcons.arrowUp,
                        label: 'Retrait',
                        onPressed: () {},
                      ),
                      ActionButton(
                        icon: FontAwesomeIcons.moneyCheck,
                        label: 'Paiement',
                        onPressed: () {},
                      ),
                      ActionButton(
                        icon: FontAwesomeIcons.arrowsRotate,
                        label: 'Transfert',
                        onPressed: () => Get.toNamed('/transfer', arguments: controller.currentUser.value),
                      ),
                      ActionButton(
                        icon: FontAwesomeIcons.arrowTrendUp,
                        label: 'Déplafonnement',
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Transactions récentes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1976D2),
                    ),
                  ),
                  const SizedBox(height: 10),
                 Obx(() {
  if (controller.isLoading.value) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
  
  if (controller.transactions.isEmpty) {
    return const Center(
      child: Text(
        'Aucune transaction',
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey,
        ),
      ),
    );
  }

  return ListView.separated(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: controller.transactions.length,
    separatorBuilder: (context, index) => const Divider(),
    itemBuilder: (context, index) {
      final transaction = controller.transactions[index];

      return ListTile(
        leading: CircleAvatar(
          backgroundColor: transaction.status == 'cancelled' 
              ? Colors.grey[300]
              : const Color(0xFFBBDEFB),
          child: FaIcon(
            _getTransactionIcon(transaction),
            color: transaction.status == 'cancelled'
                ? Colors.grey
                : const Color(0xFF1976D2),
          ),
        ),
        title: Text(
          transaction.description,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: transaction.status == 'cancelled' ? Colors.grey : Colors.black,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (transaction.otherUserName.isNotEmpty)
              Text(
                transaction.otherUserName,
                style: TextStyle(
                  color: transaction.status == 'cancelled' ? Colors.grey : null,
                ),
              ),
            Text(
              DateFormat('dd/MM/yyyy HH:mm').format(transaction.timestamp),
              style: TextStyle(
                color: transaction.status == 'cancelled' ? Colors.grey : null,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${transaction.amount} FCFA',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: transaction.status == 'cancelled'
                    ? Colors.grey
                    : (transaction.isPositive ? Colors.green : const Color(0xFF1976D2)),
              ),
            ),
            if (transaction.canCancel)
              IconButton(
                icon: const FaIcon(
                  FontAwesomeIcons.rotateLeft,
                  size: 18,
                ),
                onPressed: () => _showCancelConfirmation(
                  context,
                  transaction,
                ),
                color: const Color(0xFF1976D2),
              ),
          ],
        ),
      );
    },
  );
})
                ],
              ),
            ),
          ),
           Positioned(
            right: 20,
            bottom: 110, // Ajuster la position du bouton QR code
            child: FloatingActionButton.large(
              onPressed: () => _showQRModal(context),
              backgroundColor: const Color(0xFF2196F3),
              child: const FaIcon(
                FontAwesomeIcons.qrcode,
                size: 40,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTransactionIcon(TransactionDisplay transaction) {
    switch (transaction.type) {
      case TransactionType.transfer:
        return transaction.isPositive
            ? FontAwesomeIcons.arrowDown
            : FontAwesomeIcons.arrowUp;
      case TransactionType.payment:
        return FontAwesomeIcons.moneyCheck;
      case TransactionType.deposit:
        return FontAwesomeIcons.arrowDown;
      case TransactionType.withdrawal:
        return FontAwesomeIcons.arrowUp;
      default:
        return FontAwesomeIcons.clockRotateLeft;
    }
  }
}

class ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              icon,
              size: 30,
              color: const Color(0xFF1976D2),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1976D2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}