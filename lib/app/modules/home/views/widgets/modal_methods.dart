// 3. modal_methods.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../controllers/home_controller.dart';
class ModalMethods {
  static void showQRModal(BuildContext context, HomeController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Scanner pour payer',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1976D2),
                    ),
                  ),
                  IconButton(
                    icon: const FaIcon(FontAwesomeIcons.xmark),
                    onPressed: () => Navigator.pop(context),
                    color: const Color(0xFF1976D2),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: MediaQuery.of(context).size.width * 0.8,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 5,
                        blurRadius: 7,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: controller.currentUser.value != null
                      ? QrImageView(
                          data: controller.currentUser.value!.phoneNumber,
                          version: QrVersions.auto,
                          size: 250,
                        )
                      : const FaIcon(
                          FontAwesomeIcons.qrcode,
                          size: 250,
                          color: Color(0xFF1976D2),
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'Présentez ce code à scanner',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1976D2),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Les autres utilisateurs peuvent scanner ce code pour effectuer un paiement',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void showScanner(BuildContext context, HomeController controller, String type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    type == 'deposit'
                        ? 'Scanner pour dépôt'
                        : 'Scanner pour retrait',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1976D2),
                    ),
                  ),
                  IconButton(
                    icon: const FaIcon(FontAwesomeIcons.xmark),
                    onPressed: () => Navigator.pop(context),
                    color: const Color(0xFF1976D2),
                  ),
                ],
              ),
            ),
            Expanded(
              child: MobileScanner(
                controller: MobileScannerController(
                  detectionSpeed: DetectionSpeed.normal,
                  facing: CameraFacing.back,
                ),
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  for (final barcode in barcodes) {
                    debugPrint('Barcode found: ${barcode.rawValue}');

                    // Ajout de la condition pour le dépôt
                    if (type == 'deposit' && barcode.rawValue != null) {
                      Navigator.pop(context);
                      Get.toNamed('/deposit', arguments: {
                        'senderId': controller.currentUser.value!.id,
                        'receiverPhone': barcode.rawValue
                      });
                    }
                    // Condition pour le retrait (à adapter selon vos besoins)
                    else if (type == 'withdrawal' && barcode.rawValue != null) {
                      Navigator.pop(context);
                      Get.toNamed('/withdrawal', arguments: {
                        'senderPhone': barcode.rawValue,
                        'receiverId': controller.currentUser.value!.id
                      });
                    } else if (type == 'ceiling' && barcode.rawValue != null) {
                      Navigator.pop(context);
                      Get.toNamed('/ceiling-update',
                          arguments: {'targetPhone': barcode.rawValue});
                    }
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                type == 'deposit'
                    ? 'Scannez le code QR pour effectuer un dépôt'
                    : 'Scannez le code QR pour effectuer un retrait',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  static void showCancelConfirmation(BuildContext context, HomeController controller, TransactionDisplay transaction) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Annuler la transaction'),
          content: const Text(
            'Êtes-vous sûr de vouloir annuler cette transaction ? '
            'Cette action est irréversible.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Non'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                controller.cancelTransfer(transaction);
              },
              child: const Text('Oui'),
            ),
          ],
        );
      },
    );
  }
}
