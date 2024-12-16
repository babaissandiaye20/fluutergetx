import 'package:get/get.dart';

import '../controllers/scheduled_transfer_controller.dart';

class ScheduledTransferBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ScheduledTransferController>(
      () => ScheduledTransferController(),
    );
  }
}
