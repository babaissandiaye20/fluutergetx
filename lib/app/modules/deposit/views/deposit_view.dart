import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../controllers/deposit_controller.dart';

class DepositView extends GetView<DepositController> {
  const DepositView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DepositController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Effectuer un dépôt'),
        backgroundColor: const Color(0xFF2196F3),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.receiver.value == null) {
          return Center(
            child: Text(
              controller.errorMessage.value.isNotEmpty
                  ? controller.errorMessage.value
                  : 'Chargement du destinataire...',
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
                        'Destinataire',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1976D2),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${controller.receiver.value!.firstName} ${controller.receiver.value!.lastName}',
                        style: const TextStyle(fontSize: 18),
                      ),
                      Text(
                        controller.receiver.value!.phoneNumber,
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
                        'Montant du dépôt',
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
                    ? () => controller.processDeposit()
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const FaIcon(FontAwesomeIcons.moneyBillTransfer),
                label: const Text(
                  'Effectuer le dépôt',
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
