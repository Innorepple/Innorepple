import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _form,
            child: Column(
              children: [
                TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Full Name'), validator: _req),
                const SizedBox(height: 12),
                TextFormField(controller: _email, decoration: const InputDecoration(labelText: 'Email'), validator: _req),
                const SizedBox(height: 12),
                TextFormField(controller: _phone, decoration: const InputDecoration(labelText: 'Phone'), validator: _req),
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
                  validator: (v)=> (v==null||v.length<4)?'Min 4 chars':null
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirm, 
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirm = !_obscureConfirm;
                        });
                      },
                    ),
                  ),
                  validator: (v)=> (v!=_password.text)?'Passwords do not match':null
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading?null:() async {
                      if(!_form.currentState!.validate()) return;
                      setState(()=>_loading=true);
                      final err = await context.read<AuthService>().register(
                        name: _name.text.trim(),
                        email: _email.text.trim(),
                        phone: _phone.text.trim(),
                        password: _password.text.trim(),
                      );
                      setState(()=>_loading=false);
                      if (err!=null) {
                        if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                      } else {
                        if(context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration successful. Please log in.')));
                          Navigator.pushReplacementNamed(context, '/login');
                        }
                      }
                    },
                    child: Text(_loading?'Please wait...':'Create Account'),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _req(String? v)=> (v==null||v.isEmpty)?'Required':null;
}