import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:library_nitc/auth_provider.dart';
import 'package:library_nitc/main.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:library_nitc/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'google_sign_in_button_stub.dart'
    if (dart.library.js_interop) 'package:google_sign_in_web/web_only.dart'
    as google_sign_in_web;

const String _googleServerClientId = String.fromEnvironment(
  'GOOGLE_SERVER_CLIENT_ID',
);
const String _googleIosClientId = String.fromEnvironment(
  'GOOGLE_IOS_CLIENT_ID',
);

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _rollNoController = TextEditingController();
  final _empIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _googleSignIn = GoogleSignIn(
    hostedDomain: 'nitc.ac.in',
    clientId:
        kIsWeb
            ? (_googleServerClientId.isEmpty ? null : _googleServerClientId)
            : (_googleIosClientId.isEmpty ? null : _googleIosClientId),
    serverClientId:
        kIsWeb || _googleServerClientId.isEmpty ? null : _googleServerClientId,
    scopes: const ['email'],
  );
  StreamSubscription<GoogleSignInAccount?>? _googleUserSubscription;
  bool _loading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _showLegacyLogin = false;
  String? _googleIdToken;
  GoogleLoginChallenge? _googleChallenge;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _googleUserSubscription = _googleSignIn.onCurrentUserChanged.listen((
        account,
      ) {
        if (account != null) unawaited(_handleWebGoogleAccount(account));
      });
    }
  }

  @override
  void dispose() {
    _googleUserSubscription?.cancel();
    _rollNoController.dispose();
    _empIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleWebGoogleAccount(GoogleSignInAccount account) async {
    if (!mounted || _loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final idToken = (await account.authentication).idToken;
      if (idToken == null || idToken.isEmpty) {
        throw 'Google did not return an ID token. Check the Web OAuth client configuration.';
      }
      _googleIdToken = idToken;
      await _submitGoogleLogin();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _startGoogleLogin() async {
    setState(() {
      _loading = true;
      _error = null;
      _googleChallenge = null;
      _googleIdToken = null;
    });
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return;
      final idToken = (await account.authentication).idToken;
      if (idToken == null || idToken.isEmpty) {
        throw 'Google did not return an ID token. Check the OAuth client configuration.';
      }
      _googleIdToken = idToken;
      await _submitGoogleLogin();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _continueGoogleLogin() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _submitGoogleLogin();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitGoogleLogin() async {
    final idToken = _googleIdToken;
    if (idToken == null) throw 'Please sign in with Google again.';

    final challenge = await context.read<AuthProvider>().googleLogin(
      idToken,
      empId:
          _googleChallenge == GoogleLoginChallenge.facultyCredentials
              ? _empIdController.text.trim()
              : null,
      password: _googleChallenge == null ? null : _passwordController.text,
      rememberMe: _rememberMe,
    );

    if (!mounted) return;
    if (challenge != null) {
      setState(() {
        _googleChallenge = challenge;
        _passwordController.clear();
        _error = null;
      });
      return;
    }
    await _finishLogin();
  }

  Future<void> _login() async {
    final rollNo = _rollNoController.text.trim();
    final password = _passwordController.text;

    if (rollNo.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please enter your roll number and password.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await context.read<AuthProvider>().login(
        rollNo,
        password,
        rememberMe: _rememberMe,
      );

      // Guard: widget may have been disposed while we awaited the HTTP call.
      if (!mounted) return;

      await _finishLogin();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _finishLogin() async {
    if (!mounted) return;
    // If pushed from profile/protected action: pop back (Consumer rebuilds the caller).
    // If somehow the root: replace with MainPage.
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const MainPage()));
    }
  }

  Widget _passwordField() => TextField(
    controller: _passwordController,
    obscureText: _obscurePassword,
    textInputAction: TextInputAction.done,
    onSubmitted:
        (_) => _googleChallenge != null ? _continueGoogleLogin() : _login(),
    decoration: InputDecoration(
      labelText: 'Koha Password',
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: context.cs.surface,
      suffixIcon: IconButton(
        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
      ),
    ),
  );

  Widget _googleButton() {
    if (kIsWeb) {
      return AbsorbPointer(
        absorbing: _loading,
        child: google_sign_in_web.renderButton(),
      );
    }
    return OutlinedButton.icon(
      onPressed: _loading ? null : _startGoogleLogin,
      icon: const Icon(Icons.account_circle_outlined),
      label: const Text('Continue with Google'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.cs.surfaceContainerLow,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 80),
            SizedBox(
              height: 160,
              width: 160,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Image.asset('assets/main_logo.png'),
              ),
            ),
            const SizedBox(height: 48),
            if (_googleChallenge == null && !_showLegacyLogin) ...[
              SizedBox(
                width: double.infinity,
                height: 54,
                child: _googleButton(),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() => _showLegacyLogin = true),
                child: const Text('Use Koha username and password instead'),
              ),
            ],
            if (_googleChallenge != null) ...[
              Text(
                _googleChallenge == GoogleLoginChallenge.studentPassword
                    ? 'Enter your Koha password to finish signing in.'
                    : 'Enter your employee ID and Koha password.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (_googleChallenge ==
                  GoogleLoginChallenge.facultyCredentials) ...[
                TextField(
                  controller: _empIdController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Employee ID',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: context.cs.surface,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              _passwordField(),
              Row(
                children: [
                  Checkbox(
                    value: _rememberMe,
                    onChanged:
                        (value) => setState(() => _rememberMe = value ?? false),
                  ),
                  const Text('Remember me', style: TextStyle(fontSize: 14)),
                ],
              ),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _loading ? null : _continueGoogleLogin,
                  child:
                      _loading
                          ? const CircularProgressIndicator()
                          : const Text('CONTINUE'),
                ),
              ),
            ],
            if (_showLegacyLogin && _googleChallenge == null) ...[
              TextField(
                controller: _rollNoController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Roll Number / Koha User ID',
                  hintText: 'e.g. B23CS001',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: context.cs.surface,
                ),
              ),
              const SizedBox(height: 16),
              _passwordField(),
              Row(
                children: [
                  Checkbox(
                    value: _rememberMe,
                    onChanged:
                        (value) => setState(() => _rememberMe = value ?? false),
                  ),
                  const Text('Remember me', style: TextStyle(fontSize: 14)),
                ],
              ),
              TextButton(
                onPressed: () => setState(() => _showLegacyLogin = false),
                child: const Text('Back to Google sign-in'),
              ),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    color: AppColors.unavailable,
                    fontSize: 13,
                  ),
                ),
              ),
            const SizedBox(height: 24),
            if (_showLegacyLogin && _googleChallenge == null)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.cs.primary,
                    foregroundColor: context.cs.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      _loading
                          ? SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: context.cs.surface,
                              strokeWidth: 2,
                            ),
                          )
                          : const Text(
                            'LOGIN',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                ),
              ),
            const SizedBox(height: 48),
            SizedBox(
              width: 64,
              height: 78,
              child: Image.asset('assets/nitc_logo.png'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
