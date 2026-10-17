import 'package:flutter/material.dart';
import '../features/movies/screens/movies_screen.dart';
import '../features/series/screens/series_screen.dart';
import '../features/search/screens/search_screen.dart';
import 'constants.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    MoviesScreen(),
    SeriesScreen(),
    SearchScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(
              color: Colors.white.withOpacity(0.05),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: AppColors.primaryLight,
            unselectedItemColor: AppColors.textTertiary,
            selectedLabelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.movie_rounded),
                activeIcon: Icon(Icons.movie_rounded, color: AppColors.primaryLight),
                label: 'أفلام',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.tv_rounded),
                activeIcon: Icon(Icons.tv_rounded, color: AppColors.primaryLight),
                label: 'مسلسلات',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.search_rounded),
                activeIcon: Icon(Icons.search_rounded, color: AppColors.primaryLight),
                label: 'بحث',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
