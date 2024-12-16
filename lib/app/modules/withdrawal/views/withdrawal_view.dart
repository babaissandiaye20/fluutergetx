// withdrawal_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../controllers/withdrawal_controller.dart';

class WithdrawalView extends GetView<WithdrawalController> {
  const WithdrawalView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Effectuer un retrait'),
        backgroundColor: const Color(0xFF2196F3),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.sender.value == null) {
          return Center(
            child: Text(
              controller.errorMessage.value.isNotEmpty
                  ? controller.errorMessage.value
                  : 'Chargement de l\'expéditeur...',
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Expéditeur',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1976D2),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${controller.sender.value!.firstName} ${controller.sender.value!.lastName}',
                        style: const TextStyle(fontSize: 18),
                      ),
                      Text(
                        controller.sender.value!.phoneNumber,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Montant du retrait',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1976D2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          IconButton(
                            onPressed: controller.decrementAmount,
                            icon: const Icon(Icons.remove_circle_outline),
                            color: const Color(0xFF1976D2),
                          ),
                          Expanded(
                            child: TextField(
                              controller: controller.amountTextController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: 'Entrez le montant',
                                suffixText: 'FCFA',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: controller.updateAmount,
                            ),
                          ),
                          IconButton(
                            onPressed: controller.incrementAmount,
                            icon: const Icon(Icons.add_circle_outline),
                            color: const Color(0xFF1976D2),
                          ),
                        ],
                      ),
                      if (controller.errorMessage.value.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            controller.errorMessage.value,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: controller.amount.value > 0
                    ? () => controller.processWithdrawal()
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const FaIcon(FontAwesomeIcons.moneyBillTransfer),
                label: const Text(
                  'Effectuer le retrait',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
