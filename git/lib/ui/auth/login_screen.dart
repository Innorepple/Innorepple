import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _id = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('मैत्री', style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('Connecting Health & Hearts', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.teal.shade700)),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _id,
                    decoration: const InputDecoration(labelText: 'Email or Phone'),
                    validator: (v) => (v==null||v.isEmpty)?'Required':null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (v) => (v==null||v.length<4)?'Min 4 chars':null,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _loading?null:() async {
                        if(!_form.currentState!.validate()) return;
                        setState(()=>_loading=true);
                        final err = await context.read<AuthService>().login(id: _id.text.trim(), password: _password.text.trim());
                        setState(()=>_loading=false);
                        if (err!=null) {
                          if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                        } else {
                          if(context.mounted) Navigator.pushReplacementNamed(context, '/');
                        }
                      },
                      icon: const Icon(Icons.login), label: Text(_loading?'Please wait...':'Login'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(onPressed: ()=>Navigator.pushNamed(context, '/register'), child: const Text('Create account')),
                      TextButton(onPressed: ()=>Navigator.pushNamed(context, '/forgot'), child: const Text('Forgot password?')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}