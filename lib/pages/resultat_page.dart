import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../models/session_examen.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:estim_campus/compos/app_scaffold.dart';

class ResultatPage extends StatefulWidget {
  const ResultatPage({super.key});

  @override
  State<ResultatPage> createState() => _ResultatPageState();
}

class _ResultatPageState extends State<ResultatPage>
    with WidgetsBindingObserver {
  List<SessionExamen> _availableSessions = [];
  SessionExamen? _selectedSession;
  String _currentMatricule = '';
  String? _anonymousId;

  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _resultData;
  String? _unavailableMessage;
  bool _searched = false;
  bool _requiresPayment = false;
  int? _paymentAmount;
  bool _waitingForPayment = false;
  String? _currentPaymentUrl;
  int? _pendingSessionId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    String? savedMatricule = StorageService.getString('user_matricule');
    if (savedMatricule != null && savedMatricule.isNotEmpty) {
      _controller.text = savedMatricule;
      _currentMatricule = savedMatricule;
    }

    _anonymousId = StorageService.getString('anonymous_id');
    if (_anonymousId == null) {
      final int timestamp = DateTime.now().millisecondsSinceEpoch;
      final String randomSuffix =
          (timestamp % 10000).toString().padLeft(4, '0');
      _anonymousId = "ANONYMOUS_$randomSuffix";
      StorageService.setString('anonymous_id', _anonymousId!);
    }

    final String? pendingMatricule =
        StorageService.getString('pending_payment_matricule');
    final String? pendingSessionId =
        StorageService.getString('pending_payment_session_id');

    if (pendingMatricule != null && pendingMatricule.isNotEmpty) {
      _controller.text = pendingMatricule;
      _currentMatricule = pendingMatricule;
      if (pendingSessionId != null) {
        _pendingSessionId = int.tryParse(pendingSessionId);
      }
      StorageService.removeData('pending_payment_matricule');
      StorageService.removeData('pending_payment_session_id');
    }

    _fetchSessions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _waitingForPayment) {
      _checkPaymentStatus();
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _waitingForPayment) _checkPaymentStatus();
      });
      Future.delayed(const Duration(seconds: 7), () {
        if (mounted && _waitingForPayment) _checkPaymentStatus();
      });
    }
  }

  Future<void> _checkPaymentStatus() async {
    if (_controller.text.isNotEmpty && _selectedSession != null) {
      setState(() => _isLoading = true);
      await _fetchResultat(_controller.text, _selectedSession!.id);

      if (mounted) {
        if (!_requiresPayment && _resultData != null) {
          if (_waitingForPayment) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text("Paiement validé ! Voici les résultats.")
                ]),
                backgroundColor: Theme.of(context).colorScheme.secondary,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            );
            final String? savedMatricule =
                StorageService.getString('user_matricule');
            if (savedMatricule == null || savedMatricule.isEmpty) {
              _showSaveMatriculeDialog(_controller.text);
            }
          }
          setState(() {
            _waitingForPayment = false;
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
          if (_waitingForPayment && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                    "Paiement non encore détecté. Veuillez patienter ou réessayer."),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    }
  }

  void _showSaveMatriculeDialog(String matricule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Enregistrer ce matricule ?"),
        content: Text(
            "Voulez-vous enregistrer le matricule $matricule comme étant le vôtre ?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("PLUS TARD")),
          FilledButton(
            onPressed: () {
              StorageService.setString('user_matricule', matricule);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Matricule enregistré !")),
              );
            },
            child: const Text("ENREGISTRER"),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchSessions() async {
    setState(() => _isLoading = true);
    final sessionsData = await ApiService.getSessions();
    _availableSessions =
        sessionsData.map((s) => SessionExamen.fromJson(s)).toList();

    if (_availableSessions.isNotEmpty) {
      setState(() {
        if (_pendingSessionId != null) {
          try {
            _selectedSession =
                _availableSessions.firstWhere((s) => s.id == _pendingSessionId);
          } catch (e) {
            _selectedSession = _availableSessions.first;
          }
          _pendingSessionId = null;
        } else {
          _selectedSession = _availableSessions.first;
        }
        _isLoading = false;
        if (_currentMatricule.isNotEmpty && _selectedSession != null)
          _fetchResultat(_currentMatricule, _selectedSession!.id);
      });
    } else {
      setState(() {
        _selectedSession = null;
        _isLoading = false;
        // Ne pas mettre _searched à true si aucune session n'est disponible
        // _searched = true;
      });
    }
  }

  Future<void> _fetchResultat(String matricule, int sessionId) async {
    if (matricule.isEmpty) return;
    setState(() {
      _isLoading = true;
      _searched = true;
      _unavailableMessage = null;
      _resultData = null;
      _requiresPayment = false;
    });

    try {
      final response = await ApiService.getResultat(matricule, sessionId);
      setState(() {
        _isLoading = false;
        if (response != null) {
          if (response['requires_payment'] == true) {
            _requiresPayment = true;
            _paymentAmount = response['amount'];
          } else if (response['available'] == true) {
            _resultData = response['data'];
            _requiresPayment = false;
          } else {
            _unavailableMessage = response['error'] ??
                response['message'] ??
                "Résultat introuvable.";
          }
        } else {
          _unavailableMessage = "Erreur lors de la récupération des données.";
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _unavailableMessage = "Une erreur est survenue.";
      });
    }
  }

  Future<void> _handlePayment() async {
    if (_selectedSession == null) return;
    setState(() => _isLoading = true);
    final payData = await ApiService.createPaymentLink(
        _controller.text, _selectedSession!.id);
    setState(() => _isLoading = false);

    if (payData != null && payData['payment_url'] != null) {
      if (!mounted) return;
      setState(() {
        _waitingForPayment = true;
        _currentPaymentUrl = payData['payment_url'];
      });
      StorageService.setString('pending_payment_matricule', _controller.text);
      if (_selectedSession != null)
        StorageService.setString(
            'pending_payment_session_id', _selectedSession!.id.toString());
      _showPaymentWebView(payData['payment_url']);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(payData?['error'] ?? "Erreur de paiement"),
          backgroundColor: Colors.red));
    }
  }

  void _showPaymentWebView(String url) {
    final colorScheme = Theme.of(context).colorScheme;
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(onPageStarted: (String url) {
        if (url.contains('payment-success')) {
          Navigator.pop(context);
          _checkPaymentStatus();
        }
      }))
      ..loadRequest(Uri.parse(url));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(children: [
          const SizedBox(height: 12),
          Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10))),
          Padding(
              padding: const EdgeInsets.all(16),
              child: Text("Paiement Sécurisé",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface))),
          Expanded(child: WebViewWidget(controller: controller)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppScaffold(
      selectedIndex: -1,
      appBar: AppBar(
        title: const Text('Mes Résultats',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
              icon: Icon(Icons.refresh_rounded,
                  color: colorScheme.onSurfaceVariant),
              onPressed: () {
                _fetchSessions();
                if (_currentMatricule.isNotEmpty && _selectedSession != null)
                  _fetchResultat(_currentMatricule, _selectedSession!.id);
              }),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600), // PARFAIT POUR PC
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text("Consultez vos résultats d'examen",
                    style: TextStyle(
                        fontSize: 16, color: colorScheme.onSurfaceVariant)),
                const SizedBox(height: 24),

                // CHAMP MATRICULE
                Container(
                  decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16)),
                  child: Row(children: [
                    Expanded(
                        child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                          hintText: "Entrez votre matricule",
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16)),
                      onChanged: (value) => _currentMatricule = value,
                      onSubmitted: (value) {
                        if (_selectedSession != null)
                          _fetchResultat(value, _selectedSession!.id);
                      },
                    )),
                    IconButton(
                        icon: Icon(Icons.search_rounded,
                            color: colorScheme.primary),
                        onPressed: () {
                          if (_selectedSession != null)
                            _fetchResultat(
                                _controller.text, _selectedSession!.id);
                        }),
                  ]),
                ),
                const SizedBox(height: 16),

                // SELECTEUR SESSION
                DropdownButtonFormField<SessionExamen>(
                  value: _selectedSession,
                  decoration: InputDecoration(
                    hintText: _availableSessions.isEmpty
                        ? 'Aucune session disponible'
                        : 'Sélectionnez une session',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  items: _availableSessions
                      .map(
                          (s) => DropdownMenuItem(value: s, child: Text(s.nom)))
                      .toList(),
                  onChanged: _availableSessions.isEmpty
                      ? null
                      : (v) {
                          setState(() {
                            _selectedSession = v;
                            if (_currentMatricule.isNotEmpty && v != null)
                              _fetchResultat(_currentMatricule, v.id);
                          });
                        },
                ),

                // Ne pas afficher "Aucune session disponible" si aucune session n'est disponible
                // if (_availableSessions.isEmpty && !_isLoading && _searched)
                //   Padding(
                //       padding: const EdgeInsets.symmetric(vertical: 40),
                //       child: Text("Aucune session disponible.",
                //           textAlign: TextAlign.center,
                //           style: TextStyle(color: colorScheme.outline))),

                const SizedBox(height: 32),

                if (_isLoading)
                  Center(
                      child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: CircularProgressIndicator(
                              color: colorScheme.primary)))
                else if (_searched)
                  _buildMainContent(colorScheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(ColorScheme colorScheme) {
    if (_requiresPayment)
      return _buildPaymentView(colorScheme);
    else if (_unavailableMessage != null)
      return _buildErrorState(
          title: "Résultats non disponibles",
          message: _unavailableMessage!,
          icon: Icons.info_outline_rounded,
          colorScheme: colorScheme);
    else if (_resultData != null)
      return _resultData!['admis'] == true
          ? _buildSuccessView(colorScheme)
          : _buildFailedView(colorScheme);
    else
      return _buildErrorState(
          title: "Prêt",
          message: "Entrez votre matricule et sélectionnez une session.",
          icon: Icons.search_rounded,
          colorScheme: colorScheme);
  }

  Widget _buildPaymentView(ColorScheme colorScheme) {
    final bool hasMatricule =
        StorageService.getString('user_matricule') != null;
    if (_waitingForPayment) {
      return Column(children: [
        const SizedBox(height: 60),
        TweenAnimationBuilder(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(seconds: 1),
          curve: Curves.elasticOut,
          builder: (context, double val, child) =>
              Transform.scale(scale: val, child: child),
          child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  shape: BoxShape.circle, color: colorScheme.primaryContainer),
              child: Icon(Icons.hourglass_top_rounded,
                  size: 60, color: colorScheme.primary)),
        ),
        const SizedBox(height: 30),
        Text("En attente de validation...",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Text("Le résultat s'affichera dès que le paiement est confirmé.",
            textAlign: TextAlign.center,
            style: TextStyle(color: colorScheme.onSurfaceVariant)),
        const SizedBox(height: 30),
        if (_currentPaymentUrl != null)
          FilledButton.tonal(
              onPressed: () async {
                if (await canLaunchUrl(Uri.parse(_currentPaymentUrl!)))
                  await launchUrl(Uri.parse(_currentPaymentUrl!),
                      mode: LaunchMode.externalApplication);
              },
              child: const Text("Ouvrir le lien de paiement")),
        const SizedBox(height: 12),
        OutlinedButton(
            onPressed: _checkPaymentStatus,
            child: const Text("Vérifier maintenant")),
      ]);
    }

    return Column(children: [
      const SizedBox(height: 60),
      Icon(hasMatricule ? Icons.lock_outline_rounded : Icons.person_off_rounded,
          size: 80, color: colorScheme.onSurfaceVariant),
      const SizedBox(height: 20),
      Text(hasMatricule ? "Consultation payante" : "Profil incomplet",
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 10),
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
              hasMatricule
                  ? "Frais de ${_paymentAmount ?? 100} XAF requis pour consulter ce résultat."
                  : "Configurez votre profil pour continuer.",
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant))),
      const SizedBox(height: 30),
      FilledButton(
          onPressed: hasMatricule
              ? _handlePayment
              : () => Navigator.pushReplacementNamed(context, '/settings'),
          style: FilledButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
          child: Text(
              hasMatricule ? "PAYER MAINTENANT" : "CONFIGURER MON PROFIL")),
    ]);
  }

  // --- LA VUE CRÉATIVE ET ANIMÉE DES RÉSULTATS ---
  Widget _buildSuccessView(ColorScheme colorScheme) {
    Map<String, dynamic> notes = _resultData!['details_notes'] ?? {};
    double moyenne = double.tryParse(_resultData!['moyenne'].toString()) ?? 0.0;

    return Column(children: [
      // Animation du texte de félicitations
      TweenAnimationBuilder(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutBack,
        builder: (context, double val, child) => Opacity(
            opacity: val, child: Transform.scale(scale: val, child: child)),
        child: Column(children: [
          Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  shape: BoxShape.circle, color: colorScheme.primaryContainer),
              child: Icon(Icons.emoji_events_rounded,
                  size: 50, color: colorScheme.primary)),
          const SizedBox(height: 16),
          Text("FÉLICITATIONS !",
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: colorScheme.primary,
                  letterSpacing: 1)),
          Text("Session ${_selectedSession?.nom ?? ''}",
              style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
      const SizedBox(height: 40),

      // CERCLE DE MOYENNE ANIMÉ
      TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: moyenne / 20.0),
        duration: const Duration(seconds: 2),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return SizedBox(
            width: 160,
            height: 160,
            child: Stack(fit: StackFit.expand, children: [
              CircularProgressIndicator(
                  value: value,
                  strokeWidth: 12,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(moyenne >= 10
                      ? colorScheme.secondary
                      : colorScheme.error)),
              Center(
                  child: Text("${moyenne.toStringAsFixed(2)}",
                      style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: moyenne >= 10
                              ? colorScheme.secondary
                              : colorScheme.error))),
            ]),
          );
        },
      ),
      const SizedBox(height: 8),
      Text("MOYENNE GÉNÉRALE",
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurfaceVariant,
              letterSpacing: 2)),
      const SizedBox(height: 30),

      // CARTES DES NOTES AVEC BARRES DE PROGRESSION
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border:
                Border.all(color: colorScheme.outlineVariant.withOpacity(0.5))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                  "${_resultData!['nom_etudiant'] ?? ''} (${_resultData!['matricule']})",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface))),
          if (notes.isNotEmpty)
            ...notes.entries.map((e) {
              double noteVal = double.tryParse(e.value.toString()) ?? 0;
              return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                  child: Text(e.key,
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: colorScheme.onSurface))),
                              Text("${e.value}/20",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: noteVal >= 10
                                          ? colorScheme.secondary
                                          : colorScheme.error))
                            ]),
                        const SizedBox(height: 8),
                        TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: noteVal / 20.0),
                            duration: Duration(
                                milliseconds: 800 +
                                    notes.keys.toList().indexOf(e.key) * 200),
                            curve: Curves.easeOut,
                            builder: (context, value, child) =>
                                LinearProgressIndicator(
                                    value: value,
                                    minHeight: 6,
                                    backgroundColor:
                                        colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(3),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        noteVal >= 10
                                            ? colorScheme.secondary
                                            : colorScheme.error))),
                      ]));
            }).toList()
          else
            Text("Détails non disponibles.",
                style: TextStyle(color: colorScheme.outline)),
        ]),
      ),
    ]);
  }

  Widget _buildFailedView(ColorScheme colorScheme) {
    return _buildErrorState(
      title: "Session non validée",
      message:
          "Vous n'avez pas atteint la moyenne requise pour la session ${_selectedSession?.nom ?? ''}. Contactez votre établissement.",
      icon: Icons.sentiment_dissatisfied_rounded,
      colorScheme: colorScheme,
    );
  }

  Widget _buildErrorState(
      {required String title,
      required String message,
      required IconData icon,
      required ColorScheme colorScheme}) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(children: [
        Icon(icon, size: 80, color: colorScheme.outlineVariant),
        const SizedBox(height: 20),
        Text(title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Text(message,
            textAlign: TextAlign.center,
            style: TextStyle(color: colorScheme.onSurfaceVariant, height: 1.5)),
      ]),
    );
  }
}
