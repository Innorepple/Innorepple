import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../health_history_screen.dart';
import '../../services/local_storage.dart';
import '../../services/notification_service.dart';

class DailyCheckupScreen extends StatefulWidget {
  const DailyCheckupScreen({super.key});

  @override
  State<DailyCheckupScreen> createState() => _DailyCheckupScreenState();
}

class _DailyCheckupScreenState extends State<DailyCheckupScreen> with TickerProviderStateMixin {
  bool remindersOn = true;
  bool tipsOn = true;
  int selectedMood = 3; // 1-5 scale
  double energyLevel = 3.0; // 1-5 scale
  double stressLevel = 2.0; // 1-5 scale
  int waterIntake = 0; // glasses of water
  int sleepHours = 8;
  bool hasExercised = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    tipsOn = LocalStorage.instance.tipsEnabled;
    remindersOn = LocalStorage.instance.remindersEnabled;
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _loadDailyData();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _loadDailyData() {
    // Load today's data from local storage
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final dailyData = LocalStorage.instance.getDailyCheckup(today);
    if (dailyData != null) {
      setState(() {
        selectedMood = dailyData['mood'] ?? 3;
        energyLevel = (dailyData['energy'] ?? 3.0).toDouble();
        stressLevel = (dailyData['stress'] ?? 2.0).toDouble();
        waterIntake = dailyData['water'] ?? 0;
        sleepHours = dailyData['sleep'] ?? 8;
        hasExercised = dailyData['exercise'] ?? false;
      });
    }
  }

  void _saveDailyData() {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final dailyData = {
      'mood': selectedMood,
      'energy': energyLevel,
      'stress': stressLevel,
      'water': waterIntake,
      'sleep': sleepHours,
      'exercise': hasExercised,
      'timestamp': DateTime.now().toIso8601String(),
    };
    LocalStorage.instance.saveDailyCheckup(today, dailyData);
  }

