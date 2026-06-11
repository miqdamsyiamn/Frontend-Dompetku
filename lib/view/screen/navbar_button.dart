// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '/utils/app_theme.dart';
import '/services/auth_manager.dart';
import 'home_screen.dart';
import 'transactions_screen.dart';
import 'goals_screen.dart';
import 'profile_screen.dart';
import 'user_management_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  bool get _isAdmin => AuthManager().isAdmin;

  // Build the list of navigation items dynamically
  List<_NavItemData> get _navItems {
    return [
      _NavItemData(
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        label: 'Beranda',
        screen: () => HomeContent(onNavigateToTab: _navigateToTab),
      ),
      _NavItemData(
        icon: Icons.receipt_long_outlined,
        activeIcon: Icons.receipt_long,
        label: 'Transaksi',
        screen: () => const TransactionsScreen(),
      ),
      _NavItemData(
        icon: Icons.savings_outlined,
        activeIcon: Icons.savings,
        label: 'Goals',
        screen: () => const GoalsScreen(),
      ),
      if (_isAdmin)
        _NavItemData(
          icon: Icons.admin_panel_settings_outlined,
          activeIcon: Icons.admin_panel_settings,
          label: 'Admin',
          screen: () => const UserManagementScreen(),
        ),
      _NavItemData(
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: 'Profil',
        screen: () => const ProfileScreen(),
      ),
    ];
  }

  void _navigateToTab(int index) {
    final items = _navItems;
    if (index >= items.length) index = 0;
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = _navItems;
    // Clamp the current index to valid range
    if (_currentIndex >= items.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      body: items[_currentIndex].screen(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (int i = 0; i < items.length; i++)
                  _buildNavItem(
                    index: i,
                    icon: items[i].icon,
                    activeIcon: items[i].activeIcon,
                    label: items[i].label,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }



  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isActive = _currentIndex == index;

    return Semantics(
      label: 'Tab $label',
      button: true,
      selected: isActive,
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? AppTheme.primary.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? activeIcon : icon,
                color: isActive ? AppTheme.primary : AppTheme.textSecondary,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  color: isActive ? AppTheme.primary : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Widget Function() screen;

  const _NavItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.screen,
  });
}
