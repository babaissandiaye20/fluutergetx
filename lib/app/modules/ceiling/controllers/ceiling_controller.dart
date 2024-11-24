import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:wave_mercredi/app/models/user_model.dart';
import 'package:wave_mercredi/app/services/firestore_services.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CeilingController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final Rx<User?> targetUser = Rx<User?>(null);
  
  late final String targetPhone;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>;
    targetPhone = args['targetPhone'];
    _loadUser();
  }

  Future<void> _loadUser() async {
    isLoading(true);
    try {
      final userData = await _firestoreService.getUserByPhone(targetPhone);
      
      if (userData == null) {
        errorMessage('Utilisateur non trouvé');
        return;
      }
      targetUser.value = userData;
    } catch (e) {
      errorMessage('Erreur lors du chargement: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<void> processCeilingUpdate() async {
    if (targetUser.value == null) {
      errorMessage('Utilisateur non trouvé');
      return;
    }

    isLoading(true);
    try {
      // Calculer les nouvelles limites (x2.5)
      final newMaxBalance = targetUser.value!.maxBalance * 2.5;
      final newMonthlyLimit = targetUser.value!.monthlyTransactionLimit * 2.5;

      // Mettre à jour dans Firestore
      await _firestoreService.updateUser(
        targetUser.value!.id,
        {
          'maxBalance': newMaxBalance,
          'monthlyTransactionLimit': newMonthlyLimit,
        },
      );
      
      Fluttertoast.showToast(
        msg: "Déplafonnement effectué avec succès!",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0
      );

      Get.back();
      
    } catch (e) {
      errorMessage('Erreur lors du déplafonnement: $e');
      Fluttertoast.showToast(
        msg: "Erreur lors du déplafonnement: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0
      );
    } finally {
      isLoading(false);
    }
  }
}