import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../controllers/home_controller.dart';
import 'package:wave_mercredi/app/models/transaction_model.dart';

class RecentTransactionsList extends StatelessWidget {
  final HomeController controller = Get.find<HomeController>();
  final Function(BuildContext, TransactionDisplay) onCancelTransaction;

  RecentTransactionsList({
    super.key,
    required this.onCancelTransaction,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
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
                              color: transaction.status == 'cancelled'
                                  ? Colors.grey
                                  : Colors.black,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (transaction.otherUserName.isNotEmpty)
                                Text(
                                  transaction.otherUserName,
                                  style: TextStyle(
                                    color: transaction.status == 'cancelled'
                                        ? Colors.grey
                                        : null,
                                  ),
                                ),
                              Text(
                                DateFormat('dd/MM/yyyy HH:mm')
                                    .format(transaction.timestamp),
                                style: TextStyle(
                                  color: transaction.status == 'cancelled'
                                      ? Colors.grey
                                      : null,
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
                        : (transaction.isPositive
                            ? Colors.green
                            : const Color(0xFF1976D2)),
                  ),
                ),
                if (transaction.canCancel)
                  IconButton(
                    icon: const FaIcon(
                      FontAwesomeIcons.rotateLeft,
                      size: 18,
                    ),
                    onPressed: () => onCancelTransaction(context, transaction),
                    color: const Color(0xFF1976D2),
                  ),
              ],
            ),
          );
        },
      );
    });
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