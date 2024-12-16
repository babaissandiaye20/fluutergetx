import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/scheduled_transfer_controller.dart';
import 'package:wave_mercredi/app/models/scheduledTransfer_model.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:wave_mercredi/app/models/user_model.dart';


class ScheduledTransferView extends GetView<ScheduledTransferController> {
  const ScheduledTransferView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planification de transfert'),
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
                    // Liste des transferts planifiés
                    if (controller.scheduledTransfers.isNotEmpty) ...[
                      Text(
                        'Transferts planifiés',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: controller.scheduledTransfers.length,
                        itemBuilder: (context, index) {
                          final transfer = controller.scheduledTransfers[index];
                          return FutureBuilder<User?>(
                            future: controller.getReceiverInfo(transfer.receiverId),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Card(
                                  child: ListTile(
                                    title: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              
                              final receiver = snapshot.data;
                              return Card(
                                child: ListTile(
                                  title: Text(
                                    receiver != null 
                                      ? '${receiver.firstName} ${receiver.lastName}'
                                      : 'Destinataire inconnu'
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Montant: ${transfer.amount} FCFA'),
                                      Text(
                                        'Date: ${DateFormat('dd/MM/yyyy HH:mm').format(transfer.executionDate)}'
                                      ),
                                      Text(
                                        'Fréquence: ${transfer.frequency.toString().split('.').last}'
                                      )
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => controller.deleteScheduledTransfer(transfer),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      const Divider(height: 30),
                    ],

                    // Reste du code inchangé...
                    Text(
                      controller.isMultipleTransferMode.value
                          ? 'Mode de planification multiple'
                          : 'Mode de planification simple',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    
                  const SizedBox(height: 20),

                    TextField(
                      onChanged: controller.searchUserByPhone,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                          labelText: 'Numéro de téléphone',
                          suffixIcon: const Icon(Icons.search),
                          hintText: controller.phoneNumber.value.isNotEmpty
                              ? controller.phoneNumber.value
                              : 'Rechercher un destinataire'),
                    ),
                    const SizedBox(height: 20),

                    SwitchListTile(
                      title: const Text('Afficher les favoris'),
                      value: controller.showFavorites.value,
                      onChanged: (_) => controller.toggleShowFavorites(),
                    ),

                    Text(
                      'Ou sélectionnez un contact',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: controller.showFavorites.value
                            ? controller.favoriteUsers.length
                            : controller.contactsList.length,
                        itemBuilder: (context, index) {
                          final contactWithAvailability =
                              controller.showFavorites.value
                                  ? ContactWithAvailability(
                                      contact: Contact(
                                        displayName:
                                            '${controller.favoriteUsers[index].firstName} ${controller.favoriteUsers[index].lastName}',
                                        phones: [
                                          Phone(controller.favoriteUsers[index]
                                                  .phoneNumber ??
                                              '')
                                        ],
                                      ),
                                      dbUser: controller.favoriteUsers[index],
                                      isAvailable: true,
                                    )
                                  : controller.contactsList[index];

                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: GestureDetector(
                              onTap: () => controller
                                  .selectReceiver(contactWithAvailability),
                              onLongPress:
                                  contactWithAvailability.dbUser != null
                                      ? () => controller.toggleFavorite(
                                          contactWithAvailability.dbUser!)
                                      : null,
                              child: Column(
                                children: [
                                  Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: 30,
                                        backgroundColor:
                                            contactWithAvailability.isAvailable
                                                ? const Color(0xFF2196F3)
                                                : Colors.grey,
                                        child: Text(
                                          contactWithAvailability
                                              .contact.displayName[0]
                                              .toUpperCase(),
                                          style: const TextStyle(
                                              color: Colors.white),
                                        ),
                                      ),
                                      if (contactWithAvailability.isAvailable)
                                        const Positioned(
                                          right: 0,
                                          bottom: 0,
                                          child: Icon(
                                            Icons.star,
                                            size: 16,
                                            color: Colors.amber,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    contactWithAvailability.contact.displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    contactWithAvailability.isAvailable
                                        ? 'Appui long pour favori'
                                        : 'Non inscrit',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: contactWithAvailability.isAvailable
                                          ? Colors.green
                                          : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    if (controller.isMultipleTransferMode.value &&
                        controller.multipleReceivers.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Destinataires sélectionnés',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          ...controller.multipleReceivers
                              .map((receiver) => Card(
                                    child: ListTile(
                                      title: Text(
                                          '${receiver.firstName} ${receiver.lastName}'),
                                      subtitle:
                                          Text(receiver.phoneNumber ?? ''),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.remove_circle),
                                        onPressed: () => controller
                                            .removeMultipleReceiver(receiver),
                                      ),
                                    ),
                                  ))
                              ,
                        ],
                      ),

                    if (!controller.isMultipleTransferMode.value &&
                        controller.receiverUser.value != null)
                      Card(
                        child: ListTile(
                          title: Text(
                              '${controller.receiverUser.value!.firstName} ${controller.receiverUser.value!.lastName}'),
                          subtitle: Text(
                              controller.receiverUser.value!.phoneNumber ?? ''),
                          trailing: IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: controller.clearReceiver,
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),

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

                    ListTile(
                      title: const Text('Date d\'exécution'),
                      subtitle: Text(DateFormat('dd/MM/yyyy HH:mm')
                          .format(controller.executionDate.value)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final now = DateTime.now();
                        final DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: now,
                          firstDate: now,
                          lastDate: now.add(const Duration(days: 365)),
                        );
                        if (pickedDate != null) {
                          final TimeOfDay? pickedTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(pickedDate
                                        .day ==
                                    now.day
                                ? now.add(const Duration(minutes: 5))
                                : DateTime(now.year, now.month, now.day, 9, 0)),
                          );
                          if (pickedTime != null) {
                            final selectedDateTime = DateTime(
                              pickedDate.year,
                              pickedDate.month,
                              pickedDate.day,
                              pickedTime.hour,
                              pickedTime.minute,
                            );

                            if (selectedDateTime.isBefore(now)) {
                              Get.snackbar(
                                'Erreur',
                                'Vous ne pouvez pas sélectionner une heure déjà passée',
                                backgroundColor: Colors.red,
                                colorText: Colors.white,
                              );
                            } else {
                              controller.setExecutionDate(selectedDateTime);
                            }
                          }
                        }
                      },
                    ),

                    const SizedBox(height: 20),

                    DropdownButtonFormField<TransferFrequency>(
                      value: controller.frequency.value,
                      decoration: const InputDecoration(
                        labelText: 'Fréquence',
                      ),
                      items: TransferFrequency.values.map((frequency) {
                        return DropdownMenuItem(
                          value: frequency,
                          child: Text(frequency.toString().split('.').last),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          controller.setFrequency(value);
                        }
                      },
                    ),

                    const SizedBox(height: 20),

                    SwitchListTile(
                      title: const Text('Payer les frais'),
                      subtitle: Text(controller.payFeesBySender.value
                          ? 'Les frais seront déduits de votre solde'
                          : 'Les frais seront déduits du montant envoyé'),
                      value: controller.payFeesBySender.value,
                      onChanged: (_) => controller.toggleFeePaymentMethod(),
                    ),

                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: ((controller.isMultipleTransferMode.value
                                  ? controller.multipleReceivers.isNotEmpty
                                  : controller.receiverUser.value != null) &&
                              controller.amount.value > 0)
                          ? controller.scheduleTransfer
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: Text(
                        controller.isMultipleTransferMode.value
                            ? 'Planifier les transferts'
                            : 'Planifier le transfert',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
              if (controller.isLoading.value)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Color(0x80FFFFFF),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2196F3),
                      ),
                    ),
                  ),
                ),
            ],
          )),
    );
  }
}