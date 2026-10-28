
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'expert_register_screen.dart';

class ExpertLoginScreen extends StatefulWidget {
  const ExpertLoginScreen({super.key});

  @override
  State<ExpertLoginScreen> createState() =>
      _ExpertLoginScreenState();
}

class _ExpertLoginScreenState
    extends State<ExpertLoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool obscurePassword = true;
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ================= EXPERT LOGIN =================

  void expertLogin() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    // Temporary expert login.
    // Firebase authentication will be connected later.

    Future.delayed(
      const Duration(milliseconds: 700),
      () {
        if (!mounted) return;

        setState(() {
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Expert authentication will be connected with Firebase.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,

      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,

        iconTheme: const IconThemeData(
          color: AppTheme.textDark,
        ),

        title: const Text(
          'Expert Login',
          style: TextStyle(
            color: AppTheme.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            24,
            10,
            24,
            30,
          ),

          child: Form(
            key: _formKey,

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                const SizedBox(height: 15),

                // ================= ICON =================

                Center(
                  child: Container(
                    width: 90,
                    height: 90,

                    decoration: const BoxDecoration(
                      color: AppTheme.pastelBlue,
                      shape: BoxShape.circle,
                    ),

                    child: const Icon(
                      Icons.medical_services_rounded,
                      size: 45,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ================= TITLE =================

                const Center(
                  child: Text(
                    'Expert Portal',
                    textAlign: TextAlign.center,

                    style: TextStyle(
                      fontSize: 29,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                const Center(
                  child: Text(
                    'Login to manage your professional profile and connect with the community.',
                    textAlign: TextAlign.center,

                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: AppTheme.textGrey,
                    ),
                  ),
                ),

                const SizedBox(height: 35),

                // ================= INFORMATION BOX =================

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),

                  decoration: BoxDecoration(
                    color: AppTheme.pastelGreen,
                    borderRadius:
                        BorderRadius.circular(16),
                  ),

                  child: const Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [

                      Icon(
                        Icons.verified_user_outlined,
                        color:
                            AppTheme.primaryDark,
                        size: 23,
                      ),

                      SizedBox(width: 12),

                      Expanded(
                        child: Text(
                          'This portal is for verified healthcare professionals such as dermatologists and psychologists.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color:
                                AppTheme.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // ================= EMAIL =================

                const Text(
                  'Professional Email',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),

                const SizedBox(height: 8),

                TextFormField(
                  controller: emailController,
                  keyboardType:
                      TextInputType.emailAddress,

                  decoration: _inputDecoration(
                    hint: 'Enter your professional email',
                    icon: Icons.email_outlined,
                  ),

                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Please enter your email';
                    }

                    final email =
                        value.trim();

                    if (!RegExp(
                      r'^[\w\.-]+@[\w\.-]+\.\w+$',
                    ).hasMatch(email)) {
                      return 'Please enter a valid email';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // ================= PASSWORD =================

                const Text(
                  'Password',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),

                const SizedBox(height: 8),

                TextFormField(
                  controller: passwordController,
                  obscureText: obscurePassword,

                  decoration: _inputDecoration(
                    hint: 'Enter your password',
                    icon:
                        Icons.lock_outline_rounded,

                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          obscurePassword =
                              !obscurePassword;
                        });
                      },

                      icon: Icon(
                        obscurePassword
                            ? Icons
                                .visibility_off_outlined
                            : Icons
                                .visibility_outlined,
                      ),
                    ),
                  ),

                  validator: (value) {
                    if (value == null ||
                        value.isEmpty) {
                      return 'Please enter your password';
                    }

                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }

                    return null;
                  },
                ),

                // ================= FORGOT PASSWORD =================

                Align(
                  alignment:
                      Alignment.centerRight,

                  child: TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Password recovery will be connected with Firebase later.',
                          ),
                          behavior:
                              SnackBarBehavior
                                  .floating,
                        ),
                      );
                    },

                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color:
                            AppTheme.primaryDark,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ================= LOGIN BUTTON =================

                SizedBox(
                  width: double.infinity,
                  height: 55,

                  child: ElevatedButton(
                    onPressed:
                        isLoading
                            ? null
                            : expertLogin,

                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          AppTheme.primaryDark,

                      foregroundColor:
                          Colors.white,

                      disabledBackgroundColor:
                          AppTheme.primaryDark
                              .withValues(
                            alpha: 0.6,
                          ),

                      elevation: 0,

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),
                      ),
                    ),

                    child: isLoading
                        ? const SizedBox(
                            width: 23,
                            height: 23,

                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color:
                                  Colors.white,
                            ),
                          )
                        : const Text(
                            'Expert Login',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 25),

                // ================= REGISTER EXPERT =================

                Container(
                  width: double.infinity,

                  padding:
                      const EdgeInsets.all(18),

                  decoration: BoxDecoration(
                    color:
                        AppTheme.pastelYellow,

                    borderRadius:
                        BorderRadius.circular(18),
                  ),

                  child: Column(
                    children: [

                      const Icon(
                        Icons
                            .person_add_alt_1_rounded,
                        size: 32,
                        color:
                            AppTheme.primaryDark,
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        'Not registered as an expert?',
                        textAlign:
                            TextAlign.center,

                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                              FontWeight.w600,
                          color:
                              AppTheme.textDark,
                        ),
                      ),

                      const SizedBox(height: 5),

                      const Text(
                        'Create your professional profile and become part of Vitiligo Connect.',
                        textAlign:
                            TextAlign.center,

                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color:
                              AppTheme.textGrey,
                        ),
                      ),

                      const SizedBox(height: 10),

                      SizedBox(
                        width: double.infinity,
                        height: 45,

                        child:
                            OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        const ExpertRegisterScreen(),
                              ),
                            );
                          },

                          style:
                              OutlinedButton.styleFrom(
                            foregroundColor:
                                AppTheme
                                    .primaryDark,

                            side:
                                const BorderSide(
                              color: AppTheme
                                  .primaryDark,
                            ),

                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                12,
                              ),
                            ),
                          ),

                          child: const Text(
                            'Create Expert Account',
                            style: TextStyle(
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // ================= BACK TO USER LOGIN =================

                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },

                    icon: const Icon(
                      Icons
                          .arrow_back_rounded,
                      size: 18,
                    ),

                    label: const Text(
                      'Back to User Login',
                      style: TextStyle(
                        color:
                            AppTheme.primaryDark,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ================= VERSION =================

                const Center(
                  child: Text(
                    'Vitiligo Connect • Expert Portal',
                    style: TextStyle(
                      fontSize: 11,
                      color:
                          AppTheme.textGrey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= INPUT DECORATION =================

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,

      prefixIcon: Icon(icon),

      suffixIcon: suffixIcon,

      filled: true,
      fillColor: Colors.white,

      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide:
            BorderSide.none,
      ),

      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide:
            const BorderSide(
          color: Color(0xFFE4E8E5),
        ),
      ),

      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide:
            const BorderSide(
          color: AppTheme.primaryDark,
          width: 1.5,
        ),
      ),

      errorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide:
            const BorderSide(
          color: Colors.redAccent,
        ),
      ),

      focusedErrorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide:
            const BorderSide(
          color: Colors.redAccent,
          width: 1.5,
        ),
      ),
    );
  }
}

