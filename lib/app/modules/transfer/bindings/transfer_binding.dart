import 'package:get/get.dart';
import '../controllers/transfer_controller.dart';

class TransferBinding implements Bindings {
  @override
  void dependencies() {
    // Enregistrer le contrôleur
    Get.lazyPut<TransferController>(() => TransferController());
  }
}