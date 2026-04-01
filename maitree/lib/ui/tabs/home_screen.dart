import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/local_storage.dart';
import '../../services/auth_service.dart';
import '../../services/location_service.dart';
import '../calendar_screen.dart';
import 'daily_checkup_screen.dart';
import 'med_bot_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _tapCount = 0;
  Timer? _tapTimer;
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _tapTimer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to open link')));
    }
  }

  void _onSosTap() async {
    _tapCount++;
    _tapTimer?.cancel();
    _tapTimer = Timer(const Duration(seconds: 3), () => _tapCount = 0);
    
    if (_tapCount >= 5) {
      _tapCount = 0;
      
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                SizedBox(width: 16),
                Text('Getting your location for emergency...'),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      
      try {
        // Get current location
        final position = await LocationService.instance.getEmergencyLocation();
        final auth = context.read<AuthService>();
        
        String locationText = 'Emergency! Need ambulance';
        Map<String, dynamic>? locationData;
        
        if (position != null) {
          locationText = LocationService.instance.formatLocationForSMS(position);
          
          // Create location data for Firestore
          locationData = LocationService.instance.createLocationData(
            position, 
            auth.email ?? auth.phone ?? 'unknown_user'
          );
          
          // Store emergency location in Firestore
          await _storeEmergencyLocation(locationData, auth);
        } else {
          locationText = 'Emergency! Need ambulance at my location. Unable to get GPS coordinates.';
        }
        
        // Send SMS with location
        final uri = Uri(scheme: 'smsto', path: '108', queryParameters: {'body': locationText});
        await launchUrl(uri);
        
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(position != null 
                ? 'Emergency alert sent with your location!' 
                : 'Emergency alert sent (location unavailable)'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print('Error in SOS function: $e');
        
        // Fallback: send SMS without location
        final uri = Uri(scheme: 'smsto', path: '108', queryParameters: {
          'body': 'Emergency! Need ambulance. Location services unavailable.'
        });
        await launchUrl(uri);
        
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Emergency alert sent (location unavailable)'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    }
  }
  
  Future<void> _storeEmergencyLocation(Map<String, dynamic> locationData, AuthService auth) async {
    try {
      // Add user information
      locationData['userName'] = auth.name ?? 'Unknown';
      locationData['userEmail'] = auth.email ?? 'Unknown';
      locationData['userPhone'] = auth.phone ?? 'Unknown';
      locationData['emergencyType'] = 'SOS_BUTTON';
      
      // Store in Firestore
      await FirebaseFirestore.instance
          .collection('emergency_alerts')
          .add(locationData);
      
      print('Emergency location stored in Firestore');
    } catch (e) {
      print('Error storing emergency location: $e');
      // Don't throw error - emergency SMS should still work
    }
  }
  

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final now = DateTime.now();
    final meds = LocalStorage.instance.readMeds();
    
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          floating: false,
          expandedHeight: 160,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2E7D6B), Color(0xFF4CAF50)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.white24,
                            child: Icon(Icons.person, color: Colors.white, size: 32),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getGreeting(now.hour),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  auth.name ?? 'Friend',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _weatherWidget(),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildListDelegate([
            const SizedBox(height: 16),
            _healthOverview(),
            const SizedBox(height: 16),
            _quickActions(context),
            const SizedBox(height: 16),
            _sosCard(),
            const SizedBox(height: 16),
            _medicationCard(meds),
            const SizedBox(height: 16),
            _healthTips(),
            const SizedBox(height: 16),
            _resourcesSection(),
            const SizedBox(height: 32),
          ]),
        )
      ],
    );
  }

  Widget _sosCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.red.withValues(alpha: 0.1) : Colors.red.shade50, 
          borderRadius: BorderRadius.circular(16), 
          border: Border.all(color: isDark ? Colors.red.withValues(alpha: 0.3) : Colors.red.shade100)
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ScaleTransition(
                  scale: Tween(begin: 0.95, end: 1.05).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), shape: const StadiumBorder()),
                    onPressed: _onSosTap,
                    child: const Text('SOS'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'If pressed without valid reason, ₹5000 fine applies. Tap 5 times rapidly to alert ambulance (SMS to 108).',
                    style: TextStyle(color: isDark ? Theme.of(context).textTheme.bodyMedium?.color : Colors.black87),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting(int hour) {
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Widget _weatherWidget() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          Icon(Icons.wb_sunny, color: Colors.white, size: 20),
          SizedBox(height: 4),
          Text('24°C', style: TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _healthOverview() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isDark ? LinearGradient(
            colors: [Theme.of(context).cardColor, Theme.of(context).cardColor.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ) : const LinearGradient(
            colors: [Color(0xFFF8FFF8), Color(0xFFE8F5E8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.health_and_safety, color: Colors.green[700], size: 24),
                const SizedBox(width: 12),
                Text(
                  'Health Overview',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.headlineSmall?.color),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _healthMetric('Heart Rate', '72 BPM', Icons.favorite, Colors.red),
                const SizedBox(width: 16),
                _healthMetric('Steps Today', '8,543', Icons.directions_walk, Colors.blue),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _healthMetric('Water Intake', '1.2L / 2L', Icons.local_drink, Colors.cyan),
                const SizedBox(width: 16),
                _healthMetric('Sleep', '7h 30m', Icons.bedtime, Colors.indigo),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _healthMetric(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
            Text(label, style: TextStyle(fontSize: 10, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7))),
          ],
        ),
      ),
    );
  }

  Widget _quickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.headlineSmall?.color),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _quickActionButton(
                'Med Bot',
                Icons.smart_toy,
                const Color(0xFF4CAF50),
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MedBotScreen()),
                ),
              ),
              const SizedBox(width: 12),
              _quickActionButton(
                'Daily Checkup',
                Icons.health_and_safety,
                const Color(0xFF2196F3),
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DailyCheckupScreen()),
                ),
              ),
              const SizedBox(width: 12),
              _quickActionButton(
                'Calendar',
                Icons.calendar_today,
                const Color(0xFFFF9800),
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarScreen())),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _medicationCard(List<dynamic> meds) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Theme.of(context).cardColor : Colors.blue[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.blue.withValues(alpha: 0.3) : Colors.blue[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.medication, color: Colors.blue[700]),
                const SizedBox(width: 12),
                Text(
                  'Medication Tracker',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).textTheme.headlineSmall?.color),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarScreen())),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (meds.isEmpty)
              Text('No medications scheduled today', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color))
            else
              ...meds.take(3).map((med) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.circle, color: Colors.green, size: 8),
                    const SizedBox(width: 8),
                    Text(med['name'] ?? 'Medication', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
                    const Spacer(),
                    Text(med['time'] ?? 'Time not set', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7))),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _healthTips() {
    final tips = [
      'Drink at least 8 glasses of water daily',
      'Take a 10-minute walk after meals',
      'Practice deep breathing for stress relief',
      'Get 7-8 hours of quality sleep',
      'Eat plenty of fruits and vegetables',
    ];
    
    final randomTip = tips[Random().nextInt(tips.length)];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isDark ? LinearGradient(
            colors: [Theme.of(context).cardColor, Theme.of(context).cardColor.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ) : const LinearGradient(
            colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(Icons.lightbulb_outline, color: Colors.orange[700], size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Health Tip of the Day',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Theme.of(context).textTheme.headlineSmall?.color : Colors.orange[800]),
                  ),
                  const SizedBox(height: 4),
                  Text(randomTip, style: TextStyle(fontSize: 13, color: isDark ? Theme.of(context).textTheme.bodyMedium?.color : Colors.orange[700])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resourcesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Health Resources',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.headlineSmall?.color),
          ),
          const SizedBox(height: 12),
          _resourceCard(
            'Support a Life — Donate',
            'Your contribution saves lives',
            Icons.favorite_rounded,
            Colors.red,
            () => _open('https://praveen-kumar-goswami.github.io/Donation-For-Maitree-/'),
          ),
          const SizedBox(height: 8),
          _resourceCard(
            'Pregnancy Health Tips',
            'Better Health Channel',
            Icons.pregnant_woman,
            Colors.pink,
            () => _open('https://www.betterhealth.vic.gov.au/health/healthyliving/pregnancy-and-diet'),
          ),
          const SizedBox(height: 8),
          _resourceCard(
            'Health Education',
            'Comprehensive health resources',
            Icons.school,
            Colors.purple,
            () => _open('https://www.scarleteen.com'),
          ),
        ],
      ),
    );
  }

  Widget _resourceCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
