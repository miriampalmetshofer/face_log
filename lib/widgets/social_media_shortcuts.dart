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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // First row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildAppIcon(
                url: 'https://www.google.com',
                icon: Icons.search,
                label: 'Google',
                color: Colors.blue.shade700,
              ),
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
            ],
          ),
          const SizedBox(height: 30),
          // Second row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildAppIcon(
                url: 'https://www.tiktok.com',
                icon: Icons.tiktok,
                label: 'TikTok',
                color: Colors.black,
              ),
              _buildAppIcon(
                url: 'https://www.youtube.com',
                icon: Icons.play_circle_filled,
                label: 'YouTube',
                color: Colors.red,
              ),
              _buildAppIcon(
                url: 'https://www.derstandard.at',
                icon: Icons.article,
                label: 'Der Standard',
                color: Colors.black87,
              ),
            ],
          ),
          const SizedBox(height: 30),
          // Third row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildAppIcon(
                url: 'https://www.kurier.at',
                icon: Icons.newspaper,
                label: 'Kurier',
                color: Colors.blue.shade800,
              ),
              _buildAppIcon(
                url: 'https://wetter.orf.at',
                icon: Icons.wb_sunny,
                label: 'Wetter',
                color: Colors.orange,
              ),
              _buildAppIcon(
                url: 'https://play2048.co',
                icon: Icons.grid_4x4,
                label: '2048',
                color: Colors.deepOrange,
              ),
            ],
          ),
          const SizedBox(height: 30),
          // Fourth row - Games
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildAppIcon(
                url: 'https://tetris.com/play-tetris',
                icon: Icons.view_module,
                label: 'Tetris',
                color: Colors.purple,
              ),
              _buildAppIcon(
                url: 'https://wordle.at',
                icon: Icons.grid_on,
                label: 'Wordle',
                color: Colors.green.shade700,
              ),
              _buildAppIcon(
                url: 'https://poki.com/en/g/subway-surfers',
                icon: Icons.directions_run,
                label: 'Subway Surfers',
                color: Colors.yellow.shade700,
              ),
            ],
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
