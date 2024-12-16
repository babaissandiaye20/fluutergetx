import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class QRCodeButton extends StatelessWidget {
  final VoidCallback onPressed;

  const QRCodeButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.large(
      onPressed: onPressed,
      backgroundColor: const Color(0xFF2196F3),
      child: const FaIcon(
        FontAwesomeIcons.qrcode,
        size: 40,
        color: Colors.white,
      ),
    );
  }
}