import 'package:flutter/material.dart';
import '../widgets/card_container.dart';
import '../widgets/primary_button.dart';
import '../models/health_log_model.dart';
import '../services/health_log_service.dart';
import 'sos_screen.dart';

class HealthLoggingScreen extends StatefulWidget {
  const HealthLoggingScreen({super.key});

  @override
  State<HealthLoggingScreen> createState() => _HealthLoggingScreenState();
}

class _HealthLoggingScreenState extends State<HealthLoggingScreen> {
  final HealthLogService _service = HealthLogService();

  // Date auto-filled
  DateTime _date = DateTime.now();

  // Cycle day (optional, auto-calc later)
  int? _cycleDay;

  // Period
  String _periodStatus = 'None';
  bool _spotting = false;

  // Symptoms
  final List<String> _symptomOptions = [
    'Cramps',
    'Headache',
    'Bloating',
    'Nausea',
    'Breast tenderness',
    'Back pain',
    'Fatigue',
    'Acne',
  ];
  final Set<String> _selectedSymptoms = {};

  // Mood
  String _mood = 'Neutral';
  int _moodIntensity = 3; // 1-5

  // Pain
  int _painIntensity = 0; // 0-10
  String _painLocation = '';

  // Flow intensity
  String _flowIntensity = 'None';

  // Sleep
  double? _sleepHours;
  String _sleepQuality = 'Good';

  // Activity
  String _activityType = 'None';
  int? _activityDuration;

  // Hydration
  int _hydration = 0;
  int _hydrationGoal = 8;

  // Nutrition
  final List<String> _cravingOptions = ['Sweet', 'Salty', 'Spicy'];
  final Set<String> _cravings = {};
  bool _ironTaken = false;
  final TextEditingController _foodNotesCtrl = TextEditingController();

  // Mental health
  String _stressLevel = 'Medium';
  final TextEditingController _stressReasonCtrl = TextEditingController();

  // Energy level
  int _energyLevel = 5;

  // Meds & self-care
  final TextEditingController _medsCtrl = TextEditingController();
  final Set<String> _selfCare = {};

  // Notes
  final TextEditingController _notesController = TextEditingController();

  bool _saving = false;

