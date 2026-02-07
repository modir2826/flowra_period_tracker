import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../services/auth_service.dart';
import '../services/health_log_service.dart';
import 'login_screen.dart';
import 'chatbot_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  final HealthLogService _healthLogService = HealthLogService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  String _selectedCycleLength = '28';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Account Section
            _buildSection(
              title: 'Account',
              children: [
                _buildSettingsTile(
                  icon: Icons.person,
                  title: 'Profile',
                  subtitle: 'Manage your profile information',
                  onTap: () => _showProfileDialog(),
                ),
                _buildSettingsTile(
                  icon: Icons.lock,
                  title: 'Change Password',
                  subtitle: 'Update your password',
                  onTap: () => _showChangePasswordDialog(),
                ),
              ],
            ),
            // Health Settings Section
            _buildSection(
              title: 'Health Settings',
              titleTopPadding: 8,
              children: [
                _buildDropdownTile(
                  icon: Icons.calendar_month,
                  title: 'Average Cycle Length',
                  subtitle: 'Days between periods',
                  value: _selectedCycleLength,
                  items: ['21', '24', '26', '28', '30', '32', '35'],
                  onChanged: (val) => setState(() => _selectedCycleLength = val ?? '28'),
                ),
                _buildSettingsTile(
                  icon: Icons.medical_information,
                  title: 'Health Data Export',
                  subtitle: 'Download your health logs',
                  onTap: () => _exportHealthData(),
                ),
              ],
            ),
            // Privacy & Security Section
            _buildSection(
              title: 'Privacy & Security',
              children: [
                _buildSettingsTile(
                  icon: Icons.privacy_tip,
                  title: 'Privacy Policy',
                  subtitle: 'Read our privacy terms',
                  onTap: () => _showPrivacyPolicy(),
                ),
                _buildSettingsTile(
                  icon: Icons.description,
                  title: 'Terms of Service',
                  subtitle: 'View terms and conditions',
                  onTap: () => _showTermsOfService(),
                ),
                _buildSettingsTile(
                  icon: Icons.delete_forever,
                  title: 'Delete Account',
                  subtitle: 'Permanently delete your account',
                  onTap: () => _showDeleteAccountDialog(),
                  isDestructive: true,
                ),
              ],
            ),
            // Support Section
            _buildSection(
              title: 'Support',
              children: [
                _buildSettingsTile(
                  icon: Icons.chat_bubble,
                  title: 'Ask AI Assistant',
                  subtitle: 'Get answers to your questions',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ChatbotScreen()),
                    );
                  },
                ),
                _buildSettingsTile(
                  icon: Icons.help,
                  title: 'Help & FAQ',
                  subtitle: 'Common questions and answers',
                  onTap: () => _showHelpFaq(),
                ),
                _buildSettingsTile(
                  icon: Icons.bug_report,
                  title: 'Report a Bug',
                  subtitle: 'Help us improve Flowra',
                  onTap: () => _showBugReport(),
                ),
                _buildSettingsTile(
                  icon: Icons.info,
                  title: 'About',
                  subtitle: 'Version 1.0.0 | Made with ❤️',
                  onTap: () => _showAboutDialog(),
                ),
              ],
            ),
            // Logout Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showLogoutDialog(),
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
    double titleTopPadding = 16,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, titleTopPadding, 16, 8),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.pink.shade600,
                  ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : Colors.pink.shade600),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDestructive ? Colors.red : Colors.black,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
      onTap: onTap,
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.pink.shade600),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.pink.shade600,
      ),
    );
  }

  Widget _buildDropdownTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.pink.shade600),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: DropdownButton<String>(
        value: value,
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
        underline: const SizedBox(),
      ),
    );
  }

  Widget _dialogPrimaryButton({
    required String label,
    required VoidCallback onPressed,
    IconData? icon,
    Color? color,
  }) {
    final btn = icon == null
        ? ElevatedButton(
            onPressed: onPressed,
            child: Text(label),
          )
        : ElevatedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 18),
            label: Text(label),
          );
    return btn;
  }

  Widget _dialogSecondaryButton({
    required String label,
    required VoidCallback onPressed,
    IconData? icon,
  }) {
    final btn = icon == null
        ? TextButton(onPressed: onPressed, child: Text(label))
        : TextButton.icon(onPressed: onPressed, icon: Icon(icon, size: 18), label: Text(label));
    return btn;
  }

  ButtonStyle _primaryButtonStyle({Color? backgroundColor}) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor ?? Colors.pink.shade600,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
    );
  }

  ButtonStyle _secondaryButtonStyle() {
    return TextButton.styleFrom(
      foregroundColor: Colors.pink.shade600,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This feature is coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showProfileDialog() async {
    final user = _firebaseAuth.currentUser;
    final nameCtrl = TextEditingController(text: user?.displayName ?? '');
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Display name'),
            ),
          ],
        ),
        actions: [
          _dialogSecondaryButton(
            label: 'Cancel',
            icon: Icons.close,
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                await user?.updateDisplayName(nameCtrl.text.trim());
                if (!mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to update profile: $e')),
                );
              }
            },
            icon: const Icon(Icons.save),
            label: const Text('Save Changes'),
            style: _primaryButtonStyle(),
          ),
        ],
      ),
    );
  }

  Future<void> _showChangePasswordDialog() async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current password'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: newCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New password'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: confirmCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm new password'),
            ),
          ],
        ),
        actions: [
          _dialogSecondaryButton(
            label: 'Cancel',
            icon: Icons.close,
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              if (newCtrl.text != confirmCtrl.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('New passwords do not match')),
                );
                return;
              }
              try {
                final user = _firebaseAuth.currentUser;
                final email = user?.email;
                if (user == null || email == null) {
                  throw Exception('Not authenticated');
                }
                final credential = EmailAuthProvider.credential(
                  email: email,
                  password: currentCtrl.text,
                );
                await user.reauthenticateWithCredential(credential);
                await user.updatePassword(newCtrl.text);
                if (!mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password updated')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to update password: $e')),
                );
              }
            },
            icon: const Icon(Icons.lock_reset),
            label: const Text('Update Password'),
            style: _primaryButtonStyle(),
          ),
        ],
      ),
    );
  }

  Future<void> _exportHealthData() async {
    try {
      final logs = await _healthLogService.fetchLogsOnce();
      final payload = logs.map((l) => l.toJson()).toList();
      final jsonStr = payload.map((e) => e.toString()).join('\n');
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Health Data Export'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: SelectableText(jsonStr),
            ),
          ),
        actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: jsonStr));
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')),
                );
              },
              style: _secondaryButtonStyle(),
              child: const Text('Copy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              style: _secondaryButtonStyle(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  void _showPrivacyPolicy() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'We only collect data you enter to provide tracking and insights. '
            'Your data is stored securely and is not sold or shared with third parties. '
            'You can delete your data at any time from Settings.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: _secondaryButtonStyle(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Text(
            'Flowra provides wellness tracking tools and safety features. '
            'It is not a substitute for professional medical advice. '
            'Use the SOS feature responsibly and verify your contact information.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: _secondaryButtonStyle(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHelpFaq() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Help & FAQ'),
        content: const SingleChildScrollView(
          child: Text(
            '• Track your cycle in the Period Tracker.\n'
            '• Log mood, energy, and pain in Health Logging.\n'
            '• Use Insights to view trends.\n'
            '• Add trusted contacts for SOS alerts.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: _secondaryButtonStyle(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showBugReport() {
    final template = 'Flowra Bug Report\\n'
        '1) What happened?\\n'
        '2) Steps to reproduce:\\n'
        '3) Expected result:\\n'
        '4) Actual result:\\n'
        '5) Device/OS:\\n';
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report a Bug'),
        content: const Text('Copy the template and send it to support@flowra.app'),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: template));
              if (!mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bug report template copied')),
              );
            },
            style: _secondaryButtonStyle(),
            child: const Text('Copy Template'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: _secondaryButtonStyle(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Flowra',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2026 Flowra. All rights reserved.\nMade with ❤️ for women\'s health and safety.',
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text(
            'Flowra is a comprehensive period tracker and women\'s safety companion app designed to help you manage your health and stay safe.',
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          _dialogSecondaryButton(
            label: 'Cancel',
            icon: Icons.close,
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              await _authService.logout();
              if (!mounted) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: _primaryButtonStyle(backgroundColor: Colors.red.shade600),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'This action cannot be undone. All your data will be permanently deleted. Are you sure?',
        ),
        actions: [
          _dialogSecondaryButton(
            label: 'Cancel',
            icon: Icons.close,
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final user = _firebaseAuth.currentUser;
                final uid = user?.uid;
                if (uid == null) throw Exception('Not authenticated');

                // Best-effort data cleanup
                await _db.ref('health_logs/$uid').remove();
                await _db.ref('cycles/$uid').remove();
                await _db.ref('recent_cycles/$uid').remove();
                await _db.ref('contacts/$uid').remove();

                await user?.delete();
                if (!mounted) return;
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Delete failed: $e')),
                );
              }
            },
            icon: const Icon(Icons.delete_forever),
            label: const Text('Delete Account'),
            style: _primaryButtonStyle(backgroundColor: Colors.red.shade700),
          ),
        ],
      ),
    );
  }
}
