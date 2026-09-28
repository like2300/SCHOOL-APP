import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import 'package:estim_campus/compos/app_scaffold.dart';

class PaymentSuccessPage extends StatefulWidget {
  const PaymentSuccessPage({super.key});

  @override
  State<PaymentSuccessPage> createState() => _PaymentSuccessPageState();
}

class _PaymentSuccessPageState extends State<PaymentSuccessPage> {
  @override
  void initState() {
    super.initState();
    // On peut imaginer un délai avant redirection automatique
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _handleRedirection();
      }
    });
  }

  void _handleRedirection() {
    final pendingMatricule = StorageService.getString('pending_payment_matricule');
    final pendingInscription = StorageService.getString('pending_payment_inscription_id');

    if (pendingMatricule != null) {
      Navigator.pushReplacementNamed(context, '/resultats');
    } else if (pendingInscription != null) {
      Navigator.pushReplacementNamed(context, '/verify');
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      selectedIndex: -1,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.green, size: 100),
            const SizedBox(height: 24),
            const Text(
              "Paiement Réussi !",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              "Votre transaction a été validée avec succès.\nVous allez être redirigé automatiquement.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _handleRedirection,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text("CONTINUER", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
