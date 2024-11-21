import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/transfer_controller.dart';

class TransferView extends GetView<TransferController> {
  const TransferView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfert'),
        backgroundColor: const Color(0xFF2196F3),
        actions: [
          Obx(() => Switch(
            value: controller.isMultipleTransferMode.value,
            onChanged: (_) => controller.toggleMultipleTransferMode(),
            activeColor: Colors.white,
          ))
        ],
      ),
      body: Obx(() => Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Ajout de widgets de débogage
                Obx(() => Column(
                  children: [
                    Text('Receiver: ${controller.receiverUser.value?.firstName ?? "Aucun"}'),
                    Text('Multiple Receivers: ${controller.multipleReceivers.length}'),
                    Text('Phone Number: ${controller.phoneNumber.value}'),
                  ],
                )),

                // Mode de transfert
                Text(
                  controller.isMultipleTransferMode.value 
                    ? 'Mode de transfert multiple' 
                    : 'Mode de transfert simple',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Champ de recherche par numéro
                TextField(
                  onChanged: controller.searchUserByPhone,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Numéro de téléphone',
                    suffixIcon: const Icon(Icons.search),
                    hintText: controller.phoneNumber.value.isNotEmpty 
                      ? controller.phoneNumber.value 
                      : 'Rechercher un destinataire'
                  ),
                ),
                const SizedBox(height: 20),
                
                // Liste de contacts
                Text(
                  'Ou sélectionnez un contact',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: controller.contactsList.length,
                    itemBuilder: (context, index) {
                      final contact = controller.contactsList[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: GestureDetector(
                          onTap: () => controller.selectReceiver(contact),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: const Color(0xFF2196F3),
                                child: Text(
                                  contact.firstName[0].toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(contact.firstName),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // Destinataires multiples
                if (controller.isMultipleTransferMode.value && 
                    controller.multipleReceivers.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Destinataires sélectionnés',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      ...controller.multipleReceivers.map((receiver) => Card(
                        child: ListTile(
                          title: Text('${receiver.firstName} ${receiver.lastName}'),
                          subtitle: Text(receiver.phoneNumber),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle),
                            onPressed: () => controller.removeMultipleReceiver(receiver),
                          ),
                        ),
                      )).toList(),
                    ],
                  ),

                // Destinataire unique
                if (!controller.isMultipleTransferMode.value && 
                    controller.receiverUser.value != null)
                  Card(
                    child: ListTile(
                      title: Text('${controller.receiverUser.value!.firstName} ${controller.receiverUser.value!.lastName}'),
                      subtitle: Text(controller.receiverUser.value!.phoneNumber),
                      trailing: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: controller.clearReceiver,
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                // Champ de montant
                TextField(
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final amount = double.tryParse(value) ?? 0.0;
                    controller.setAmount(amount);
                  },
                  decoration: const InputDecoration(
                    labelText: 'Montant',
                    suffixText: 'FCFA',
                  ),
                ),

                const SizedBox(height: 20),

                // Option de paiement des frais
                SwitchListTile(
                  title: const Text('Payer les frais'),
                  subtitle: const Text('Le montant des frais sera déduit de votre solde'),
                  value: controller.payFeesBySender.value,
                  onChanged: (_) => controller.toggleFeePaymentMethod(),
                ),

                const SizedBox(height: 20),

                // Bouton de transfert
                ElevatedButton(
                  onPressed: (
                    (controller.isMultipleTransferMode.value 
                      ? controller.multipleReceivers.isNotEmpty 
                      : controller.receiverUser.value != null) 
                    && controller.amount.value > 0
                  ) 
                    ? controller.performTransfer 
                    : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: Text(
                    controller.isMultipleTransferMode.value 
                      ? 'Effectuer le transfert multiple' 
                      : 'Effectuer le transfert',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),

          // Indicateur de chargement
          if (controller.isLoading.value)
            const Positioned.fill(
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF2196F3),
                ),
              ),
            ),
        ],
      )),
    );
  }
}