import 'package:flutter/material.dart';

class GridTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  const GridTile({required this.title, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = [
      Colors.pink.shade100,
      Colors.blue.shade100,
      Colors.green.shade100,
      Colors.orange.shade100,
      Colors.purple.shade100,
      Colors.teal.shade100,
    ];
    final bg = (colors..shuffle()).first;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: bg.withOpacity(0.5),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Icon(icon, size: 36, color: theme.colorScheme.primary),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
