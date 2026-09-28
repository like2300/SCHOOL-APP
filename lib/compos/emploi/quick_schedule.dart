import 'package:flutter/material.dart';
import 'package:estim_campus/services/api_service.dart';
import 'package:estim_campus/services/storage_service.dart';

class QuickSchedule extends StatefulWidget {
  const QuickSchedule({super.key});

  @override
  State<QuickSchedule> createState() => _QuickScheduleState();
}

class _QuickScheduleState extends State<QuickSchedule> {
  List<dynamic> _todayCours = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTodayCours();
  }

  Future<void> _fetchTodayCours() async {
    final now = DateTime.now();
    
    // Récupération du profil utilisateur avec des valeurs par défaut 'Tous'
    final etab = StorageService.getString('user_etab') ?? 'Tous';
    final niv = StorageService.getString('user_niveau') ?? 'Tous';
    final fil = StorageService.getString('user_filiere') ?? 'Toutes';

    final data = await ApiService.getCours(
      day: now.weekday,
      etablissement: etab,
      niveau: niv,
      filiere: fil,
    );

    if (mounted) {
      setState(() {
        _todayCours = data.take(3).toList();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
    if (_todayCours.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Programme du jour',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1A1A1A)),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/emploi'),
                child: Text('Tout voir', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ..._todayCours.asMap().entries.map((entry) => _buildTimelineItem(entry.value, entry.key == _todayCours.length - 1)),
      ],
    );
  }

  Widget _buildTimelineItem(dynamic c, bool isLast) {
    final startTime = c['heure'].split(' - ')[0];
    
    return IntrinsicHeight(
      child: Row(
        children: [
          // Timeline indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
                    boxShadow: [
                      BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.2), blurRadius: 4, spreadRadius: 1),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: Colors.grey[300],
                    ),
                  ),
              ],
            ),
          ),
          
          // Course Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16, right: 4),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.grey[100]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        startTime,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          c['salle'],
                          style: TextStyle(color: Colors.blue[800], fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    c['matiere'],
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        c['prof'] ?? 'Enseignant non spécifié',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
