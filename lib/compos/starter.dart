// lib/compos/starter.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui';
import 'package:estim_campus/services/api_service.dart';
import 'package:estim_campus/services/auth_service.dart';
import 'package:estim_campus/services/storage_service.dart';

class StarterCompo extends StatefulWidget {
  const StarterCompo({super.key});

  @override
  State<StarterCompo> createState() => _StarterCompoState();
}

class _StarterCompoState extends State<StarterCompo> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Largeur max du contenu — au-delà de cette largeur (desktop/web),
  // tout reste centré dans une colonne façon "mobile" au lieu de s'étirer.
  static const double _maxContentWidth = 480.0;

  // Valeurs locales de secours si l'API est injoignable.
  // Modifiables à tout moment depuis /admin/ > Slides d'onboarding.
  static const List<Map<String, dynamic>> _fallbackData = [
    {
      'image': 'assets/img/students.png',
      'title': 'Estim Campus',
      'description':
          'votre campus dans votre poche profite de tous les avantages de votre campus',
      'imageHeight': 350.0,
      'imageWidth': 350.0,
    },
    {
      'image': 'assets/img/edt_image.png',
      'title': 'Cours en ligne',
      'description':
          'Accédez à tous vos cours et supports pédagogiques où que vous soyez',
      'imageHeight': 450.0,
      'imageWidth': 450.0,
      'gradientHeight1': 0.45,
      'gradientHeight2': 0.55,
    },
    {
      'image': 'assets/img/ad_image.png',
      'title': 'Communauté',
      'description':
          'Restez connecté avec votre communauté étudiante et vos professeurs',
      'imageHeight': 400.0,
      'imageWidth': 400.0,
    },
  ];

  List<Map<String, dynamic>> _onboardingData = List.from(_fallbackData);

  @override
  void initState() {
    super.initState();
    _loadSlides();
  }

  /// Charge les slides depuis l'API (modifiables dans /admin/).
  /// En cas d'échec, garde les images locales.
  Future<void> _loadSlides() async {
    try {
      final slides = await ApiService.getOnboardingSlides();
      if (!mounted || slides.isEmpty) return;
      setState(() {
        _onboardingData = slides.map<Map<String, dynamic>>((s) {
          final rawImg = (s['image_display'] ?? s['image'] ?? '').toString();
          final img = rawImg.isNotEmpty
              ? ApiService.formatImageUrl(rawImg) ?? rawImg
              : _fallbackData[0]['image'].toString();
          return {
            'image': img,
            'title': (s['title'] ?? '').toString(),
            'description': (s['description'] ?? '').toString(),
            'imageHeight': 400.0,
            'imageWidth': 400.0,
          };
        }).toList();
        _currentPage = 0;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _isWide => MediaQuery.of(context).size.width > _maxContentWidth;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Largeur effective du "cadre" de contenu: pleine largeur sur mobile,
    // plafonnée à _maxContentWidth sur web/desktop.
    final contentWidth =
        screenWidth > _maxContentWidth ? _maxContentWidth : screenWidth;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        // Sur desktop/web, on encadre tout dans un fond légèrement teinté
        // pour bien délimiter la zone "app" au milieu de l'écran.
        child: Container(
          width: double.infinity,
          color: _isWide ? const Color(0xFFF3F3F3) : Colors.white,
          child: Center(
            child: Container(
              width: contentWidth,
              color: Colors.white,
              child: Stack(
                children: [
                  Positioned.fill(
                    top: -140,
                    child: SvgPicture.asset(
                      'assets/img/wave1.svg',
                      height: 100,
                      width: contentWidth,
                      // Teinte la vague avec la couleur d'accent de la DB.
                      colorFilter: ColorFilter.mode(
                        Theme.of(context).colorScheme.secondary,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      itemCount: _onboardingData.length,
                      itemBuilder: (context, index) {
                        return _buildPage(
                          imagePath: _onboardingData[index]['image']!,
                          title: _onboardingData[index]['title']!,
                          description: _onboardingData[index]['description']!,
                          imageHeight: _onboardingData[index]['imageHeight']!,
                          imageWidth: _onboardingData[index]['imageWidth']!,
                          gradientHeight1:
                              _onboardingData[index]['gradientHeight1'] ?? 0.23,
                          gradientHeight2:
                              _onboardingData[index]['gradientHeight2'] ?? 0.34,
                          contentWidth: contentWidth,
                        );
                      },
                    ),
                  ),
                  Positioned(
                    bottom: 120,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _onboardingData.length,
                        (index) => _buildDot(index),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 40,
                    left: 20,
                    right: 20,
                    child: Center(child: _buildButton()),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPage({
    required String imagePath,
    required String title,
    required String description,
    required double imageHeight,
    required double imageWidth,
    required double gradientHeight1,
    required double gradientHeight2,
    required double contentWidth,
  }) {
    final screenHeight = MediaQuery.of(context).size.height;

    double adjustedWidth = imageWidth;
    if (adjustedWidth > contentWidth * 0.95) {
      adjustedWidth = contentWidth * 0.95;
    }
    double adjustedHeight = adjustedWidth * (imageHeight / imageWidth);

    // Sur web, la fenêtre peut être large mais pas forcément haute
    // (ex: fenêtre de navigateur redimensionnée) — on continue donc
    // aussi à plafonner par rapport à la hauteur d'écran.
    if (adjustedHeight > screenHeight * 0.45) {
      adjustedHeight = screenHeight * 0.45;
      adjustedWidth = adjustedHeight * (imageWidth / imageHeight);
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: screenHeight * 0.1),
          Container(
            height: adjustedHeight,
            width: contentWidth,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: adjustedHeight,
                  width: adjustedWidth,
                  child: imagePath.startsWith('http')
                      ? Image.network(
                          imagePath,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              Image.asset(
                            _fallbackData[0]['image'].toString(),
                            fit: BoxFit.contain,
                          ),
                        )
                      : Image.asset(
                          imagePath,
                          fit: BoxFit.contain,
                        ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: adjustedHeight * gradientHeight1,
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withOpacity(0.0),
                              Colors.white.withOpacity(0.6),
                              Colors.white.withOpacity(0.9),
                            ],
                            stops: [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: adjustedHeight * gradientHeight2,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withOpacity(0.0),
                            Colors.white.withOpacity(0.4),
                            Colors.white.withOpacity(0.8),
                            Colors.white,
                          ],
                          stops: [0.0, 0.3, 0.7, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: screenHeight < 700 ? 26 : 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: screenHeight < 700 ? 12 : 14,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: screenHeight * 0.3),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    final accent = Theme.of(context).colorScheme.secondary;
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(horizontal: 5),
      height: 8,
      width: _currentPage == index ? 30 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? accent
            : Colors.grey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
        boxShadow: _currentPage == index
            ? [
                BoxShadow(
                  color: accent.withOpacity(0.5),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ]
            : [],
      ),
    );
  }

  Widget _buildButton() {
    final accent = Theme.of(context).colorScheme.secondary;
    return GestureDetector(
      onTap: () async {
        if (_currentPage < _onboardingData.length - 1) {
          _pageController.nextPage(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        } else {
          // Fin de l'onboarding -> page de connexion entière.
          await StorageService.setBool('isFirstTime', false);
          if (!context.mounted) return;
          Navigator.pushReplacementNamed(
            context,
            AuthService.isLoggedIn ? '/home' : '/login',
          );
        }
      },
      child: Container(
        // Sur web/desktop, on garde une largeur confortable de bouton
        // mais toujours plafonnée par la largeur du contenu.
        width: MediaQuery.of(context).size.width > _maxContentWidth
            ? _maxContentWidth - 40
            : 340,
        height: 55,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              accent,
              accent.withOpacity(0.75),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.4),
              blurRadius: 15,
              offset: Offset(0, 8),
            ),
            BoxShadow(
              color: accent.withOpacity(0.2),
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _currentPage == _onboardingData.length - 1
                    ? 'Commencer'
                    : 'Suivant',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(width: 8),
              Icon(
                _currentPage == _onboardingData.length - 1
                    ? Icons.check_circle_outline
                    : Icons.arrow_forward,
                color: Colors.black,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