  @override
  void dispose() {
    _foodNotesCtrl.dispose();
    _stressReasonCtrl.dispose();
    _medsCtrl.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveLog() async {
    setState(() => _saving = true);
    try {
      final model = HealthLogModel(
        timestamp: _date,
        mood: _mood,
        moodIntensity: _moodIntensity,
        energy: _energyLevel,
        painIntensity: _painIntensity,
        painLocation: _painLocation,
        periodStatus: _periodStatus,
        spotting: _spotting,
        cycleDay: _cycleDay,
        symptoms: _selectedSymptoms.toList(),
        sleepHours: _sleepHours,
        sleepQuality: _sleepQuality,
        activityType: _activityType,
        activityDuration: _activityDuration,
        hydration: _hydration,
        hydrationGoal: _hydrationGoal,
        cravings: _cravings.toList(),
        ironTaken: _ironTaken,
        foodNotes: _foodNotesCtrl.text.trim(),
        stressLevel: _stressLevel,
        stressReason: _stressReasonCtrl.text.trim(),
        energyLevel: _energyLevel,
        medications: _medsCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
        selfCare: _selfCare.toList(),
        notes: _notesController.text.trim(),
      );

      await _service.addLog(model);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Log saved'), backgroundColor: Colors.green));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving log: $e')));
    } finally {
      setState(() => _saving = false);
    }
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.pink.shade700,
                ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 3,
            width: 36,
            decoration: BoxDecoration(
              color: Colors.pink.shade200,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: const Text('Log Your Health'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.pink.shade700,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.pink.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CardContainer(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.pink.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.favorite, color: Colors.pink.shade600),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Today\'s Check-In',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Takes under 2 minutes - your data stays private.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Date
            CardContainer(
              padding: const EdgeInsets.all(12),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Date', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text('${_date.toLocal().toString().split(' ')[0]}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ]),
                TextButton.icon(onPressed: () async {
                  final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime.now());
                  if (picked != null) setState(() => _date = picked);
                }, icon: const Icon(Icons.calendar_today), label: const Text('Change'))
              ]),
            ),
            const SizedBox(height: 12),

          // Period & cycle
          _sectionTitle('Period Status'),
          const SizedBox(height: 8),
          CardContainer(
            padding: const EdgeInsets.all(12),
            child: Column(children: [
              DropdownButtonFormField<String>(
                value: _periodStatus,
                items: ['None','Spotting','Light','Medium','Heavy'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setState(() => _periodStatus = v ?? 'None'),
                decoration: const InputDecoration(border: InputBorder.none),
              ),
              Row(children: [
                Checkbox(value: _spotting, onChanged: (v) => setState(() => _spotting = v ?? false)),
                const SizedBox(width: 8),
                const Text('Spotting today'),
              ])
            ]),
          ),
          const SizedBox(height: 12),

          // Symptoms
          _sectionTitle('Symptoms (select all that apply)'),
          const SizedBox(height: 8),
          CardContainer(padding: const EdgeInsets.all(12), child: Wrap(spacing: 8, children: _symptomOptions.map((s) {
            final selected = _selectedSymptoms.contains(s);
            return FilterChip(label: Text(s), selected: selected, onSelected: (v) => setState(() => v ? _selectedSymptoms.add(s) : _selectedSymptoms.remove(s)));
          }).toList())),
          const SizedBox(height: 12),

          // Mood
          _sectionTitle('Mood'),
          const SizedBox(height: 8),
          CardContainer(padding: const EdgeInsets.all(12), child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              ...['😊','😐','😔','😡','😰','😴'].map((e) => GestureDetector(onTap: () => setState(() => _mood = e), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: _mood==e?Colors.pink.shade100:Colors.transparent,borderRadius: BorderRadius.circular(8)), child: Text(e, style: const TextStyle(fontSize: 28))))),
            ]),
            const SizedBox(height: 8),
            Row(children: [const Text('Intensity:'), Expanded(child: Slider(value: _moodIntensity.toDouble(), min: 1, max: 5, divisions: 4, label: '$_moodIntensity', onChanged: (v)=>setState(()=>_moodIntensity=v.toInt())))]),
          ])),
          const SizedBox(height: 12),

          // Pain
          _sectionTitle('Pain'),
          const SizedBox(height: 8),
          CardContainer(padding: const EdgeInsets.all(12), child: Column(children: [
            Text('Pain intensity: $_painIntensity/10', style: const TextStyle(fontWeight: FontWeight.bold)),
            Slider(value: _painIntensity.toDouble(), min: 0, max: 10, divisions: 10, label: '$_painIntensity', onChanged: (v)=>setState(()=>_painIntensity=v.toInt())),
            const SizedBox(height: 8),
            TextField(decoration: const InputDecoration(labelText: 'Pain location (optional)'), onChanged: (v)=>setState(()=>_painLocation=v)),
          ])),
          const SizedBox(height: 12),

          // Sleep
          _sectionTitle('Sleep'),
          const SizedBox(height: 8),
          CardContainer(padding: const EdgeInsets.all(12), child: Column(children: [
            Row(children: [const Text('Hours slept:'), const SizedBox(width: 8), Expanded(child: TextField(keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'e.g. 7.5'), onChanged: (v)=> setState(()=> _sleepHours = double.tryParse(v))))]),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(value: _sleepQuality, items: ['Poor','Okay','Good'].map((s)=>DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v)=> setState(()=> _sleepQuality = v ?? 'Good'), decoration: const InputDecoration(border: InputBorder.none)),
          ])),
          const SizedBox(height: 12),

          // Activity
          _sectionTitle('Activity'),
          const SizedBox(height: 8),
          CardContainer(padding: const EdgeInsets.all(12), child: Column(children: [
            DropdownButtonFormField<String>(value: _activityType, items: ['None','Walking','Yoga','Gym'].map((s)=>DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v)=> setState(()=> _activityType = v ?? 'None'), decoration: const InputDecoration(border: InputBorder.none)),
            const SizedBox(height: 8),
            TextField(keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Duration (minutes)'), onChanged: (v)=> setState(()=> _activityDuration = int.tryParse(v))),
          ])),
          const SizedBox(height: 12),

          // Hydration
          _sectionTitle('Hydration'),
          const SizedBox(height: 8),
          CardContainer(padding: const EdgeInsets.all(12), child: Row(children: [
            Expanded(child: Row(children: [const Text('Glasses:'), const SizedBox(width: 8), Expanded(child: TextField(keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'e.g. 8'), onChanged: (v)=> setState(()=> _hydration = int.tryParse(v) ?? 0)))])),
            const SizedBox(width: 12),
            Column(children: [const Text('Goal'), const SizedBox(height: 4), Text('$_hydrationGoal')])
          ])),
          const SizedBox(height: 12),

          // Nutrition
          _sectionTitle('Nutrition & Cravings'),
          const SizedBox(height: 8),
          CardContainer(padding: const EdgeInsets.all(12), child: Column(children: [
            Wrap(spacing: 8, children: _cravingOptions.map((c) => FilterChip(label: Text(c), selected: _cravings.contains(c), onSelected: (v)=> setState(()=> v? _cravings.add(c): _cravings.remove(c)))).toList()),
            const SizedBox(height: 8),
            Row(children: [const Text('Iron taken?'), const SizedBox(width: 8), Switch(value: _ironTaken, onChanged: (v)=> setState(()=> _ironTaken = v))]),
            const SizedBox(height: 8),
            TextField(controller: _foodNotesCtrl, decoration: const InputDecoration(labelText: 'Food notes')),
          ])),
          const SizedBox(height: 12),

          // Mental Health
          _sectionTitle('Stress & Energy'),
          const SizedBox(height: 8),
          CardContainer(padding: const EdgeInsets.all(12), child: Column(children: [
            DropdownButtonFormField<String>(value: _stressLevel, items: ['Low','Medium','High'].map((s)=>DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v)=> setState(()=> _stressLevel = v ?? 'Medium'), decoration: const InputDecoration(border: InputBorder.none)),
            const SizedBox(height: 8),
            TextField(controller: _stressReasonCtrl, decoration: const InputDecoration(labelText: 'Stress reason (optional)')),
            const SizedBox(height: 8),
            Row(children: [const Text('Energy'), Expanded(child: Slider(value: _energyLevel.toDouble(), min: 0, max: 10, divisions: 10, onChanged: (v)=> setState(()=> _energyLevel = v.toInt())))]),
          ])),
          const SizedBox(height: 12),

          // Meds & Self-care
          _sectionTitle('Medication & Self-care'),
          const SizedBox(height: 8),
          CardContainer(padding: const EdgeInsets.all(12), child: Column(children: [
            TextField(controller: _medsCtrl, decoration: const InputDecoration(labelText: 'Medications (comma separated)')),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: ['Hot water bag','Meditation','Rest','Massage'].map((s) => FilterChip(label: Text(s), selected: _selfCare.contains(s), onSelected: (v)=> setState(()=> v? _selfCare.add(s): _selfCare.remove(s)))).toList()),
          ])),
          const SizedBox(height: 12),

          // Notes & Save
          _sectionTitle('Notes'),
          const SizedBox(height: 8),
          CardContainer(padding: const EdgeInsets.all(12), child: TextField(controller: _notesController, maxLines: 4, decoration: const InputDecoration(hintText: 'Daily notes...'))),
          const SizedBox(height: 16),
          PrimaryButton(label: _saving ? 'Saving...' : 'Save Log', onPressed: _saving ? null : _saveLog),
          const SizedBox(height: 24),
        ]),
      ),
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: () { Navigator.push(context, MaterialPageRoute(builder: (_) => const SosScreen())); }, backgroundColor: Colors.red.shade600, icon: const Icon(Icons.emergency, color: Colors.white), label: const Text('SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
    );
  }
}
