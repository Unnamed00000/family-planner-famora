import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/firebase_service.dart';
import '../widgets/common.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    required this.authRepository,
    required this.locale,
    required this.onLocaleChanged,
    super.key,
  });

  final AuthRepository authRepository;
  final Locale locale;
  final ValueChanged<Locale> onLocaleChanged;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final loginController = TextEditingController();
  final passwordController = TextEditingController();
  bool useFamilyLogin = false;
  bool registerMode = false;
  bool loading = false;
  String? error;

  @override
  void dispose() {
    loginController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final strings = AppStrings.of(context);
    setState(() {
      loading = true;
      error = null;
    });
    try {
      if (registerMode) {
        await widget.authRepository.registerWithEmail(loginController.text, passwordController.text);
      } else if (useFamilyLogin) {
        await widget.authRepository.signInWithFamilyLogin(loginController.text, passwordController.text);
      } else {
        await widget.authRepository.signInWithEmail(loginController.text, passwordController.text);
      }
    } on FirebaseAuthException catch (exception) {
      setState(() => error = strings.authError(exception.code, exception.message));
    } catch (exception) {
      setState(() => error = exception.toString());
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.family_restroom_rounded, size: 56, color: theme.colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    strings.appName,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    strings.tagline,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<Locale>(
                    initialValue: widget.locale,
                    decoration: InputDecoration(
                      labelText: strings.chooseLanguage,
                      prefixIcon: const Icon(Icons.language_rounded),
                    ),
                    items: [
                      for (final item in AppStrings.supportedLocales)
                        DropdownMenuItem(
                          value: item,
                          child: Text(AppStrings.languageNames[item.languageCode] ?? item.languageCode),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        widget.onLocaleChanged(value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(value: false, label: Text(strings.email), icon: const Icon(Icons.mail_rounded)),
                      ButtonSegment(value: true, label: Text(strings.familyLogin), icon: const Icon(Icons.badge_rounded)),
                    ],
                    selected: {useFamilyLogin},
                    onSelectionChanged: registerMode ? null : (value) => setState(() => useFamilyLogin = value.first),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: loginController,
                    keyboardType: useFamilyLogin ? TextInputType.text : TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: useFamilyLogin ? strings.familyLogin : strings.email,
                      prefixIcon: Icon(useFamilyLogin ? Icons.badge_rounded : Icons.mail_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: strings.password,
                      prefixIcon: const Icon(Icons.lock_rounded),
                    ),
                    onSubmitted: (_) => loading ? null : submit(),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(error!, style: TextStyle(color: theme.colorScheme.error)),
                  ],
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: loading ? null : submit,
                    icon: loading
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.login_rounded),
                    label: Text(registerMode ? strings.createAccount : strings.signIn),
                  ),
                  TextButton(
                    onPressed: loading
                        ? null
                        : () => setState(() {
                              registerMode = !registerMode;
                              useFamilyLogin = false;
                            }),
                    child: Text(registerMode ? strings.alreadyHaveAccount : strings.createEmailAccount),
                  ),
                  const SizedBox(height: 12),
                  const AppFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
