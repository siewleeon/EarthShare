import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  Widget _buildNavItem(IconData icon, String label, bool isSelected) {
    return InkWell(
      onTap: () => onTap(_getIndexForLabel(label)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.blue : Colors.grey,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.blue : Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(Icons.add),
        color: Colors.white,
        onPressed: () => onTap(2), // Post index
      ),
    );
  }

  int _getIndexForLabel(String label) {
    switch (label.toLowerCase()) {
      case 'home':
        return 0;
      case 'search':
        return 1;
      case 'post':
        return 2;
      case 'history':
        return 3;
      case 'profile':
        return 4;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home, 'Home', currentIndex == 0),
            _buildNavItem(Icons.search, 'Search', currentIndex == 1),
            _buildAddButton(),
            _buildNavItem(Icons.history, 'History', currentIndex == 3),
            _buildNavItem(Icons.person, 'Profile', currentIndex == 4),
          ],
        ),
      ),
    );
  }
} 