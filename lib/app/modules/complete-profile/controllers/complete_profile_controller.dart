import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wave_mercredi/app/services/firestore_services.dart';
import 'package:wave_mercredi/app/models/user_model.dart';

class CompleteProfileController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  final RxString selectedRole = RxString('');
  final RxBool isLoading = RxBool(false);

  void initializeUser(User user) {
    firstNameController.text = user.firstName;
    lastNameController.text = user.lastName;
    phoneController.text = user.phoneNumber;
  }

  Future<void> completeProfile(User user) async {
    if (selectedRole.value.isEmpty) {
      Get.snackbar('Erreur', 'Veuillez sélectionner un rôle');
      return;
    }

    isLoading.value = true;
    try {
      final updatedUser = User(
        id: user.id,
        firstName: firstNameController.text,
        lastName: lastNameController.text,
        email: user.email,
        phoneNumber: phoneController.text,
        role: selectedRole.value,
        displayName: '${firstNameController.text} ${lastNameController.text}',
        balance: user.balance,
      );

      await _firestoreService.setUser(updatedUser.id, updatedUser);
      Get.offAllNamed('/home', arguments: updatedUser);
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors de la mise à jour: $e');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    firstNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    super.onClose();
  }
}
