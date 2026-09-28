import 'package:flutter/material.dart';
import 'package:estim_campus/compos/apps.dart';
import 'package:estim_campus/services/api_service.dart';
import 'package:estim_campus/compos/bottom_nav.dart';
import 'package:estim_campus/compos/app_scaffold.dart';

class Appstores extends StatefulWidget {
  const Appstores({super.key});

  @override
  State<Appstores> createState() => _AppstoresState();
}

class _AppstoresState extends State<Appstores> {
  List<dynamic> _apps = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchApps();
  }

  Future<void> _fetchApps() async {
    final data = await ApiService.getApps();
    setState(() {
      _apps = data;
      _isLoading = false;
    });
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'calendar_today': return Icons.calendar_today;
      case 'grade': return Icons.grade;
      case 'menu_book': return Icons.menu_book;
      case 'message': return Icons.message;
      case 'assignment': return Icons.assignment;
      default: return Icons.apps;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      selectedIndex: 1,
      appBar: AppBar(
        title: const Text('Applications'),
        automaticallyImplyLeading: false,
      ),
      bottomNavigationBar: const NavbarCompo(selectedIndex: 1),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 900 ? 4 : 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: _apps.length,
              itemBuilder: (context, index) {
                final app = _apps[index];
                return Apps(
                  title: app['title'],
                  description: app['description'],
                  icon: _getIconData(app['icon_name']),
                  image: app['image_url'],
                  onTap: app['route'] != null 
                    ? () => Navigator.pushNamed(context, app['route']) 
                    : () => print('App ${app['title']} tapped'),
                );
              },
            ),
          ),
    );
  }
}
