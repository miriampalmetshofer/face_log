import 'package:flutter/material.dart';

class VideoLibraryInfoDialog extends StatelessWidget {
  const VideoLibraryInfoDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          SizedBox(width: 8),
          Text('So funktioniert\'s'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoStep(
                      '1. Aufnehmen',
                      'Nimm ein Video deines Gesichts auf. Die Aufnahme startet durch Drücken des roten Buttons auf dem Hauptbildschirm. Die Aufhname endet sich automatisch nach 5 Minuten. Bitte brich das Video nicht vorher ab. Bitte verlasse die App währende der Aufnahme nicht (falls es doch passiert, kehre so schnell wie möglich zurück). Das Video wird automatisch in der Bibliothek gespeichert.',
                      Icons.videocam,
                      Colors.red,
                    ),
                    const SizedBox(height: 16),
                    _buildInfoStep(
                      '2. Annotieren',
                      'Öffne das Video in der Bibliothek und fülle das Formular aus. Beantworte alle Fragen zu den Umständen unter denen das Video aufgezeichnet wurde. Videos für die du das Formular noch ausfüllen musst, sind mit einem orangen Stift markiert.',
                      Icons.edit_note,
                      Colors.orange,
                    ),
                    const SizedBox(height: 16),
                    _buildInfoStep(
                      '3. Hochladen',
                      'Nach dem Ausfüllen kannst du das Video hochladen. Drücke dazu auf die drei Punkte und wähle "Hochladen". Das Hochladen kann etwas dauern, da Videos groß sein können.',
                      Icons.cloud_upload,
                      Colors.blue,
                    ),
                    const SizedBox(height: 16),
                    _buildInfoStep(
                      '4. Fertig!',
                      'Erfolgreich hochgeladene Videos sind mit einem grünen Häkchen markiert. Videos sollten grundsätzlich nicht mehrmals hochgeladen werden.',
                      Icons.check_circle,
                      Colors.green,
                    ),
                    const SizedBox(height: 24),
                    // Button at bottom of scroll content
                    Center(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        ),
                        child: const Text('Verstanden'),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: const [], // Remove default actions since button is in content
    );
  }

  Widget _buildInfoStep(String title, String description, IconData icon, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => const VideoLibraryInfoDialog(),
    );
  }
}
