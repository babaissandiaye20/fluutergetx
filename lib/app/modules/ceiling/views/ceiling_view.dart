import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/ceiling_controller.dart';

class CeilingView extends GetView<CeilingController> {
  const CeilingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Déplafonnement'),
        backgroundColor: const Color(0xFF1976D2),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final user = controller.targetUser.value;
        if (user == null) {
          return const Center(child: Text('Utilisateur non trouvé'));
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Utilisateur: ${user.firstName} ${user.lastName}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Téléphone: ${user.phoneNumber}'),
                      Text('Rôle: ${user.role}'),
                      const Divider(),
                      const Text(
                        'Limites actuelles:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Solde maximum: ${user.maxBalance.toStringAsFixed(2)} FCFA',
                      ),
                      Text(
                        'Limite mensuelle: ${user.monthlyTransactionLimit.toStringAsFixed(2)} FCFA',
                      ),
                      const Divider(),
                      const Text(
                        'Nouvelles limites (x2.5):',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Nouveau solde maximum: ${(user.maxBalance * 2.5).toStringAsFixed(2)} FCFA',
                      ),
                      Text(
                        'Nouvelle limite mensuelle: ${(user.monthlyTransactionLimit * 2.5).toStringAsFixed(2)} FCFA',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (controller.errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    controller.errorMessage.value,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              ElevatedButton(
                onPressed: controller.processCeilingUpdate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Confirmer le déplafonnement',
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