import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../services/notification_service.dart';
import '../services/contacts_service.dart';
// contact_model import not needed here

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  bool _sosActivated = false;
  LocationPermission? _locationPermission;

  @override
  void initState() {
    super.initState();
    _refreshPermissionStatus();
  }

  Future<void> _refreshPermissionStatus() async {
    try {
      final p = await Geolocator.checkPermission();
      setState(() => _locationPermission = p);
    } catch (_) {
      setState(() => _locationPermission = null);
    }
  }

  Future<void> _requestLocationPermission() async {
    try {
      final p = await Geolocator.requestPermission();
      setState(() => _locationPermission = p);
    } catch (_) {
      setState(() => _locationPermission = null);
    }
  }

  Future<void> _openSettings() async {
    await Geolocator.openAppSettings();
    await Geolocator.openLocationSettings();
    _refreshPermissionStatus();
  }

  Future<void> _triggerSOS() async {
    setState(() => _sosActivated = true);

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Sending emergency alert...'),
          ],
        ),
      ),
    );

    try {
      // Fetch trusted contacts from Firebase
      final contacts = await ContactsService().fetchContactsOnce();
      final trusted = contacts.where((c) => c.trusted).toList();

      // Attempt to get location (best-effort)
      Position? pos;
      try {
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          var permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          if (permission != LocationPermission.denied && permission != LocationPermission.deniedForever) {
            pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
          }
        }
      } catch (_) {
        pos = null;
      }

      // Send SOS to backend
      await NotificationService().triggerSos(
        trusted,
        message: 'Emergency! I need help.',
        latitude: pos?.latitude,
        longitude: pos?.longitude,
      );
      if (!mounted) return;
      Navigator.pop(context); // remove loading

      if (!mounted) return;
      // Show success
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('SOS Activated'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 50),
              const SizedBox(height: 16),
              const Text('Emergency alert sent to your trusted contacts'),
              const SizedBox(height: 8),
              Text(pos != null ? 'Location shared: ${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}' : 'Location unavailable'),
              const SizedBox(height: 16),
              const Text('Help is on the way. Stay safe.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (!mounted) return;
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) Navigator.pop(context); // remove loading
      if (mounted) setState(() => _sosActivated = false);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('SOS Failed'),
          content: Text('Failed to send SOS: $e'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Using WillPopScope here; PopScope replacement causes API mismatch
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async => !_sosActivated,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: _sosActivated
              ? null
              : IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.pink.shade600),
                  onPressed: () => Navigator.pop(context),
                ),
          title: Text(
            'Emergency SOS',
            style: TextStyle(
              color: Colors.pink.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
          automaticallyImplyLeading: !_sosActivated,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              
              // Status
              if (!_sosActivated)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    border: Border.all(color: Colors.blue.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Tap the red button below to send an emergency alert to your trusted contacts.',
                          style: TextStyle(color: Colors.blue.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              
              if (_sosActivated)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    border: Border.all(color: Colors.green.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SOS Activated',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Emergency alert sent. Your location is being shared.',
                              style: TextStyle(
                                color: Colors.green.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 40),

              // SOS Button
              Center(
                child: GestureDetector(
                  onTap: _sosActivated ? null : _triggerSOS,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Colors.red.shade600, Colors.red.shade800],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withAlpha(128),
                          blurRadius: 20,
                          spreadRadius: 5,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.emergency,
                          size: 60,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _sosActivated ? 'ACTIVATED' : 'SOS',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Information Section
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
                      'What happens when you press SOS?',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    _InfoItem(
                      icon: Icons.notifications_active,
                      title: 'Send Alert',
                      description:
                          'Emergency alert sent to all your trusted contacts',
                    ),
                    const SizedBox(height: 12),
                    _InfoItem(
                      icon: Icons.location_on,
                      title: 'Share Location',
                      description:
                          'Real-time location shared with trusted contacts',
                    ),
                    const SizedBox(height: 12),
                    _InfoItem(
                      icon: Icons.phone,
                      title: 'Quick Contact',
                      description:
                          'Contacts can call you immediately for assistance',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Location permission card
              if (!_sosActivated)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    border: Border.all(color: Colors.orange.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.orange.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Location Permission',
                            style: TextStyle(
                              color: Colors.orange.shade900,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _locationPermission == null
                            ? 'Unable to determine permission status.'
                            : (_locationPermission == LocationPermission.always || _locationPermission == LocationPermission.whileInUse)
                                ? 'Enabled — app can access your location when sending SOS.'
                                : (_locationPermission == LocationPermission.denied)
                                    ? 'Permission denied. Tap Request to allow access.'
                                    : 'Permission denied permanently. Open settings to grant access.',
                        style: TextStyle(color: Colors.orange.shade800, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: _requestLocationPermission,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade600),
                            child: const Text('Request Permission'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: _openSettings,
                            child: const Text('Open Settings'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),

              // Manage Contacts
              if (!_sosActivated)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      // TODO: Navigate to manage contacts
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Manage trusted contacts - Coming soon!')),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.pink.shade600),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.group, color: Colors.pink.shade600),
                        const SizedBox(width: 8),
                        Text(
                          'Manage Trusted Contacts',
                          style: TextStyle(
                            color: Colors.pink.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _InfoItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.green.shade600, size: 20),
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
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
