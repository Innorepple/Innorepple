import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _id = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(children: [
          TextField(controller: _id, decoration: const InputDecoration(labelText: 'Email or Phone')),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading?null:() async {
                setState(()=>_loading=true);
                final err = await context.read<AuthService>().sendPasswordReset(_id.text.trim());
                setState(()=>_loading=false);
                if (err!=null) {
                  if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                } else {
                  if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reset link/OTP sent (or local password cleared).')));
                }
              },
              child: Text(_loading?'Please wait...':'Send Reset'),
            ),
          )
        ]),
      ),
    );
  }
}