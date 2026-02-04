import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class WellnessScreen extends StatelessWidget {
  const WellnessScreen({super.key});

  static final List<Map<String, String>> _sessions = [
    {
      'title': 'Breathing Exercise - 5 min',
      'desc': 'Guided breathing to calm anxiety',
      'url': 'https://www.youtube.com/watch?v=odADwWzHR24'
    },
    {
      'title': 'Gentle Stretching',
      'desc': 'Short stretch routine for comfort',
      'url': 'https://www.youtube.com/watch?v=VaoV1PrYft4'
    },
    {
      'title': 'Short Guided Meditation',
      'desc': '5 minute grounding meditation',
      'url': 'https://www.youtube.com/watch?v=inpok4MKVLM'
    },
  ];

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final messenger = ScaffoldMessenger.of(context);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      messenger.showSnackBar(const SnackBar(content: Text('Unable to open video')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wellness Sessions')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _sessions.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final s = _sessions[i];
          return Card(
            child: ListTile(
              title: Text(s['title']!),
              subtitle: Text(s['desc']!),
              trailing: ElevatedButton(
                onPressed: () => _openUrl(context, s['url']!),
                child: const Text('Play'),
              ),
            ),
          );
        },
      ),
    );
  }
}
