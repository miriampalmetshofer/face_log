import 'package:flutter/material.dart';

class SocialMediaShortcuts extends StatelessWidget {
  final Function(String) onAppTap;

  const SocialMediaShortcuts({
    super.key,
    required this.onAppTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 30.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildAppIcon(
            url: 'https://www.instagram.com',
            icon: Icons.camera_alt,
            label: 'Instagram',
            color: Colors.pink,
          ),
          _buildAppIcon(
            url: 'https://www.facebook.com',
            icon: Icons.facebook,
            label: 'Facebook',
            color: Colors.blue,
          ),
          _buildAppIcon(
            url: 'https://www.tiktok.com',
            icon: Icons.tiktok,
            label: 'TikTok',
            color: Colors.black,
          ),
        ],
      ),
    );
  }

  Widget _buildAppIcon({
    required String url,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, size: 40),
          color: color,
          onPressed: () => onAppTap(url),
        ),
        Text(label),
      ],
    );
  }
}
