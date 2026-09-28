import 'package:flutter/material.dart';

class IndispoCompo {
  static void show({
    required BuildContext context,
    String title = 'Indisponible',
    String message = 'Cette fonctionnalité est indisponible pour le moment',
    IconData icon = Icons.network_check,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        icon: Icon(icon, color: Colors.red, size: 60),
        title: Text(title, textAlign: TextAlign.center),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
