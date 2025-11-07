import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../pages/history_page.dart';
import '../pages/create_run_page.dart';
import '../pages/overview_run_page.dart';
import '../pages/profile_page.dart';
import '../pages/settings_page.dart';
import '../pages/login_page.dart';
import '../pages/register_page.dart';
import 'session_manager.dart';

class BaseNavigation extends StatefulWidget {
  const BaseNavigation({super.key});

  @override
  State<BaseNavigation> createState() => _BaseNavigationState();
}

class _BaseNavigationState extends State<BaseNavigation> {
  int _currentIndex = 2; // Default to Home
  bool _loggedIn = false;

  final List<GlobalKey<NavigatorState>> _navigatorKeys =
  List.generate(5, (_) => GlobalKey<NavigatorState>());

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _initLoginState();
  }

  Future<void> _initLoginState() async {
    await SessionManager.loadPersistentLogin();
    setState(() {
      _loggedIn = SessionManager.isLoggedIn;
    });
  }

  void _updatePages() {
    _pages = [
      _loggedIn ? const HistoryPage() : const LoginPage(),
      _loggedIn ? const CreateRunPage() : const LoginPage(),
      const OverviewRunPage(),
      _loggedIn ? const ProfilePage() : const LoginPage(),
      const SettingsPage(),
    ];
  }

  void _onTabSelected(int index) {
    if (!_loggedIn && (index == 0 || index == 1 || index == 3)) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
      return;
    }

    if (index == _currentIndex) {
      _navigatorKeys[index]
          .currentState
          ?.popUntil((route) => route.isFirst);
    } else {
      setState(() => _currentIndex = index);
    }
  }

  Future<bool> _handleBackNavigation() async {
    final currentNavigator = _navigatorKeys[_currentIndex].currentState!;
    final canPop = await currentNavigator.maybePop();

    if (!canPop) {
      if (_currentIndex != 2) {
        setState(() => _currentIndex = 2);
        return false;
      }
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    _updatePages();

    return PopScope(
      canPop: false, // whether the route can pop
      onPopInvokedWithResult: (didPop, result) async {
        // This is called when a back gesture is invoked (including Android predictive back)
        if (!didPop) {
          final shouldPop = await _handleBackNavigation();
          if (shouldPop && context.mounted) {
            Navigator.of(context).maybePop();
          }
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: List.generate(_pages.length, (index) {
            return Navigator(
              key: _navigatorKeys[index],
              onGenerateRoute: (_) => MaterialPageRoute(
                builder: (_) => _pages[index],
              ),
            );
          }),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabSelected,
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.access_time,
                  color: _loggedIn ? null : Colors.grey),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline,
                  color: _loggedIn ? null : Colors.grey),
              label: 'Create',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline,
                  color: _loggedIn ? null : Colors.grey),
              label: 'Profile',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              label: 'Settings',
            ),
          ],
          showSelectedLabels: false,
          showUnselectedLabels: false,
        ),
      ),
    );
  }
}