  @override
  Widget build(BuildContext context) {
    final meds = LocalStorage.instance.readMeds();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text('Daily Health Check-Up', style: TextStyle(color: isDark ? Colors.white : Colors.teal.shade800)),
        elevation: 0,
        backgroundColor: isDark ? Theme.of(context).appBarTheme.backgroundColor : Colors.teal.shade50,
        foregroundColor: isDark ? Colors.white : Colors.teal.shade800,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.teal.shade800),
      ),
      backgroundColor: isDark ? Theme.of(context).scaffoldBackgroundColor : Colors.teal.shade50,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 20),
            _buildMoodTracker(),
            const SizedBox(height: 20),
            _buildHealthMetrics(),
            const SizedBox(height: 20),
            _buildWaterTracker(),
            const SizedBox(height: 20),
            _buildMedicationSection(meds),
            const SizedBox(height: 20),
            _buildHealthTools(),
            const SizedBox(height: 20),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildWelcomeCard() {
    final now = DateTime.now();
    final greeting = now.hour < 12 ? 'Good Morning' : now.hour < 17 ? 'Good Afternoon' : 'Good Evening';
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$greeting! 👋',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'How are you feeling today?',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('EEEE, MMM d').format(now),
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMoodTracker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.mood, color: Colors.amber.shade700, size: 24),
              const SizedBox(width: 12),
              Text(
                'Mood Check',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('How do you feel today?', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              final mood = index + 1;
              final emojis = ['😢', '😕', '😐', '😊', '😄'];
              final isSelected = selectedMood == mood;
              
              return GestureDetector(
                onTap: () {
                  setState(() => selectedMood = mood);
                  _saveDailyData();
                },
                child: ScaleTransition(
                  scale: isSelected
                      ? Tween<double>(begin: 1.0, end: 1.2).animate(_pulseAnimation)
                      : const AlwaysStoppedAnimation(1.0),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.amber.shade100 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: isSelected ? Colors.amber.shade400 : Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        emojis[index],
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHealthMetrics() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: Colors.blue.shade700, size: 24),
              const SizedBox(width: 12),
              Text(
                'Energy & Wellness',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Energy Level
          Text('Energy Level: ${energyLevel.toInt()}/5', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
          Slider(
            value: energyLevel,
            min: 1,
            max: 5,
            divisions: 4,
            onChanged: (value) {
              setState(() => energyLevel = value);
              _saveDailyData();
            },
            activeColor: Colors.green,
          ),
          
          const SizedBox(height: 16),
          
          // Stress Level
          Text('Stress Level: ${stressLevel.toInt()}/5', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
          Slider(
            value: stressLevel,
            min: 1,
            max: 5,
            divisions: 4,
            onChanged: (value) {
              setState(() => stressLevel = value);
              _saveDailyData();
            },
            activeColor: Colors.orange,
          ),
          
          const SizedBox(height: 16),
          
          // Sleep Hours
          Text('Sleep Hours: ${sleepHours}h', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
          Slider(
            value: sleepHours.toDouble(),
            min: 4,
            max: 12,
            divisions: 8,
            onChanged: (value) {
              setState(() => sleepHours = value.toInt());
              _saveDailyData();
            },
            activeColor: Colors.indigo,
          ),
          
          const SizedBox(height: 16),
          
          // Exercise Check
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Did you exercise today?', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
            value: hasExercised,
            onChanged: (value) {
              setState(() => hasExercised = value);
              _saveDailyData();
            },
            activeThumbColor: Colors.green,
          ),
        ],
      ),
    );
  }
  
  Widget _buildWaterTracker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_drink, color: Colors.blue.shade700, size: 24),
              const SizedBox(width: 12),
              Text(
                'Water Intake',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
              ),
              const Spacer(),
              Text('${waterIntake}/8 glasses', style: TextStyle(color: isDark ? Colors.white70 : Colors.grey)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: waterIntake / 8,
                  backgroundColor: Colors.blue.shade50,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade400),
                  minHeight: 8,
                ),
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  IconButton(
                    onPressed: waterIntake > 0 ? () {
                      setState(() => waterIntake--);
                      _saveDailyData();
                    } : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  IconButton(
                    onPressed: waterIntake < 15 ? () {
                      setState(() => waterIntake++);
                      _saveDailyData();
                    } : null,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildMedicationSection(List<dynamic> meds) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.medication, color: Colors.red.shade700, size: 24),
              const SizedBox(width: 12),
              Text(
                'Medications',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _addMedicine,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (meds.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'No medications added yet.\nTap "Add" to track your medicines.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
                ),
              ),
            )
          else
            ...meds.asMap().entries.map((entry) {
              final i = entry.key;
              final m = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.medication, color: Colors.red.shade600, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m['name'] ?? 'Medication', style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(m['time'] ?? 'Time not set', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: Colors.red.shade600, size: 18),
                      onPressed: () async {
                        final list = LocalStorage.instance.readMeds();
                        if (i < list.length) {
                          list.removeAt(i);
                          await LocalStorage.instance.saveMeds(list);
                          setState(() {});
                        }
                      },
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Medication Reminders', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
            subtitle: Text('Get notifications for your medicines', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
            value: remindersOn,
            onChanged: (v) async {
              setState(() => remindersOn = v);
              await LocalStorage.instance.setRemindersEnabled(remindersOn);
              if (remindersOn) {
                _scheduleMedicationReminders();
                NotificationService.instance.showNow(
                  title: 'Maitree',
                  body: 'Medication reminders enabled! You\'ll get notifications for your medicines.',
                );
              }
            },
            activeThumbColor: Colors.red.shade400,
          ),
        ],
      ),
    );
  }
  
  Widget _buildHealthTools() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.health_and_safety, color: Colors.purple.shade700, size: 24),
              const SizedBox(width: 12),
              Text(
                'Health Tools',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildToolButton(
                  'BMI Calculator',
                  Icons.calculate,
                  Colors.blue,
                  () => _open('https://www.calculator.net/bmi-calculator.html'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildToolButton(
                  'Diet Planner',
                  Icons.restaurant_menu,
                  Colors.green,
                  () => _open('https://www.strongrfastr.com/diet-meal-planner'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildToolButton(
                  'Health History',
                  Icons.history,
                  Colors.orange,
                  _openHistory,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildToolButton(
                  'Health Tips',
                  Icons.lightbulb_outline,
                  tipsOn ? Colors.amber : Colors.grey,
                  () async {
                    setState(() => tipsOn = !tipsOn);
                    await LocalStorage.instance.setTipsEnabled(tipsOn);
                    if (tipsOn) {
                      NotificationService.instance.showNow(
                        title: 'Maitree',
                        body: 'Health tips enabled! You\'ll get daily wellness notifications.',
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildToolButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
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
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          _saveDailyData();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Daily health check-up saved! 🎉'),
              backgroundColor: Colors.green,
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'Complete Daily Check-Up',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> _addMedicine() async {
    final nameCtrl = TextEditingController();
    TimeOfDay time = TimeOfDay.now();
    final result = await showDialog<bool>(context: context, builder: (ctx){
      return AlertDialog(
        title: const Text('Add Medicine'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 8),
            Row(children:[
              const Text('Time: '),
              TextButton(onPressed: () async {
                final picked = await showTimePicker(context: context, initialTime: time);
                if (picked!=null) { time = picked; (ctx as Element).markNeedsBuild(); }
              }, child: Text('${time.hour.toString().padLeft(2,'0')}:${time.minute.toString().padLeft(2,'0')}'))
            ])
          ],
        ),
        actions: [
          TextButton(onPressed: ()=> Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: ()=> Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      );
    });
    if (result==true && nameCtrl.text.trim().isNotEmpty) {
      final meds = LocalStorage.instance.readMeds();
      meds.add({'name': nameCtrl.text.trim(), 'time': '${time.hour}:${time.minute}'});
      await LocalStorage.instance.saveMeds(meds);
      if (remindersOn) {
        await NotificationService.instance.scheduleDaily(title: 'Take ${nameCtrl.text.trim()}', body: 'Medication reminder', time: time);
      }
      if (mounted) setState((){});
    }
  }

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HealthHistoryScreen()),
    );
  }
  
  void _scheduleMedicationReminders() {
    final meds = LocalStorage.instance.readMeds();
    for (var med in meds) {
      final timeStr = med['time'] as String?;
      if (timeStr != null && timeStr.isNotEmpty) {
        // Schedule notification for medication
        NotificationService.instance.scheduleMedication(
          medName: med['name'] ?? 'Medication',
          timeStr: timeStr,
        );
      }
    }
  }
}