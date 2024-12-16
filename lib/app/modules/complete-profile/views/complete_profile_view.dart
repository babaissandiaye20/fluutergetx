import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../controllers/complete_profile_controller.dart';
import 'package:wave_mercredi/app/models/user_model.dart';

class CompleteProfileView extends StatelessWidget {
  final User user;
  final CompleteProfileController controller = Get.put(CompleteProfileController());

  CompleteProfileView({super.key, required this.user}) {
    controller.initializeUser(user);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compléter votre profil'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Center(
                child: Icon(FontAwesomeIcons.userCircle, size: 100, color: Colors.blue),
              ),
              const SizedBox(height: 30),
              TextFormField(
                controller: controller.firstNameController,
                decoration: const InputDecoration(
                  labelText: 'Prénom',
                  prefixIcon: FaIcon(FontAwesomeIcons.user),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre prénom';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: controller.lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Nom',
                  prefixIcon: FaIcon(FontAwesomeIcons.userAlt),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre nom';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: controller.phoneController,
                decoration: const InputDecoration(
                  labelText: 'Numéro de téléphone',
                  prefixIcon: FaIcon(FontAwesomeIcons.phone),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre numéro de téléphone';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Obx(() => DropdownButtonFormField<String>(
                    value: controller.selectedRole.value.isEmpty ? null : controller.selectedRole.value,
                    decoration: const InputDecoration(
                      labelText: 'Rôle',
                      prefixIcon: FaIcon(FontAwesomeIcons.briefcase),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'client', child: Text('Client')),
                      DropdownMenuItem(value: 'agent', child: Text('Agent')),
                      DropdownMenuItem(value: 'marchand', child: Text('Marchand')),
                    ],
                    onChanged: (value) {
                      controller.selectedRole.value = value!;
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez sélectionner un rôle';
                      }
                      return null;
                    },
                  )),
              const SizedBox(height: 30),
              Obx(() => ElevatedButton(
                    onPressed: controller.isLoading.value ? null : () => controller.completeProfile(user),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: controller.isLoading.value
                        ? const CircularProgressIndicator()
                        : const Text(
                            'Finaliser mon profil',
                            style: TextStyle(fontSize: 18),
                          ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}