import 'dart:convert';
import 'dart:io'; // Ajouté pour la détection internet
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:estim_campus/services/api_service.dart';
import 'package:estim_campus/services/storage_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  String _systemPrompt =
      'Tu es un assistant académique. Sois concis et adapte ton langage à la filière de l\u2019étudiant.';
  String _contextInfo = '';

  // TODO: Attention, il est dangereux de laisser une clé API en dur dans le code source côté client.
  final String _apiKey = const String.fromEnvironment('GROQ_API_KEY');
  String? _matricule;

  bool _isBlockedByExam = false;
  String _blockedMessage = "";
  bool _isGuest = false;
  String _assistantNom = 'Assistant';
  String _assistantPersonnalite = '';

  @override
  void initState() {
    super.initState();
    _checkAccessAndLoadData();
  }

  /// Vérifie si le téléphone est connecté à internet
  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
      return false;
    } on SocketException catch (_) {
      return false;
    }
  }

  /// Affiche un message d'erreur si pas de réseau
  void _showNoInternetSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.white),
            SizedBox(width: 12),
            Text('Aucune connexion internet. Vérifiez votre réseau.'),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _checkExamBlocking(dynamic contextData) async {
    final now = DateTime.now();
    final hour = now.hour;

    if (hour >= 6 && hour < 22) {
      final String calendar = contextData['calendrier'] ?? "";
      final String todayStr = "${now.day}/${now.month}";

      if (calendar.contains(todayStr) &&
          (calendar.contains("Examen") ||
              calendar.contains("Devoir") ||
              calendar.contains("Composition"))) {
        setState(() {
          _isBlockedByExam = true;
          _blockedMessage =
              "L'Assistant est désactivé aujourd'hui car vous avez un examen ou un devoir prévu. Sécurité académique activée. Réouverture à 22h00.";
        });
      }
    }
  }

  void _checkAccessAndLoadData() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Nom + personnalité depuis /admin/ (Assistant IA), jamais en dur.
      try {
        final assistant = await ApiService.getAssistant();
        if (mounted && assistant != null) {
          setState(() {
            _assistantNom =
                (assistant['nom'] ?? 'Assistant').toString();
            _assistantPersonnalite =
                (assistant['personnalite'] ?? '').toString();
          });
        }
      } catch (_) {}
      _matricule = StorageService.getString('user_matricule');
      if (_matricule == null || _matricule!.isEmpty) {
        setState(() {
          _isGuest = true;
        });
        _loadPromptAndContext();
      } else {
        setState(() => _isGuest = false);
        _loadPromptAndContext();
        _loadChatHistory();
      }
    });
  }

  void _loadChatHistory() {
    if (_matricule == null) return;
    final String key = 'chat_history_$_matricule';
    final dynamic savedHistory = StorageService.getData(key);
    if (savedHistory != null && savedHistory is List) {
      setState(() {
        _messages = List<Map<String, String>>.from(
            savedHistory.map((item) => Map<String, String>.from(item)));
      });
      _scrollToBottom();
    }
  }

  void _saveChatHistory() {
    if (_matricule == null) return;
    final String key = 'chat_history_$_matricule';
    final historyToSave = _messages.length > 20
        ? _messages.sublist(_messages.length - 20)
        : _messages;
    StorageService.saveData(key, historyToSave);
  }

  Future<void> _loadPromptAndContext() async {
    final etablissement =
        StorageService.getString('user_etab') ?? "Non spécifié";
    final niveau = StorageService.getString('user_niveau') ?? "Non spécifié";
    final filiere = StorageService.getString('user_filiere') ?? "Non spécifié";
    final nom = StorageService.getString('user_nom') ?? "";
    final prenom = StorageService.getString('user_prenom') ?? "";

    final prompt = await ApiService.getChatbotPrompt();
    final contextData = await ApiService.getChatbotContext(
      etablissement: etablissement,
      niveau: niveau,
      filiere: filiere,
    );

    await _checkExamBlocking(contextData);

    String info = "\n\nPROFIL ÉTUDIANT:\n";
    if (nom.isNotEmpty || prenom.isNotEmpty) info += "Nom: $prenom $nom\n";
    info += "Filière: $filiere\n";
    info += "Niveau: $niveau\n";
    info += "Établissement: $etablissement\n";
    info += "Matricule: ${_matricule ?? 'Invité'}\n\n";

    info += "INFOS ÉTABLISSEMENT:\n";
    info += "Site Web: ${contextData['school_website']}\n";
    info += "Téléphone: ${contextData['school_phone']}\n";
    info += "WhatsApp: ${contextData['school_whatsapp']}\n";
    info += "Lien Téléchargement App: ${contextData['app_download_url']}\n\n";

    info += "CONTEXTE ESTIM:\n";
    info += "Annonces: ${contextData['annonces']}\n";
    info += "Cours d'aujourd'hui: ${contextData['cours']}\n";

    if (mounted) {
      setState(() {
        final base = _assistantPersonnalite.isNotEmpty
            ? _assistantPersonnalite
            : prompt;
        if (_isGuest) {
          _systemPrompt =
              "Tu es $_assistantNom en mode 'Invité'. $base Sois très accueillant et proactif : présente l'école et aide l'utilisateur à comprendre l'application (inscription, notes, etc.).";
        } else {
          _systemPrompt = "$base Tu t'adresses à un étudiant en $filiere ($niveau). Utilise son profil pour personnaliser tes conseils.";
        }
        _contextInfo = info;
      });
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    // 1. VÉRIFICATION INTERNET
    final hasInternet = await _checkInternetConnection();
    if (!hasInternet) {
      _showNoInternetSnackbar();
      return;
    }

    final userMessage = _controller.text.trim();
    setState(() {
      _messages.add({'role': 'user', 'content': userMessage});
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final response = await http
          .post(
            Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
            headers: {
              'Authorization': 'Bearer $_apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': 'llama-3.3-70b-versatile',
              'messages': [
                {'role': 'system', 'content': _systemPrompt + _contextInfo},
                ..._messages.length > 8
                    ? _messages.sublist(_messages.length - 8)
                    : _messages,
              ],
              'temperature': 0.6,
            }),
          )
          .timeout(const Duration(seconds: 30)); // Timeout de sécurité

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final botMessage = data['choices'][0]['message']['content'];
        setState(() {
          _messages.add({'role': 'assistant', 'content': botMessage});
        });
        _scrollToBottom();
        _saveChatHistory();
      } else {
        // Gestion d'erreur API (clé invalide, limite atteinte, etc.)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur API: ${response.statusCode}'),
              backgroundColor: Colors.orangeAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Le serveur met trop de temps à répondre. Réessayez.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: colorScheme.surface.withOpacity(0.8)),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary, // Jaune ESTIM
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.auto_awesome,
                  color: colorScheme.onPrimary, size: 18),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_assistantNom,
                    style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 18)),
                Text('En ligne',
                    style: TextStyle(
                        color: colorScheme.secondary, fontSize: 12)), // Vert
              ],
            ),
          ],
        ),
      ),
      body: Center(
        // --- COMPATIBILITÉ PC ---
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: _messages.isEmpty
                        ? _buildEmptyState(colorScheme)
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) =>
                                _buildMessageBubble(
                                    _messages[index], colorScheme),
                          ),
                  ),
                ],
              ),
              if (_isBlockedByExam)
                _buildBlockedArea(colorScheme)
              else
                _buildInputArea(colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlockedArea(ColorScheme colorScheme) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(Icons.security_rounded, color: colorScheme.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _blockedMessage,
                style: TextStyle(
                    color: colorScheme.onErrorContainer,
                    fontSize: 13,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer, // Jaune très clair
              shape: BoxShape.circle,
            ),
            child:
                Icon(Icons.auto_awesome, size: 64, color: colorScheme.primary),
          ),
          const SizedBox(height: 24),
          Text(
            "Bonjour ! Comment puis-je vous aider ?",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, String> msg, ColorScheme colorScheme) {
    final isUser = msg['role'] == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: isUser
              ? colorScheme.primary
              : colorScheme
                  .surfaceContainerHighest, // Jaune pour user, Gris clair pour Bot
          borderRadius: BorderRadius.circular(24).copyWith(
            bottomRight:
                isUser ? const Radius.circular(4) : const Radius.circular(24),
            bottomLeft:
                isUser ? const Radius.circular(24) : const Radius.circular(4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: MarkdownBody(
          data: msg['content']!,
          styleSheet: MarkdownStyleSheet(
            p: TextStyle(
              color: isUser ? colorScheme.onPrimary : colorScheme.onSurface,
              fontSize: 15,
              height: 1.4,
            ),
            listBullet: TextStyle(
              color: isUser
                  ? colorScheme.onPrimary.withOpacity(0.7)
                  : colorScheme.secondary, // Vert pour les puces du bot
            ),
            strong: TextStyle(
              color: isUser ? colorScheme.onPrimary : colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
            code: TextStyle(
              backgroundColor: isUser
                  ? colorScheme.onPrimary.withOpacity(0.2)
                  : colorScheme.surfaceContainerHighest,
              fontFamily: 'monospace',
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea(ColorScheme colorScheme) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colorScheme.surface.withOpacity(0), colorScheme.surface],
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TextField(
                  controller: _controller,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Écrivez votre message...',
                    hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _isLoading ? null : _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.secondary, // Vert pour le bouton d'envoi
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: colorScheme.secondary.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5)),
                  ],
                ),
                child: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: colorScheme.onSecondary, strokeWidth: 2))
                    : Icon(Icons.send_rounded,
                        color: colorScheme.onSecondary, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
