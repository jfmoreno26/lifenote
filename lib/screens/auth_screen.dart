import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Sign in / create account, with password reset.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _register = false;
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    for (final c in [_name, _email, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final auth = context.read<AuthService>();
    try {
      if (_register) {
        await auth.register(_name.text, _email.text, _password.text);
      } else {
        await auth.signIn(_email.text, _password.text);
      }
    } on AuthFailure catch (e) {
      if (mounted) showMessage(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forgot() async {
    final email = await textPrompt(context, 'Reset password',
        initial: _email.text, hint: 'you@example.com', action: 'Send link');
    if (email == null || email.isEmpty || !mounted) return;
    try {
      await context.read<AuthService>().sendPasswordReset(email);
      if (mounted) showMessage(context, 'Password reset link sent to $email');
    } on AuthFailure catch (e) {
      if (mounted) showMessage(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ln;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _form,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(color: c.primary, borderRadius: BorderRadius.circular(20)),
                      child: const Icon(Icons.sticky_note_2_rounded, color: Colors.white, size: 32),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('LifeNote',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  Text(_register ? 'Create your account' : 'Notes, habits and plans in one place',
                      textAlign: TextAlign.center, style: TextStyle(color: c.muted)),
                  const SizedBox(height: 28),
                  if (_register) ...[
                    TextFormField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(hintText: 'Full name', prefixIcon: Icon(Icons.person_outline)),
                      validator: (v) => (v ?? '').trim().isEmpty ? 'Enter your name' : null,
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(hintText: 'Email', prefixIcon: Icon(Icons.mail_outline)),
                    validator: (v) => RegExp(r'^\S+@\S+\.\S+$').hasMatch((v ?? '').trim()) ? null : 'Enter a valid email',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(
                      hintText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) => (v ?? '').length < 6 ? 'At least 6 characters' : null,
                    onFieldSubmitted: (_) => _register ? null : _submit(),
                  ),
                  if (_register) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirm,
                      obscureText: _obscure,
                      decoration:
                          const InputDecoration(hintText: 'Confirm password', prefixIcon: Icon(Icons.lock_outline)),
                      validator: (v) => v != _password.text ? 'Passwords do not match' : null,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                  ],
                  if (!_register)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(onPressed: _forgot, child: const Text('Forgot password?')),
                    )
                  else
                    const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(
                            width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(_register ? 'Create account' : 'Sign in'),
                  ),
                  const SizedBox(height: 16),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(_register ? 'Already have an account?' : 'New to LifeNote?', style: TextStyle(color: c.muted)),
                    TextButton(
                      onPressed: () => setState(() {
                        _register = !_register;
                        _form.currentState?.reset();
                      }),
                      child: Text(_register ? 'Sign in' : 'Create account'),
                    ),
                  ]),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
