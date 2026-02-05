import 'package:flutter/material.dart';
import '../models/health_log_model.dart';
import '../services/health_log_service.dart';

class HealthLoggingScreen extends StatefulWidget {
  const HealthLoggingScreen({super.key});

  @override
  State<HealthLoggingScreen> createState() => _HealthLoggingScreenState();
}

class _HealthLoggingScreenState extends State<HealthLoggingScreen> {
  int _selectedMood = 3; // 1-5 scale
  int _selectedEnergy = 5; // 1-10 scale
  int _selectedPainIntensity = 0; // 1-10 scale
  String _selectedPainLocation = '';
  late final TextEditingController _notesController = TextEditingController();

  final List<String> _moodEmojis = ['😢', '😕', '😐', '🙂', '😄'];
  final List<String> _painLocations = [
    'Lower abdomen',
    'Lower back',
    'Upper back',
    'Legs',
    'Breasts',
    'Headache',
    'Muscles'
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  // void _savelog() {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(
  //       content: Text('Health log saved successfully!'),
  //       backgroundColor: Colors.green,
  //     ),
  //   );
  //   Navigator.pop(context);
  // }

  Future<void> _savelog() async {
  try {
    // 1️⃣ Model banao (UI → Data)
    final log = HealthLogModel(
      timestamp: DateTime.now(),
      mood: _selectedMood,
      energy: _selectedEnergy,
      painIntensity: _selectedPainIntensity,
      painLocation: _selectedPainLocation,
      notes: _notesController.text.trim(),
    );

    // 2️⃣ Service ke through SAVE karo
    final service = HealthLogService();
    await service.addLog(log);

    if (!mounted) return;

    // 3️⃣ Success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Health log saved successfully!'),
        backgroundColor: Colors.green,
      ),
    );

    // 4️⃣ Back to Home
    Navigator.pop(context);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error saving log: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.pink.shade600),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Log Your Health',
          style: TextStyle(
            color: Colors.pink.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mood Section
            Text(
              'How are you feeling?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      5,
                      (index) => GestureDetector(
                        onTap: () {
                          setState(() => _selectedMood = index + 1);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _selectedMood == index + 1
                                ? Colors.pink.shade100
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _selectedMood == index + 1
                                  ? Colors.pink.shade600
                                  : Colors.transparent,
                            ),
                          ),
                          child: Text(
                            _moodEmojis[index],
                            style: const TextStyle(fontSize: 32),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text('Sad', style: TextStyle(fontSize: 12)),
                      Text('Okay', style: TextStyle(fontSize: 12)),
                      Text('Normal', style: TextStyle(fontSize: 12)),
                      Text('Good', style: TextStyle(fontSize: 12)),
                      Text('Great', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Energy Level
            Text(
              'Energy Level',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Slider(
                    value: _selectedEnergy.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    activeColor: Colors.orange,
                    label: _selectedEnergy.toString(),
                    onChanged: (value) {
                      setState(() => _selectedEnergy = value.toInt());
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Low', style: TextStyle(fontSize: 12)),
                      Text('High', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Pain Section
            Text(
              'Pain Level & Location',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Intensity: $_selectedPainIntensity/10',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: _selectedPainIntensity.toDouble(),
                    min: 0,
                    max: 10,
                    divisions: 10,
                    activeColor: Colors.red,
                    label: _selectedPainIntensity.toString(),
                    onChanged: (value) {
                      setState(() => _selectedPainIntensity = value.toInt());
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Location',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _painLocations.map((location) {
                      return FilterChip(
                        label: Text(location),
                        selected: _selectedPainLocation == location,
                        onSelected: (selected) {
                          setState(() {
                            _selectedPainLocation =
                                selected ? location : '';
                          });
                        },
                        selectedColor: Colors.red.shade100,
                        labelStyle: TextStyle(
                          color: _selectedPainLocation == location
                              ? Colors.red.shade700
                              : Colors.grey.shade700,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Notes
            Text(
              'Additional Notes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Add any notes about your day...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: Colors.pink.shade600, width: 2),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _savelog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save Log',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
