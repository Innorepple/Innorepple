import 'package:flutter/material.dart';
import '../../services/local_storage.dart';

class HealthQuestionnaire extends StatefulWidget {
  const HealthQuestionnaire({super.key});

  @override
  State<HealthQuestionnaire> createState() => _HealthQuestionnaireState();
}

class _HealthQuestionnaireState extends State<HealthQuestionnaire> {
  String hasProblems = 'No';
  String condition = '';
  String duration = 'Recently';
  String takingMeds = 'No';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar( title: const Text('Health Query (Optional)') ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Answer a few quick questions to personalise Maitree. You can skip anytime.'),
              const SizedBox(height: 16),
              _q(
                'Do you have any health problems?',
                [ 'Yes', 'No' ],
                hasProblems,
                (v)=> setState(()=>hasProblems=v),
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'What condition are you dealing with? (optional)',
                ),
                onChanged: (v)=> condition = v,
              ),
              const SizedBox(height: 10),
              _q('How long have you had it?', ['Few Years','Few Months','Recently'], duration, (v)=> setState(()=>duration=v)),
              const SizedBox(height: 10),
              _q('Are you currently taking medication?', ['Yes','No'], takingMeds, (v)=> setState(()=>takingMeds=v)),
              const Spacer(),
              Row(children: [
                Expanded(child: OutlinedButton(onPressed: (){ Navigator.pushReplacementNamed(context, '/'); }, child: const Text('Skip'))),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(onPressed: () async {
                  await LocalStorage.instance.saveKyc({
                    'hasProblems': hasProblems,
                    'condition': condition,
                    'duration': duration,
                    'takingMeds': takingMeds,
                  });
                  if (context.mounted) Navigator.pushReplacementNamed(context, '/');
                }, child: const Text('Save'))),
              ])
            ],
          ),
        ),
      ),
    );
  }

  Widget _q(String title, List<String> options, String group, ValueChanged<String> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        Wrap(
          spacing: 8,
          children: options.map((o)=> ChoiceChip(
            label: Text(o),
            selected: group==o,
            onSelected: (_)=> onChanged(o),
          )).toList(),
        )
      ],
    );
  }
}