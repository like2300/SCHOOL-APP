import 'dart:async';
import 'package:flutter/material.dart';
import 'package:estim_campus/services/api_service.dart';

class Annonces extends StatefulWidget {
  const Annonces({super.key});

  @override
  State<Annonces> createState() => _AnnoncesState();
}

class _AnnoncesState extends State<Annonces> {
  List<String> _imageUrls = [];
  bool _isLoading = true;

  // Contrôleurs pour le carousel
  final PageController _pageController = PageController();
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _fetchHeroImages();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // Récupère toutes les images de l'API
  Future<void> _fetchHeroImages() async {
    final images = await ApiService.getHeroImages();
    if (mounted) {
      setState(() {
        _isLoading = false;
        _imageUrls = images
            .map((img) {
              final String? rawUrl = (img['image_display'] != null &&
                      img['image_display'].toString().isNotEmpty)
                  ? img['image_display']
                  : img['image_url'];
              return ApiService.formatImageUrl(rawUrl) ?? '';
            })
            .where((url) => url.isNotEmpty)
            .toList();

        // Si aucune image n'est trouvée, on met l'image locale par défaut
        if (_imageUrls.isEmpty) {
          _imageUrls = ['assets/img/Hero.png'];
        }
      });
    }
  }

  // Défilement automatique toutes les 4 secondes
  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (_pageController.hasClients && _imageUrls.length > 1) {
        if (_currentPage < _imageUrls.length - 1) {
          _currentPage++;
        } else {
          _currentPage = 0;
        }
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.grey[200], // Couleur de fond pendant le chargement
      ),
      // Clip.antiAlias est ESSENTIEL pour que les images ne débordent pas du border radius
      clipBehavior: Clip.antiAlias,
      child: _isLoading
          ? _buildPlaceholder()
          : Stack(
              children: [
                // Le Carousel d'images
                PageView.builder(
                  controller: _pageController,
                  itemCount: _imageUrls.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final url = _imageUrls[index];
                    final isAsset = url.startsWith('assets/');

                    return Image(
                      image: isAsset ? AssetImage(url) : NetworkImage(url),
                      fit: BoxFit.cover,
                      // Gestion d'erreur si l'image réseau ne charge pas
                      errorBuilder: (context, error, stackTrace) =>
                          _buildPlaceholder(),
                    );
                  },
                ),

                // Gradient subtil pour faire ressortir les points (optionnel mais joli)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.2),
                        ],
                      ),
                    ),
                  ),
                ),

                // Les indicateurs (Dots)
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _imageUrls.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? Colors.white
                              : Colors.white.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // Widget affiché pendant le chargement ou en cas d'erreur
  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage('assets/img/Hero.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
