import 'package:milpress_dashboard/utils/app_colors.dart';
import 'package:milpress_dashboard/widgets/app_button.dart';
import 'package:milpress_dashboard/widgets/app_text_form_field.dart';

import '../../widgets/app_message_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_repository.dart';
import 'package:go_router/go_router.dart';

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginStateProvider);
    final loginNotifier = ref.read(loginStateProvider.notifier);

    String? errorMessage;
    bool isLoading = loginState is AsyncLoading;
    if (loginState is AsyncError) {
      errorMessage = loginState.error.toString();
    }

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest.withValues(
        alpha: 0.5,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isWide = constraints.maxWidth >= 720;
            final EdgeInsets pagePadding = EdgeInsets.symmetric(
              horizontal: isWide ? 40 : 20,
              vertical: 28,
            );

            return Center(
              child: SingleChildScrollView(
                padding: pagePadding,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 28,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: Image.asset(
                                    'assets/logo.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'MilPress',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'Welcome back!',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Use your admin account to login',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 24),
                            AppTextFormField(
                              label: 'Email',
                              controller: _emailController,
                              hintText: 'Input your email',
                              prefixIcon: const Icon(Icons.email_outlined),
                              style: AppTextFieldStyle.card,
                              autofillHints: const [
                                AutofillHints.username,
                                AutofillHints.email,
                              ],
                              textInputAction: TextInputAction.next,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Enter your email';
                                }
                                if (!value.contains('@')) {
                                  return 'Enter a valid email';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 14),
                            // Password
                            AppTextFormField(
                              label: 'Password',
                              controller: _passwordController,
                              hintText: 'Re-type your password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                tooltip: _obscurePassword
                                    ? 'Show password'
                                    : 'Hide password',
                              ),
                              obscureText: _obscurePassword,
                              style: AppTextFieldStyle.card,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) async {
                                if (!isLoading &&
                                    _formKey.currentState!.validate()) {
                                  await loginNotifier.login(
                                    _emailController.text.trim(),
                                    _passwordController.text,
                                  );
                                  if (ref.read(loginStateProvider)
                                          is AsyncData &&
                                      context.mounted) {
                                    context.go('/dashboard');
                                  }
                                }
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Enter your password';
                                }
                                if (value.length < 6) {
                                  return 'Password too short';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),
                            if (errorMessage != null) ...[
                              const SizedBox(height: 8),
                              AppMessageWidget(
                                message: errorMessage == 'Invalid credentials'
                                    ? 'Incorrect email or password. Please try again.'
                                    : 'Login failed. Please check your details and try again.',
                                type: MessageType.error,
                              ),
                            ],
                            const SizedBox(height: 8),
                            AppButton(
                              label: 'Login',
                              backgroundColor: AppColors.copBlue,
                              textColor: Colors.white,
                              outlined: false,
                              onPressed: isLoading
                                  ? null
                                  : () async {
                                      if (_formKey.currentState!.validate()) {
                                        await loginNotifier.login(
                                          _emailController.text.trim(),
                                          _passwordController.text,
                                        );
                                        if (ref.read(loginStateProvider)
                                            is AsyncData) {
                                          if (context.mounted) {
                                            context.go('/dashboard');
                                          }
                                        }
                                      }
                                    },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
