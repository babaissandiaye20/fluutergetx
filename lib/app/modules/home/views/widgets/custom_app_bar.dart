import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import '../../controllers/home_controller.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final HomeController controller;

  const CustomAppBar({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF2196F3),
      title: Obx(() => Text(
            controller.currentUser.value != null
                ? 'Bonjour ${controller.currentUser.value?.firstName} ${controller.currentUser.value?.lastName}'
                : 'Bonjour',
            style: const TextStyle(color: Colors.white, fontSize: 18),
          )),
      actions: [
        IconButton(
          icon: const FaIcon(FontAwesomeIcons.rightFromBracket),
          onPressed: () => Get.offAllNamed('/login'),
          color: Colors.white,
        ),
      ],
      centerTitle: false,
      elevation: 0,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}