import 'package:flutter/material.dart';
import 'package:estim_campus/services/api_service.dart';
import 'package:estim_campus/compos/app_scaffold.dart';

class SitesWebPage extends StatefulWidget {
  const SitesWebPage({super.key});

  @override
  State<SitesWebPage> createState() => _SitesWebPageState();
}

class _SitesWebPageState extends State<SitesWebPage> {
  List<dynamic> _sites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSites();
  }

  Future<void> _fetchSites() async {
    setState(() => _isLoading = true);
    final data = await ApiService.getSitesWeb();
    if (mounted) {
      setState(() {
        _sites = data;
        _isLoading = false;
      });
    }
  }

  String _extractDomain(String? urlString) {
    if (urlString == null || urlString.isEmpty) return '';
    try {
      return Uri.parse(urlString).host.replaceFirst('www.', '');
    } catch (e) {
      return urlString;
    }
  }

  IconData _getIcon(String? iconName) {
    if (iconName == null) return Icons.language_rounded;
    switch (iconName.toLowerCase()) {
      case 'facebook':
        return Icons.facebook_rounded;
      case 'language':
        return Icons.language_rounded;
      case 'how_to_reg':
        return Icons.how_to_reg_rounded;
      case 'public':
        return Icons.public_rounded;
      case 'link':
        return Icons.link_rounded;
      case 'school':
        return Icons.school_rounded;
      default:
        return Icons.open_in_new_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppScaffold(
      selectedIndex: -1,
      appBar: AppBar(
        title: const Text('Sites & Liens Utiles',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : RefreshIndicator(
              color: colorScheme.primary,
              onRefresh: _fetchSites,
              child: _sites.isEmpty
                  ? _buildEmptyState(colorScheme)
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        int crossAxisCount = 2;
                        if (constraints.maxWidth > 900) {
                          crossAxisCount = 4;
                        } else if (constraints.maxWidth > 600) {
                          crossAxisCount = 3;
                        }

                        return Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1000),
                            child: GridView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 24),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                // CORRECTION ICI : 0.85 au lieu de 1.1 donne plus de hauteur à la carte
                                childAspectRatio: 0.85,
                              ),
                              itemCount: _sites.length,
                              itemBuilder: (context, index) {
                                return _buildAnimatedSiteCard(
                                    _sites[index], index, colorScheme);
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.link_off_rounded,
              size: 80, color: colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text('Aucun lien disponible',
              style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildAnimatedSiteCard(
      dynamic site, int index, ColorScheme colorScheme) {
    return TweenAnimationBuilder(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 80)),
      curve: Curves.easeOut,
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 30),
            child: child,
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(
              context,
              '/webview',
              arguments: {'url': site['url'], 'title': site['title']},
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            // CORRECTION ICI : Réduit à 12 au lieu de 16 pour gagner de la place
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: colorScheme.outlineVariant.withOpacity(0.5)),
            ),
            child: Column(
              // CORRECTION ICI : mainAxisSize: MainAxisSize.min évite que la colonne essaie de prendre plus d'espace que disponible
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  // CORRECTION ICI : Padding réduit à 12
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getIcon(site['icon_name']),
                    size: 28, // Légèrement réduit aussi
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 12), // Réduit de 16 à 12

                Text(
                  site['title'] ?? 'Site Web',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13, // Réduit de 14 à 13
                    color: colorScheme.onSurface,
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 4), // Réduit de 6 à 4

                Text(
                  _extractDomain(site['url']),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10, // Réduit de 11 à 10
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
