import 'package:flutter/material.dart';
import '../features/movies/screens/movies_screen.dart';
import '../features/series/screens/series_screen.dart';
import '../features/search/screens/search_screen.dart';
import '../features/favorites/screens/favorites_screen.dart';
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
    FavoritesScreen(),
    SearchScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // معالجة زر العودة
    return PopScope(
      canPop: _currentIndex == 0, // يسمح بالخروج فقط إذا كنا في الشاشة الرئيسية
      onPopInvoked: (didPop) {
        if (didPop) return;
        // إذا لم نكن في الشاشة الرئيسية، نعود إليها
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05), width: 1)),
          ),
          child: SafeArea(
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (i) => setState(() => _currentIndex = i),
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: AppColors.primaryLight,
              unselectedItemColor: AppColors.textTertiary,
              selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.movie_rounded), activeIcon: Icon(Icons.movie_rounded, color: AppColors.primaryLight), label: 'أفلام'),
                BottomNavigationBarItem(icon: Icon(Icons.tv_rounded), activeIcon: Icon(Icons.tv_rounded, color: AppColors.primaryLight), label: 'مسلسلات'),
                BottomNavigationBarItem(icon: Icon(Icons.favorite_border_rounded), activeIcon: Icon(Icons.favorite_rounded, color: AppColors.primaryLight), label: 'المفضلة'),
                BottomNavigationBarItem(icon: Icon(Icons.search_rounded), activeIcon: Icon(Icons.search_rounded, color: AppColors.primaryLight), label: 'بحث'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
