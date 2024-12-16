import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../controllers/home_controller.dart';
import './modal_methods.dart';

class QRCodeCard extends StatelessWidget {
  final HomeController controller = Get.find<HomeController>();

  QRCodeCard({super.key});

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
              'Mon QR Code',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF1976D2),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => ModalMethods.showQRModal(context, controller),
              child: Container(
                width: 100, // Slightly increased size
                height: 100, // Slightly increased size
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade100, width: 2),
                ),
                child: Obx(() => 
                  controller.currentUser.value != null
                    ? QrImageView(
                        data: controller.currentUser.value!.phoneNumber,
                        version: QrVersions.auto,
                        size: 80, // Adjusted size
                      )
                    : const Center(
                        child: FaIcon(
                          FontAwesomeIcons.qrcode,
                          size: 50,
                          color: Color(0xFF1976D2),
                        ),
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}