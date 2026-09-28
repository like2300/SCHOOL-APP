import 'package:flutter/material.dart';
import 'package:estim_campus/services/auth_service.dart';
import 'package:estim_campus/compos/app_scaffold.dart';
import 'package:estim_campus/compos/phone_field.dart';

/// Connexion par fiche d'inscription : matricule + n° téléphone.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _matriculeCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _dialCode = '+242';
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _matriculeCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await AuthService.login(
      matricule: _matriculeCtrl.text,
      // Indicatif du sélecteur + national : pas besoin de taper le 242.
      phone: '$_dialCode${_phoneCtrl.text.replaceAll(RegExp(r'\D'), '')}',
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (res['ok'] == true) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      setState(() => _error = (res['error'] ?? 'Connexion impossible.').toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppScaffold(
      selectedIndex: -1,
      appBar: AppBar(
        title: const Text('Connexion', style: TextStyle(fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.school_rounded, size: 64, color: colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Connecte-toi avec ta fiche',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Entre ton ID étudiant (sur ta fiche d\'inscription) et ton numéro de téléphone. Ton inscription doit être validée par ton établissement. Tu ne recevras ensuite que les notifications liées à ta fiche.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _matriculeCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'ID étudiant',
                      hintText: 'Ex : 1EAXBEVC (sur ta fiche)',
                      prefixIcon: Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'ID étudiant requis' : null,
                  ),
                  const SizedBox(height: 16),
                  PhoneField(
                    controller: _phoneCtrl,
                    initialDialCode: _dialCode,
                    onDialCodeChanged: (v) => _dialCode = v,
                    hintText: 'Ex : 06 123 45 67 (sans indicatif)',
                    validator: (v) =>
                        (v == null || v.replaceAll(RegExp(r'\D'), '').isEmpty)
                            ? 'Téléphone requis'
                            : null,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _error!,
                        style: TextStyle(color: colorScheme.onErrorContainer),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _loading ? null : _submit,
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.login_rounded),
                    label: Text(_loading ? 'Vérification...' : 'Se connecter'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _loading ? null : () => _showGuestDialog(context),
                    icon: const Icon(Icons.person_outline_rounded),
                    label: const Text('Continuer en invité'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showGuestDialog(BuildContext context) async {
    final navigator = Navigator.of(context);
    final nomCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String guestDial = '+242';
    final formKey = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
        title: const Text('Mode invité'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Découvre l\u2019appli sans fiche : indique juste ton nom et ton numéro.',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: nomCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nom',
                  hintText: 'Ex : Omer Elenga',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
              ),
              const SizedBox(height: 12),
              PhoneField(
                controller: phoneCtrl,
                initialDialCode: guestDial,
                onDialCodeChanged: (v) => setDialogState(() => guestDial = v),
                hintText: 'Ex : 06 123 45 67 (sans indicatif)',
                validator: (v) =>
                    (v == null || v.replaceAll(RegExp(r'\D'), '').isEmpty)
                        ? 'Téléphone requis'
                        : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Continuer'),
          ),
        ],
        ),
      ),
    );
    if (ok == true) {
      await AuthService.loginGuest(
        nom: nomCtrl.text,
        phone: '$guestDial${phoneCtrl.text.replaceAll(RegExp(r'\D'), '')}',
      );
      navigator.pushReplacementNamed('/home');
    }
    nomCtrl.dispose();
    phoneCtrl.dispose();
  }
}
