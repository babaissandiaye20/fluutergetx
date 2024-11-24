import 'package:get/get.dart';

import '../controllers/ceiling_controller.dart';

class CeilingBinding extends Bindings {
  @override
  void dependencies() {
  Get.lazyPut(() => CeilingController());
}
}
