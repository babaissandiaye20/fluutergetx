// 2. action_buttons_grid.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import '../../controllers/home_controller.dart';
import 'action_button.dart';

class ActionButtonsGrid extends StatelessWidget {
  final HomeController controller;
  final Function(BuildContext, String) showScanner;

  const ActionButtonsGrid({
    Key? key, 
    required this.controller, 
    required this.showScanner
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final currentUser = controller.currentUser.value;

      return GridView.count(
        shrinkWrap: true,
        crossAxisCount: 3,
        mainAxisSpacing: 15,
        crossAxisSpacing: 15,
        childAspectRatio: 1.1,
        children: [
          // Buttons for agents and admins
          if (currentUser != null &&
              ['agent', 'admin'].contains(currentUser.role)) ...[
            ActionButton(
              icon: FontAwesomeIcons.arrowDown,
              label: 'Dépôt',
              onPressed: () => showScanner(context, 'deposit'),
            ),
            ActionButton(
              icon: FontAwesomeIcons.arrowUp,
              label: 'Retrait',
              onPressed: () => showScanner(context, 'withdrawal'),
            ),
            ActionButton(
              icon: FontAwesomeIcons.moneyCheck,
              label: 'Paiement',
              onPressed: () {},
            ),
            ActionButton(
              icon: FontAwesomeIcons.arrowsRotate,
              label: 'Transfert',
              onPressed: () => Get.toNamed('/transfer', arguments: currentUser),
            ),
            ActionButton(
              icon: FontAwesomeIcons.clock,
              label: 'Planifier Transfert',
              onPressed: () => Get.toNamed('/scheduled-transfer', arguments: currentUser),
            ),
            ActionButton(
              icon: FontAwesomeIcons.arrowTrendUp,
              label: 'Déplafonnement',
              onPressed: () => showScanner(context, 'ceiling'),
            ),
          ],

          // Buttons for other roles
          if (currentUser != null &&
              !['agent', 'admin'].contains(currentUser.role)) ...[
            ActionButton(
              icon: FontAwesomeIcons.moneyCheck,
              label: 'Paiement',
              onPressed: () {},
            ),
            ActionButton(
              icon: FontAwesomeIcons.arrowsRotate,
              label: 'Transfert',
              onPressed: () => Get.toNamed('/transfer', arguments: currentUser),
            ),
            ActionButton(
              icon: FontAwesomeIcons.clock,
              label: 'Planifier Transfert',
              onPressed: () => Get.toNamed('/scheduled-transfer', arguments: currentUser),
            ),
          ],
        ],
      );
    });
  }
}