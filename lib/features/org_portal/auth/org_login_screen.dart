import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../utils/app_colors.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_text_form_field.dart';
import '../../../widgets/app_message_widget.dart';
import 'org_session_provider.dart';

// =============================================================================
// OrgLoginScreen
// Route: /org-login
// =============================================================================
class OrgLoginScreen extends ConsumerStatefulWidget {
  const OrgLoginScreen({super.key});

  @override
  ConsumerState<OrgLoginScreen> createState() => _OrgLoginScreenState();
}

class _OrgLoginScreenState extends ConsumerState<OrgLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Supabase auth login
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (response.user == null) {
        setState(() {
          _errorMessage = 'Incorrect email or password. Please try again.';
          _isLoading = false;
        });
        return;
      }

      // 2. Resolve org context
      final session = await ref.read(orgSessionProvider.notifier).resolve();

      if (!mounted) return;

      if (session == null) {
        // Not an org admin — check if it's a subscription error
        final orgState = ref.read(orgSessionProvider);
        if (orgState is AsyncError &&
            orgState.error == OrgPortalError.subscriptionInactive) {
          setState(() {
            _errorMessage = OrgPortalError.subscriptionInactive.message;
          });
        } else {
          setState(() {
            _errorMessage = OrgPortalError.notAnOrgAdmin.message;
          });
        }
        // Sign them out so they're not stuck in a weird auth state
        await Supabase.instance.client.auth.signOut();
      } else {
        context.go('/org/overview');
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message.contains('Invalid login credentials')
            ? 'Incorrect email or password. Please try again.'
            : e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Login failed. Please check your details and try again.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest.withValues(alpha: 0.5),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 720;
            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 40 : 20,
                  vertical: 28,
                ),
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
                            // Logo + product name
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
                              'Organization Portal',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Sign in to manage your organization',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Email
                            AppTextFormField(
                              label: 'Email',
                              controller: _emailController,
                              hintText: 'Your email address',
                              prefixIcon: const Icon(Icons.email_outlined),
                              style: AppTextFieldStyle.card,
                              autofillHints: const [
                                AutofillHints.username,
                                AutofillHints.email,
                              ],
                              textInputAction: TextInputAction.next,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Enter your email';
                                if (!v.contains('@')) return 'Enter a valid email';
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            // Password
                            AppTextFormField(
                              label: 'Password',
                              controller: _passwordController,
                              hintText: 'Your password',
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
                              ),
                              obscureText: _obscurePassword,
                              style: AppTextFieldStyle.card,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _login(),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Enter your password';
                                if (v.length < 6) return 'Password too short';
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),

                            // Error
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 8),
                              AppMessageWidget(
                                message: _errorMessage!,
                                type: MessageType.error,
                              ),
                            ],
                            const SizedBox(height: 16),

                            // Login button
                            AppButton(
                              label: _isLoading ? 'Signing in…' : 'Sign in',
                              backgroundColor: AppColors.copBlue,
                              textColor: Colors.white,
                              outlined: false,
                              onPressed: _isLoading ? null : _login,
                            ),
                            const SizedBox(height: 20),

                            // Link to admin login
                            Center(
                              child: GestureDetector(
                                onTap: () => context.go('/login'),
                                child: Text.rich(
                                  TextSpan(
                                    text: 'Are you a MilPress admin? ',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Sign in here →',
                                        style: TextStyle(
                                          color: AppColors.primaryColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
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
