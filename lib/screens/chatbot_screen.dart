import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final List<ChatMessage> _messages = [
    ChatMessage(
      text: 'Hi! 👋 I\'m Flowra\'s AI assistant. I can help answer questions about period tracking, health, safety, and wellness. What would you like to know?',
      isUser: false,
      timestamp: DateTime.now(),
    ),
  ];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  List<Map<String, String>> _suggestions = [];

  final List<Map<String, String>> _faqs = [
    {'question': 'How accurate is period prediction?', 'icon': '📅'},
    {'question': 'What is a normal cycle length?', 'icon': '⏱️'},
    {'question': 'How do I track my health logs?', 'icon': '📊'},
    {'question': 'What are the features of Flowra?', 'icon': '✨'},
    {'question': 'How do I use the SOS feature?', 'icon': '🆘'},
    {'question': 'How is my data protected?', 'icon': '🔒'},
    {'question': 'How do I add previous cycles?', 'icon': '🗓️'},
    {'question': 'What should I do if my cycle is irregular?', 'icon': '🧭'},
    {'question': 'How do I track symptoms like cramps?', 'icon': '💢'},
    {'question': 'How can I improve energy levels?', 'icon': '⚡'},
    {'question': 'How do I manage PMS symptoms?', 'icon': '🌙'},
    {'question': 'What is the fertile window?', 'icon': '🌱'},
    {'question': 'How do I add trusted contacts?', 'icon': '👥'},
    {'question': 'Can I export or delete my data?', 'icon': '📁'},
    {'question': 'What should I log daily?', 'icon': '📝'},
    {'question': 'How do I use the cycle tracker?', 'icon': '📈'},
    {'question': 'What do the insights mean?', 'icon': '🔎'},
    {'question': 'How do I reset my password?', 'icon': '🔑'},
  ];

  void _updateSuggestions(String lastQuestion) {
    final msg = lastQuestion.toLowerCase();
    final List<String> candidates = [];
    if (msg.contains('period') || msg.contains('cycle')) {
      candidates.addAll([
        'How accurate is period prediction?',
        'What is a normal cycle length?',
        'How do I track my health logs?',
      ]);
    } else if (msg.contains('health') || msg.contains('log')) {
      candidates.addAll([
        'How do I track my health logs?',
        'How is my data protected?',
        'What are the features of Flowra?',
      ]);
    } else if (msg.contains('sos') || msg.contains('emergency')) {
      candidates.addAll([
        'How do I use the SOS feature?',
        'How is my data protected?',
        'What are the features of Flowra?',
      ]);
    } else if (msg.contains('privacy') || msg.contains('data') || msg.contains('secure')) {
      candidates.addAll([
        'How is my data protected?',
        'What are the features of Flowra?',
        'How do I track my health logs?',
      ]);
    } else {
      candidates.addAll(_faqs.map((f) => f['question']!).toList());
    }

    final unique = <String>{};
    for (final q in candidates) {
      if (q.toLowerCase() == msg) continue;
      unique.add(q);
    }

    final picks = unique.take(3).toList();
    setState(() {
      _suggestions = _faqs.where((f) => picks.contains(f['question'])).toList();
    });
  }

  Future<void> _sendMessage(String message) async {
    if (message.isEmpty) return;

    // Add user message
    setState(() {
      _messages.add(ChatMessage(
        text: message,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });
    _inputController.clear();
    _scrollToBottom();

    try {
      // Call AI backend for response
      final response = await http.post(
        Uri.parse('http://localhost:8001/ai/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': message,
          'context': 'faq_assistant',
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => http.Response('{"error": "timeout"}', 500),
      );

      String botResponse;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        botResponse = data['response'] as String? ?? 'I\'m not sure about that. Could you rephrase?';
      } else {
        botResponse = _getFallbackResponse(message);
      }

      setState(() {
        _messages.add(ChatMessage(
          text: botResponse,
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
      _updateSuggestions(message);
    } catch (e) {
      // Fallback to predefined responses if backend fails
      final fallback = _getFallbackResponse(message);
      setState(() {
        _messages.add(ChatMessage(
          text: fallback,
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
      _updateSuggestions(message);
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  String _getFallbackResponse(String message) {
    final msg = message.toLowerCase();

    // Basic FAQ responses
    if (msg.contains('period') && msg.contains('track')) {
      return 'To track your period:\n1. Go to Cycle Tracker\n2. Click the date picker to select when your period started\n3. Enter how many days your period lasts\n4. Click "Save Period Start"\n\nYour data is saved securely!';
    } else if (msg.contains('cycle') && msg.contains('length')) {
      return 'A normal cycle length is typically 21-35 days, with 28 days being the average. Your cycle is calculated from the first day of one period to the first day of the next.\n\nFlowra helps you track your personal cycle pattern!';
    } else if (msg.contains('health') && msg.contains('log')) {
      return 'To log your health:\n1. Go to Health Logging\n2. Enter your mood (1-10)\n3. Rate your energy level\n4. Log any pain or discomfort\n5. Add notes (optional)\n6. Save!\n\nThis helps with insights and pattern tracking.';
    } else if (msg.contains('feature')) {
      return 'Flowra has these main features:\n📅 Period Tracking - Predict and log cycles\n📊 Health Logging - Track mood, energy, pain\n💊 Wellness Sessions - Self-care activities\n📈 Insights - AI-powered health analysis\n🆘 Emergency SOS - Quick safety alerts\n👥 Trusted Contacts - Emergency contacts\n💬 AI Chat - Get instant answers!\n\nWhat would you like to know more about?';
    } else if (msg.contains('sos')) {
      return 'The SOS feature is for emergencies:\n1. Click the red SOS button\n2. Confirm the alert\n3. Select trusted contacts to notify\n4. Your location is shared for safety\n\nUse it when you feel unsafe. Flowra prioritizes your safety!';
    } else if (msg.contains('data') || msg.contains('privacy') || msg.contains('secure')) {
      return 'Your data is protected with:\n🔐 Firebase Authentication - Secure login\n🔒 Encrypted storage - Industry-standard encryption\n👤 User-specific access - Only you see your data\n📵 No sharing - We never sell your data\n\nFlowra is designed with your privacy first!';
    } else if (msg.contains('accurate') || msg.contains('prediction')) {
      return 'Period prediction accuracy depends on:\n✅ Consistent cycle length\n✅ Multiple cycles recorded (2+ recommended)\n✅ Regular tracking\n\nThe more data you log, the more accurate the predictions become. Most users find it 85-90% accurate after 2-3 cycles!';
    } else if (msg.contains('help') || msg.contains('how')) {
      return 'I can help with questions about:\n• Period tracking and cycles\n• Health logging features\n• Using Flowra safely\n• Privacy and security\n• Wellness features\n• Emergency features\n\nWhat specifically can I help you with?';
    } else if (msg.contains('thank') || msg.contains('thanks')) {
      return 'You\'re welcome! 😊 If you have any other questions about Flowra, feel free to ask!';
    } else {
      return 'That\'s a great question! Based on what you asked, I\'m not certain of the best answer. Could you:\n1. Try asking differently\n2. Check the Help section\n3. Contact support\n\nOr ask me about period tracking, health logging, wellness, or safety features!';
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flowra Assistant'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Messages area
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: msg.isUser ? Colors.pink.shade600 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    child: Column(
                      crossAxisAlignment: msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg.text,
                          style: TextStyle(
                            color: msg.isUser ? Colors.white : Colors.black,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${msg.timestamp.hour}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            color: msg.isUser ? Colors.white70 : Colors.grey.shade600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Quick FAQ buttons (only show if no conversation started)
          if (_messages.length == 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Common Questions:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _faqs.map((faq) {
                      return ActionChip(
                        onPressed: () => _sendMessage(faq['question']!),
                        label: Text(faq['question']!),
                        avatar: Text(faq['icon']!),
                        backgroundColor: Colors.pink.shade100,
                        labelStyle: TextStyle(color: Colors.pink.shade700),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          if (_messages.length > 1 && _suggestions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Suggested questions:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _suggestions.map((faq) {
                      return ActionChip(
                        onPressed: () => _sendMessage(faq['question']!),
                        label: Text(faq['question']!),
                        avatar: Text(faq['icon']!),
                        backgroundColor: Colors.pink.shade50,
                        labelStyle: TextStyle(color: Colors.pink.shade700),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

          // Input area
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    decoration: InputDecoration(
                      hintText: 'Ask me anything...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                    onSubmitted: (val) {
                      if (!_isLoading) _sendMessage(val);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  mini: true,
                  backgroundColor: Colors.pink.shade600,
                  onPressed: _isLoading ? null : () => _sendMessage(_inputController.text),
                  child: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
