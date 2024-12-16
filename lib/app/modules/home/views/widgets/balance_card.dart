import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import '../../controllers/home_controller.dart';

class BalanceCard extends StatelessWidget {
  final HomeController controller = Get.find<HomeController>();

  BalanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Important to prevent overflow
          children: [
            const Text(
              'Solde disponible',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF1976D2),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Obx(() => Text(
                      controller.isSoldeVisible.value
                          ? '${controller.currentUser.value?.balance ?? 0} FCFA'
                          : '••••••',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1976D2),
                      ),
                    )),
                IconButton(
                  icon: const FaIcon(
                    FontAwesomeIcons.eye,
                    size: 20,
                  ),
                  onPressed: controller.toggleSoldeVisibility,
                  color: const Color(0xFF1976D2),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
