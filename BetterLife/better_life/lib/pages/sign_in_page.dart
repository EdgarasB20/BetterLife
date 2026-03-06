import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../auth_service.dart';
import 'sign_up_page.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _auth = AuthService();
  final _formKey = GlobalKey<FormState>();

  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _isLoading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'Įvesk el. paštą';
    if (!value.contains('@') || !value.contains('.'))
      return 'Neteisingas el. paštas';
    return null;
  }

  String? _validatePassword(String? v) {
    final value = v ?? '';
    if (value.isEmpty) return 'Įvesk slaptažodį';
    if (value.length < 6) return 'Slaptažodis per trumpas (min. 6)';
    return null;
  }

  String _friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Neteisingas el. paštas';
      case 'user-not-found':
        return 'Tokio vartotojo nėra';
      case 'wrong-password':
        return 'Neteisingas slaptažodis';
      case 'invalid-credential':
        return 'Neteisingi prisijungimo duomenys';
      case 'user-disabled':
        return 'Paskyra išjungta';
      case 'too-many-requests':
        return 'Per daug bandymų. Pabandyk vėliau';
      case 'network-request-failed':
        return 'Tinklo klaida. Patikrink internetą';
      default:
        return 'Prisijungti nepavyko. Bandyk dar kartą';
    }
  }

  Future<void> _signIn() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _auth.signIn(email: _email.text, password: _password.text);

      // jei buvai užstumęs SignUp route, nuvalom iki pirmo
      if (mounted) {
        Navigator.of(context).popUntil((r) => r.isFirst);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _friendlyAuthError(e));
    } catch (_) {
      setState(() => _error = 'Įvyko nenumatyta klaida');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Opens a dialog where the user can request a password reset email.
  ///
  /// The dialog manages its own internal state. When it returns `true`, a
  /// snackbar is shown. This refactoring isolates all of the asynchronous
  /// activity in a dedicated widget and avoids the framework assertion that
  /// was previously triggered when the `StatefulBuilder` was torn down while
  /// dependents were still registered.
  Future<void> _resetPasswordDialog() async {
    final sent = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // neleidžiam uždaryt paspaudus už dialogo
      builder: (_) =>
          _ResetPasswordDialog(initialEmail: _email.text.trim(), auth: _auth),
    );

    if (sent == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Išsiųstas slaptažodžio atstatymo laiškas'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'BetterLife',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Prisijunk su el. paštu',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 24),

                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.withOpacity(0.25)),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _email,
                          decoration: const InputDecoration(
                            labelText: 'El. paštas',
                            prefixIcon: Icon(Icons.email_outlined),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _password,
                          decoration: InputDecoration(
                            labelText: 'Slaptažodis',
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                            ),
                          ),
                          obscureText: _obscure,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) =>
                              _isLoading ? null : _signIn(),
                          validator: _validatePassword,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isLoading ? null : _resetPasswordDialog,
                      child: const Text('Pamiršai slaptažodį?'),
                    ),
                  ),

                  const SizedBox(height: 6),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _signIn,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Prisijungti'),
                  ),

                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Neturi paskyros?'),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const SignUpPage(),
                                  ),
                                );
                              },
                        child: const Text('Registruotis'),
                      ),
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
} // --- reset password dialog widget (appended by patch)\n

/// Dialog widget responsible for sending a password reset email.
///
/// This widget keeps its own `TextEditingController` and `_sending` flag, and
/// therefore does not rely on `StatefulBuilder` in the parent. Separating it
/// reduces the risk of breaking the widget tree during tests or when the
/// parent is disposed � the previous implementation caused a `_dependents`
/// assertion in framework.dart when the dialog was torn down while it still
/// had inherited dependents.
class _ResetPasswordDialog extends StatefulWidget {
  const _ResetPasswordDialog({
    Key? key,
    required this.initialEmail,
    required this.auth,
  }) : super(key: key);

  final String initialEmail;
  final AuthService auth;

  @override
  State<_ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<_ResetPasswordDialog> {
  late final TextEditingController _controller;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_sending) return;
    final mail = _controller.text.trim();
    if (mail.isEmpty) {
      setState(() => _error = 'Įvesk el. paštą');
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      await widget.auth.sendPasswordResetEmail(mail);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(true);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _friendlyAuthError(e);
        _sending = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Nepavyko išsiųsti laiško';
        _sending = false;
      });
    }
  }

  String _friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Neteisingas el. paštas';
      case 'user-not-found':
        return 'Tokio vartotojo nėra';
      case 'wrong-password':
        return 'Neteisingas slaptažodis';
      case 'invalid-credential':
        return 'Neteisingi prisijungimo duomenys';
      case 'user-disabled':
        return 'Paskyra išjungta';
      case 'too-many-requests':
        return 'Per daug bandymų. Pabandyk vėliau';
      case 'network-request-failed':
        return 'Tinklo klaida. Patikrink internetą';
      default:
        return 'Operacija nepavyko. Bandyk dar kartą';
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => !_sending,
      child: AlertDialog(
        scrollable: true,
        title: const Text('Pamiršai slaptažodį?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'El. paštas',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: _sending ? null : () => Navigator.of(context).pop(false),
            child: const Text('Atšaukti'),
          ),
          ElevatedButton(
            onPressed: _sending ? null : _send,
            child: _sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Siųsti'),
          ),
        ],
      ),
    );
  }
}
