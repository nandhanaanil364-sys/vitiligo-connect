import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'register_screen.dart';
import 'home_screen.dart';
import '../theme/app_theme.dart';
import 'expert_dashboard_screen.dart';
import 'admin_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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

  // ======================================================
  // LOGIN
  // ======================================================

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // ==================================================
      // FIREBASE AUTHENTICATION
      // ==================================================

      debugPrint('LOGIN: Starting Firebase authentication...');

      final credential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      debugPrint('LOGIN: Firebase authentication successful.');

      final user = credential.user;

      if (user == null) {
        throw Exception('Unable to login. User is null.');
      }

      debugPrint('LOGIN: User UID = ${user.uid}');

      final firestore = FirebaseFirestore.instance;

      // ==================================================
      // CHECK ADMIN ACCOUNT
      // ==================================================

      debugPrint('LOGIN: Checking admins collection...');

      final adminDoc =
          await firestore.collection('admins').doc(user.uid).get();

      debugPrint(
        'LOGIN: admins document exists = ${adminDoc.exists}',
      );

      if (adminDoc.exists) {
        debugPrint('LOGIN: Admin account detected.');

        if (!mounted) return;

        setState(() {
          isLoading = false;
        });

        debugPrint(
          'LOGIN: Opening AdminDashboardScreen...',
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const AdminDashboardScreen(),
          ),
        );

        return;
      }

      // ==================================================
      // CHECK NORMAL USER ACCOUNT
      // ==================================================

      debugPrint('LOGIN: Checking users collection...');

      final userDoc =
          await firestore.collection('users').doc(user.uid).get();

      debugPrint(
        'LOGIN: users document exists = ${userDoc.exists}',
      );

      if (userDoc.exists) {
        final data = userDoc.data() ?? {};

        final role = data['role']?.toString() ?? 'user';
        final status = data['status']?.toString() ?? 'active';

        debugPrint('LOGIN: role = $role');
        debugPrint('LOGIN: status = $status');

        // ----------------------------------------------
        // NORMAL USER
        // ----------------------------------------------

        if (role == 'user' && status == 'active') {
          if (!mounted) return;

          setState(() {
            isLoading = false;
          });

          debugPrint(
            'LOGIN: Opening HomeScreen...',
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  const HomeScreen(),
            ),
          );

          return;
        }

        // ----------------------------------------------
        // USER ACCOUNT NOT ACTIVE
        // ----------------------------------------------

        await FirebaseAuth.instance.signOut();

        if (!mounted) return;

        setState(() {
          isLoading = false;
        });

        _showStatusMessage(
          title: 'Account Unavailable',
          message:
              'Your account is currently not active. Please contact support.',
          icon: Icons.info_outline_rounded,
        );

        return;
      }

      // ==================================================
      // CHECK EXPERT ACCOUNT
      // ==================================================

      debugPrint(
        'LOGIN: User document not found.',
      );

      debugPrint(
        'LOGIN: Checking experts collection...',
      );

      final expertDoc =
          await firestore.collection('experts').doc(user.uid).get();

      debugPrint(
        'LOGIN: experts document exists = ${expertDoc.exists}',
      );

      if (expertDoc.exists) {
        final data = expertDoc.data() ?? {};

        final status =
            data['status']?.toString() ?? 'pending';

        final expertName =
            data['name']?.toString() ??
            user.displayName ??
            'Expert';

        final expertType =
            data['expertType']?.toString() ??
            data['specialization']?.toString() ??
            data['type']?.toString() ??
            'Expert';

        debugPrint(
          'LOGIN: Expert status = $status',
        );

        // ==================================================
        // APPROVED EXPERT
        // ==================================================

        if (status == 'approved' ||
            status == 'active') {
          if (!mounted) return;

          setState(() {
            isLoading = false;
          });

          debugPrint(
            'LOGIN: Opening ExpertDashboardScreen...',
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ExpertDashboardScreen(
                expertName: expertName,
                expertType: expertType,
              ),
            ),
          );

          return;
        }

        // ==================================================
        // PENDING EXPERT
        // ==================================================

        if (status == 'pending') {
          await FirebaseAuth.instance.signOut();

          if (!mounted) return;

          setState(() {
            isLoading = false;
          });

          _showStatusMessage(
            title: 'Approval Pending',
            message:
                'Your expert registration is still waiting for admin approval. You will be able to access the expert dashboard after your account is verified.',
            icon: Icons.hourglass_empty_rounded,
          );

          return;
        }

        // ==================================================
        // REJECTED EXPERT
        // ==================================================

        if (status == 'rejected') {
          await FirebaseAuth.instance.signOut();

          if (!mounted) return;

          setState(() {
            isLoading = false;
          });

          _showStatusMessage(
            title: 'Registration Rejected',
            message:
                'Your expert registration has been rejected. Please contact support if you believe this was a mistake.',
            icon: Icons.cancel_outlined,
          );

          return;
        }

        // ==================================================
        // SUSPENDED EXPERT
        // ==================================================

        if (status == 'suspended') {
          await FirebaseAuth.instance.signOut();

          if (!mounted) return;

          setState(() {
            isLoading = false;
          });

          _showStatusMessage(
            title: 'Account Suspended',
            message:
                'Your expert account has been temporarily suspended. Please contact support for more information.',
            icon: Icons.block_outlined,
          );

          return;
        }

        // ==================================================
        // UNKNOWN EXPERT STATUS
        // ==================================================

        await FirebaseAuth.instance.signOut();

        if (!mounted) return;

        setState(() {
          isLoading = false;
        });

        _showStatusMessage(
          title: 'Account Unavailable',
          message:
              'Your expert account cannot be accessed at this time.',
          icon: Icons.info_outline_rounded,
        );

        return;
      }

      // ==================================================
      // NO FIRESTORE PROFILE
      // ==================================================

      debugPrint(
        'LOGIN: No admins, users or experts document found.',
      );

      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      _showStatusMessage(
        title: 'Profile Not Found',
        message:
            'Your account was created, but your profile information could not be found. Please contact support.',
        icon: Icons.person_off_outlined,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('================================');
      debugPrint('FIREBASE AUTH ERROR');
      debugPrint('CODE: ${e.code}');
      debugPrint('MESSAGE: ${e.message}');
      debugPrint('================================');

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      String message;

      switch (e.code) {
        case 'invalid-credential':
          message =
              'Incorrect email or password. Please check your details and try again.';
          break;

        case 'wrong-password':
          message =
              'Incorrect password. Please try again.';
          break;

        case 'user-not-found':
          message =
              'No account was found with this email address.';
          break;

        case 'invalid-email':
          message =
              'Please enter a valid email address.';
          break;

        case 'user-disabled':
          message =
              'This account has been disabled. Please contact support.';
          break;

        case 'too-many-requests':
          message =
              'Too many login attempts. Please try again later.';
          break;

        case 'network-request-failed':
          message =
              'Network error. Please check your internet connection.';
          break;

        default:
          message =
              e.message ??
              'Firebase authentication failed.';
      }

      _showMessage(message);
    } catch (e, stackTrace) {
      debugPrint('================================');
      debugPrint('LOGIN ERROR');
      debugPrint('ERROR: $e');
      debugPrint('STACK TRACE: $stackTrace');
      debugPrint('================================');

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      _showMessage(
        'Login error: $e',
      );
    }
  }

  // ======================================================
  // SIMPLE MESSAGE
  // ======================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ======================================================
  // STATUS MESSAGE
  // ======================================================

  void _showStatusMessage({
    required String title,
    required String message,
    required IconData icon,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                icon,
                color: AppTheme.primaryDark,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(
              color: AppTheme.textGrey,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'OK',
                style: TextStyle(
                  color: AppTheme.primaryDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ======================================================
  // BUILD
  // ======================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,

      // ==================================================
      // APP BAR
      // ==================================================

      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: AppTheme.textDark,
        ),
        title: const Text(
          'Login',
          style: TextStyle(
            color: AppTheme.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // ==================================================
      // BODY
      // ==================================================

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

                // ==================================================
                // LOGO
                // ==================================================

                Center(
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration:
                        const BoxDecoration(
                      color: AppTheme.pastelGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      size: 48,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // ==================================================
                // TITLE
                // ==================================================

                const Center(
                  child: Text(
                    'Welcome Back!',
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
                    'Login to your Vitiligo Connect account',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textGrey,
                    ),
                  ),
                ),

                const SizedBox(height: 35),

                // ==================================================
                // EMAIL
                // ==================================================

                const Text(
                  'Email',
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
                  decoration: InputDecoration(
                    hintText:
                        'Enter your email',
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                    ),
                    filled: true,
                    fillColor: Colors.white,

                    border:
                        OutlineInputBorder(
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
                        color:
                            Color(0xFFE4E8E5),
                      ),
                    ),

                    focusedBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(
                        color:
                            AppTheme.primaryDark,
                        width: 1.5,
                      ),
                    ),

                    errorBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(
                        color:
                            Colors.redAccent,
                      ),
                    ),

                    focusedErrorBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(
                        color:
                            Colors.redAccent,
                        width: 1.5,
                      ),
                    ),
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

                // ==================================================
                // PASSWORD
                // ==================================================

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
                  controller:
                      passwordController,
                  obscureText:
                      obscurePassword,

                  decoration:
                      InputDecoration(
                    hintText:
                        'Enter your password',

                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                    ),

                    suffixIcon:
                        IconButton(
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

                    filled: true,
                    fillColor: Colors.white,

                    border:
                        OutlineInputBorder(
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
                        color:
                            Color(0xFFE4E8E5),
                      ),
                    ),

                    focusedBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(
                        color:
                            AppTheme.primaryDark,
                        width: 1.5,
                      ),
                    ),

                    errorBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(
                        color:
                            Colors.redAccent,
                      ),
                    ),

                    focusedErrorBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(
                        color:
                            Colors.redAccent,
                        width: 1.5,
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

                

                // ==================================================
                // LOGIN BUTTON
                // ==================================================

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed:
                        isLoading ? null : login,

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
                            'Login',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 25),

                // ==================================================
                // REGISTER
                // ==================================================

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account?",
                      style: TextStyle(
                        color:
                            AppTheme.textGrey,
                      ),
                    ),

                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Register',
                        style: TextStyle(
                          color:
                              AppTheme.primaryDark,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),


                // ==================================================
                // VERSION
                // ==================================================

                const Center(
                  child: Text(
                    'Vitiligo Connect • Version 1.0.0',
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
}