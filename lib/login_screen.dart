import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_constants.dart';
import 'shell/app_shell.dart';
import 'main.dart';
import 'dart:ui';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _error = tr('login_error_required');
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AppShell()),
      );
    } on AuthException catch (e) {
      setState(() {
        _error = e.message;
      });
    } catch (e) {
      setState(() {
        _error = 'Unexpected error: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/background.jpeg',
            fit: BoxFit.cover,
          ),

          // Dark overlay for readability
          Container(
            color: Colors.black.withOpacity(0.35),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    width: 420,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.18),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.20),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                        BoxShadow(
                          color:  AppConstants.primaryColor.withOpacity(0.08),
                          blurRadius: 30,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: const LinearGradient(
                              colors: [
                                AppConstants.primaryColor,
                                Color(0xFF8C6B16),
                              ],
                            ),
                          ),
                          child: Image.asset('assets/icons/logo_black.png'),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          tr('login_title'),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          tr('login_subtitle'),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: tr('login_email'),
                            labelStyle: const TextStyle(color: Colors.white70),
                            prefixIcon: const Icon(
                              Icons.email_outlined,
                              color: Colors.white70,
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.06),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.10),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: AppConstants.primaryColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscure,
                          onSubmitted: (_) => _isLoading ? null : _login(),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: tr('login_password'),
                            labelStyle: const TextStyle(color: Colors.white70),
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              color: Colors.white70,
                            ),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscure = !_obscure;
                                });
                              },
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.white70,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.06),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.10),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: AppConstants.primaryColor,
                              ),
                            ),
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A1518).withOpacity(0.85),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFF7A2F36),
                              ),
                            ),
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                color: Color(0xFFFFC7CE),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _isLoading ? null : _login,
                            child: _isLoading
                                ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                                :  Text('login_title'.tr()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  // @override
  // Widget build(BuildContext context) {
  //   final theme = Theme.of(context);
  //
  //   return Scaffold(
  //     backgroundColor: const Color(0xFF0A0A0A),
  //     body: Center(
  //       child: SingleChildScrollView(
  //         padding: const EdgeInsets.all(24),
  //         child: Container(
  //           width: 420,
  //           padding: const EdgeInsets.all(24),
  //           decoration: BoxDecoration(
  //             color: const Color(0xFF141414),
  //             borderRadius: BorderRadius.circular(24),
  //             border: Border.all(color: const Color(0xFF3A2F0B)),
  //             boxShadow: [
  //               BoxShadow(
  //                 color: const AppConstants.primaryColor.withOpacity(0.06),
  //                 blurRadius: 18,
  //                 offset: const Offset(0, 8),
  //               ),
  //             ],
  //           ),
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               Container(
  //                 padding: const EdgeInsets.all(6),
  //                 width: 68,
  //                 height: 68,
  //                 decoration: BoxDecoration(
  //                   borderRadius: BorderRadius.circular(18),
  //                   gradient: const LinearGradient(
  //                     colors: [
  //                       AppConstants.primaryColor,
  //                       Color(0xFF8C6B16),
  //                     ],
  //                   ),
  //                 ),
  //                 child: Image.asset('assets/icons/logo_black.png'),
  //               ),
  //               const SizedBox(height: 16),
  //               Text(
  //                 'Login',
  //                 style: theme.textTheme.headlineSmall?.copyWith(
  //                   fontWeight: FontWeight.w900,
  //                 ),
  //               ),
  //               const SizedBox(height: 8),
  //               Text(
  //                 'Sign in with your account',
  //                 style: theme.textTheme.bodyMedium,
  //               ),
  //               const SizedBox(height: 24),
  //               TextField(
  //                 controller: _emailController,
  //                 keyboardType: TextInputType.emailAddress,
  //                 decoration: const InputDecoration(
  //                   labelText: 'Email',
  //                   prefixIcon: Icon(Icons.email_outlined),
  //                 ),
  //               ),
  //               const SizedBox(height: 14),
  //               TextField(
  //                 controller: _passwordController,
  //                 obscureText: _obscure,
  //                 onSubmitted: (_) => _isLoading ? null : _login(),
  //                 decoration: InputDecoration(
  //                   labelText: 'Password',
  //                   prefixIcon: const Icon(Icons.lock_outline),
  //                   suffixIcon: IconButton(
  //                     onPressed: () {
  //                       setState(() {
  //                         _obscure = !_obscure;
  //                       });
  //                     },
  //                     icon: Icon(
  //                       _obscure
  //                           ? Icons.visibility_off_outlined
  //                           : Icons.visibility_outlined,
  //                     ),
  //                   ),
  //                 ),
  //               ),
  //               if (_error != null) ...[
  //                 const SizedBox(height: 14),
  //                 Container(
  //                   width: double.infinity,
  //                   padding: const EdgeInsets.all(12),
  //                   decoration: BoxDecoration(
  //                     color: const Color(0xFF2A1518),
  //                     borderRadius: BorderRadius.circular(14),
  //                     border: Border.all(color: const Color(0xFF7A2F36)),
  //                   ),
  //                   child: Text(
  //                     _error!,
  //                     style: const TextStyle(color: Color(0xFFFFC7CE)),
  //                   ),
  //                 ),
  //               ],
  //               const SizedBox(height: 20),
  //               SizedBox(
  //                 width: double.infinity,
  //                 child: FilledButton(
  //                   onPressed: _isLoading ? null : _login,
  //                   child: _isLoading
  //                       ? const SizedBox(
  //                     width: 22,
  //                     height: 22,
  //                     child: CircularProgressIndicator(strokeWidth: 2),
  //                   )
  //                       : const Text('Login'),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }
}