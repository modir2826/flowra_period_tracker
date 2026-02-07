import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/card_container.dart';
import 'sos_screen.dart';

class WellnessScreen extends StatefulWidget {
  const WellnessScreen({super.key});

  @override
  State<WellnessScreen> createState() => _WellnessScreenState();
}

class _WellnessScreenState extends State<WellnessScreen> {
  static final List<WellnessSession> _allSessions = [
    WellnessSession(
      id: 1,
      title: 'Breathing Exercise - 5 min',
      description: 'Guided breathing to calm anxiety and reduce stress',
      category: 'Breathing',
      duration: '5 min',
      difficulty: 'Beginner',
      url: 'https://www.youtube.com/watch?v=odADwWzHR24',
      icon: Icons.air,
    ),
    WellnessSession(
      id: 2,
      title: 'Gentle Stretching',
      description: 'Short stretch routine for comfort and flexibility',
      category: 'Stretching',
      duration: '10 min',
      difficulty: 'Beginner',
      url: 'https://www.youtube.com/watch?v=VaoV1PrYft4',
      icon: Icons.self_improvement,
    ),
    WellnessSession(
      id: 3,
      title: 'Short Guided Meditation',
      description: '5 minute grounding meditation for mindfulness',
      category: 'Meditation',
      duration: '5 min',
      difficulty: 'Beginner',
      url: 'https://www.youtube.com/watch?v=inpok4MKVLM',
      icon: Icons.spa,
    ),
    WellnessSession(
      id: 4,
      title: 'Yoga for Period Comfort',
      description: 'Gentle yoga poses to ease period discomfort',
      category: 'Yoga',
      duration: '15 min',
      difficulty: 'Beginner',
      url: 'https://www.youtube.com/watch?v=_Auza-7jCEA',
      icon: Icons.self_improvement,
    ),
    WellnessSession(
      id: 5,
      title: 'Deep Relaxation',
      description: 'Progressive muscle relaxation for deep rest',
      category: 'Relaxation',
      duration: '15 min',
      difficulty: 'Beginner',
      url: 'https://www.youtube.com/watch?v=X3Z7DZ2dQKU',
      icon: Icons.healing,
    ),
    WellnessSession(
      id: 6,
      title: 'Morning Energizer',
      description: 'Dynamic stretches to start your day energized',
      category: 'Exercise',
      duration: '10 min',
      difficulty: 'Beginner',
      url: 'https://www.youtube.com/watch?v=L_xrDAtfqIo',
      icon: Icons.energy_savings_leaf,
    ),
    WellnessSession(
      id: 7,
      title: 'Anxiety Relief Meditation',
      description: 'Guided meditation to calm anxious thoughts',
      category: 'Meditation',
      duration: '10 min',
      difficulty: 'Intermediate',
      url: 'https://www.youtube.com/watch?v=SEDuGFVXYFQ',
      icon: Icons.spa,
    ),
    WellnessSession(
      id: 8,
      title: 'Sleep Preparation',
      description: 'Calming routine to prepare for restful sleep',
      category: 'Relaxation',
      duration: '20 min',
      difficulty: 'Beginner',
      url: 'https://www.youtube.com/watch?v=UZjOPCRB0_4',
      icon: Icons.nights_stay,
    ),
  ];

  String _selectedCategory = 'All';
  // ignore: prefer_final_fields
  Set<int> _completedSessions = {};
  // ignore: prefer_final_fields
  Set<int> _favoriteSessions = {};

  List<WellnessSession> get _filteredSessions {
    if (_selectedCategory == 'All') {
      return _allSessions;
    }
    return _allSessions.where((s) => s.category == _selectedCategory).toList();
  }

  Set<String> get _categories {
    final cats = <String>{'All'};
    for (final session in _allSessions) {
      cats.add(session.category);
    }
    return cats;
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open video')),
        );
      }
    }
  }

  void _toggleComplete(int sessionId) {
    setState(() {
      if (_completedSessions.contains(sessionId)) {
        _completedSessions.remove(sessionId);
      } else {
        _completedSessions.add(sessionId);
      }
    });
  }

  void _toggleFavorite(int sessionId) {
    setState(() {
      if (_favoriteSessions.contains(sessionId)) {
        _favoriteSessions.remove(sessionId);
      } else {
        _favoriteSessions.add(sessionId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wellness Sessions'),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.teal.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Take Care of Yourself',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Explore guided sessions for relaxation and wellness',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                  const SizedBox(height: 16),
                  // Stats
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_completedSessions.length}',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              'Completed',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_favoriteSessions.length}',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              'Favorites',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Category Filter
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Categories',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ..._categories.map((category) {
                          final isSelected = _selectedCategory == category;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(category),
                              selected: isSelected,
                              onSelected: (_) {
                                setState(() => _selectedCategory = category);
                              },
                              backgroundColor: Colors.grey.shade100,
                              selectedColor: Colors.green.shade300,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Sessions List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _filteredSessions.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'No sessions in this category',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        ..._filteredSessions.map((session) {
                          final isCompleted = _completedSessions.contains(session.id);
                          final isFavorite = _favoriteSessions.contains(session.id);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: CardContainer(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          session.icon,
                                          color: Colors.green.shade600,
                                          size: 32,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              session.title,
                                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                                                  ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              session.description,
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    color: Colors.grey.shade600,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Icon(Icons.timer, size: 14, color: Colors.grey.shade500),
                                                const SizedBox(width: 4),
                                                Text(
                                                  session.duration,
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                        color: Colors.grey.shade600,
                                                      ),
                                                ),
                                                const SizedBox(width: 16),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue.shade50,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    session.difficulty,
                                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                          color: Colors.blue.shade700,
                                                          fontSize: 11,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              isFavorite ? Icons.favorite : Icons.favorite_border,
                                              color: isFavorite ? Colors.red : Colors.grey,
                                            ),
                                            onPressed: () => _toggleFavorite(session.id),
                                            constraints: const BoxConstraints(),
                                            padding: EdgeInsets.zero,
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: Icon(
                                              isCompleted ? Icons.check_circle : Icons.check_circle_outline,
                                              color: isCompleted ? Colors.green : Colors.grey,
                                            ),
                                            onPressed: () => _toggleComplete(session.id),
                                            constraints: const BoxConstraints(),
                                            padding: EdgeInsets.zero,
                                          ),
                                        ],
                                      ),
                                      Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () => _openUrl(session.url),
                                          borderRadius: BorderRadius.circular(24),
                                          child: Ink(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [Colors.green.shade500, Colors.teal.shade600],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              borderRadius: BorderRadius.circular(24),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.green.shade200.withOpacity(0.6),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 6),
                                                ),
                                              ],
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: const [
                                                  Icon(Icons.play_circle_fill, color: Colors.white, size: 18),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    'Watch',
                                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 24),
                      ],
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const SosScreen()));
        },
        backgroundColor: Colors.red.shade600,
        icon: const Icon(Icons.emergency, color: Colors.white),
        label: const Text('Emergency SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class WellnessSession {
  final int id;
  final String title;
  final String description;
  final String category;
  final String duration;
  final String difficulty;
  final String url;
  final IconData icon;

  WellnessSession({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.duration,
    required this.difficulty,
    required this.url,
    required this.icon,
  });
}
