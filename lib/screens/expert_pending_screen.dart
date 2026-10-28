import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'login_screen.dart';

class ExpertPendingScreen extends StatelessWidget {
  const ExpertPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,

      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),

            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                // ==================================================
                // ICON
                // ==================================================

                Container(
                  width: 110,
                  height: 110,

                  decoration: const BoxDecoration(
                    color: AppTheme.pastelYellow,
                    shape: BoxShape.circle,
                  ),

                  child: const Icon(
                    Icons.hourglass_top_rounded,
                    size: 55,
                    color: AppTheme.primaryDark,
                  ),
                ),

                const SizedBox(height: 30),

                // ==================================================
                // TITLE
                // ==================================================

                const Text(
                  'Waiting for Admin Approval',
                  textAlign: TextAlign.center,

                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),

                const SizedBox(height: 14),

                // ==================================================
                // DESCRIPTION
                // ==================================================

                const Text(
                  'Your expert registration has been submitted successfully.',
                  textAlign: TextAlign.center,

                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: AppTheme.textGrey,
                  ),
                ),

                const SizedBox(height: 20),

                // ==================================================
                // STATUS CARD
                // ==================================================

                Container(
                  width: double.infinity,

                  padding: const EdgeInsets.all(20),

                  decoration: BoxDecoration(
                    color: Colors.white,

                    borderRadius:
                        BorderRadius.circular(18),

                    border: Border.all(
                      color: const Color(0xFFE5EAE7),
                    ),
                  ),

                  child: Column(
                    children: [

                      const Icon(
                        Icons.admin_panel_settings_outlined,
                        size: 36,
                        color: AppTheme.primaryDark,
                      ),

                      const SizedBox(height: 14),

                      const Text(
                        'Application Under Review',
                        textAlign: TextAlign.center,

                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        'An administrator will review your professional '
                        'details and verify your registration information.',

                        textAlign: TextAlign.center,

                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: AppTheme.textGrey,
                        ),
                      ),

                      const SizedBox(height: 18),

                      // STATUS
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 9,
                        ),

                        decoration: BoxDecoration(
                          color: AppTheme.pastelYellow,
                          borderRadius:
                              BorderRadius.circular(30),
                        ),

                        child: const Row(
                          mainAxisSize: MainAxisSize.min,

                          children: [
                            Icon(
                              Icons.pending_outlined,
                              size: 18,
                              color: AppTheme.primaryDark,
                            ),

                            SizedBox(width: 7),

                            Text(
                              'Pending Approval',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ==================================================
                // INFORMATION
                // ==================================================

                const Text(
                  'You will be able to access the Expert Dashboard '
                  'after your account is approved.',

                  textAlign: TextAlign.center,

                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: AppTheme.textGrey,
                  ),
                ),

                const SizedBox(height: 30),

                // ==================================================
                // GO TO LOGIN
                // ==================================================

                SizedBox(
                  width: double.infinity,
                  height: 52,

                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,

                        MaterialPageRoute(
                          builder: (context) =>
                              const LoginScreen(),
                        ),

                        (route) => false,
                      );
                    },

                    child: const Text(
                      'Go to Login',
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