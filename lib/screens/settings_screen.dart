import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationsEnabled = true;
  bool profileVisible = true;
  bool communityMessages = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,

      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          20,
          10,
          20,
          30,
        ),
        children: [

          _sectionTitle('Notifications'),

          _settingCard(
            icon: Icons.notifications_none_rounded,
            title: 'Notifications',
            subtitle: 'Receive app notifications',
            color: AppTheme.pastelYellow,
            trailing: Switch(
              value: notificationsEnabled,
              activeColor: AppTheme.primaryDark,
              onChanged: (value) {
                setState(() {
                  notificationsEnabled = value;
                });
              },
            ),
          ),

          const SizedBox(height: 10),

          _settingCard(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'Community Messages',
            subtitle: 'Receive community updates',
            color: AppTheme.pastelBlue,
            trailing: Switch(
              value: communityMessages,
              activeColor: AppTheme.primaryDark,
              onChanged: notificationsEnabled
                  ? (value) {
                      setState(() {
                        communityMessages = value;
                      });
                    }
                  : null,
            ),
          ),

          const SizedBox(height: 25),

          _sectionTitle('Privacy'),

          _settingCard(
            icon: Icons.visibility_outlined,
            title: 'Profile Visibility',
            subtitle: profileVisible
                ? 'Your profile is visible to community members'
                : 'Your profile is hidden from community members',
            color: AppTheme.pastelGreen,
            trailing: Switch(
              value: profileVisible,
              activeColor: AppTheme.primaryDark,
              onChanged: (value) {
                setState(() {
                  profileVisible = value;
                });
              },
            ),
          ),

          const SizedBox(height: 10),

          _settingCard(
            icon: Icons.lock_outline_rounded,
            title: 'Privacy & Security',
            subtitle: 'Manage your account privacy',
            color: AppTheme.pastelPink,
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textGrey,
            ),
            onTap: () {
              _showPrivacyDialog();
            },
          ),

          const SizedBox(height: 25),

          _sectionTitle('Community Safety'),

          _settingCard(
            icon: Icons.shield_outlined,
            title: 'Community Guidelines',
            subtitle: 'Learn about safe community interaction',
            color: AppTheme.pastelBlue,
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textGrey,
            ),
            onTap: () {
              _showGuidelinesDialog();
            },
          ),

          const SizedBox(height: 10),

          _settingCard(
            icon: Icons.flag_outlined,
            title: 'Report a Problem',
            subtitle: 'Report inappropriate content or behaviour',
            color: AppTheme.pastelYellow,
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textGrey,
            ),
            onTap: () {
              _showReportDialog();
            },
          ),

          const SizedBox(height: 25),

          _sectionTitle('About'),

          _settingCard(
            icon: Icons.info_outline_rounded,
            title: 'About Vitiligo Connect',
            subtitle: 'Version 1.0.0',
            color: AppTheme.pastelGreen,
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textGrey,
            ),
            onTap: () {
              _showAboutDialog();
            },
          ),

          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _showLogoutDialog,
              icon: const Icon(
                Icons.logout_rounded,
              ),
              label: const Text(
                'Logout',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(
                  color: Color(0xFFFFCDD2),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ======================================================
  // SECTION TITLE
  // ======================================================

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.bold,
          color: AppTheme.textDark,
        ),
      ),
    );
  }

  // ======================================================
  // SETTING CARD
  // ======================================================

  Widget _settingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),

      child: Container(
        padding: const EdgeInsets.all(15),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE8ECE9),
          ),
        ),

        child: Row(
          children: [

            Container(
              width: 48,
              height: 48,

              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),

              child: Icon(
                icon,
                color: AppTheme.primaryDark,
                size: 23,
              ),
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textGrey,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  // ======================================================
  // PRIVACY
  // ======================================================

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Privacy & Security',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Your personal information should be handled '
            'securely. Privacy controls and account security '
            'features will be connected to the backend later.',
            style: TextStyle(
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // ======================================================
  // COMMUNITY GUIDELINES
  // ======================================================

  void _showGuidelinesDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Community Guidelines',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            '• Be respectful to other members.\n\n'
            '• Do not share harmful or offensive content.\n\n'
            '• Respect other people’s privacy.\n\n'
            '• Do not provide misleading medical advice.\n\n'
            '• Report inappropriate content when necessary.',
            style: TextStyle(
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // ======================================================
  // REPORT
  // ======================================================

  void _showReportDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Report a Problem',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Describe the problem...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isEmpty) {
                  return;
                }

                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Thank you. Your report has been submitted.',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  // ======================================================
  // ABOUT
  // ======================================================

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Vitiligo Connect',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          content: const Text(
            'Vitiligo Connect is a community-focused '
            'application designed to help users connect, '
            'learn, discover experts and find supportive '
            'resources related to vitiligo.\n\n'
            'Version 1.0.0',
            style: TextStyle(
              height: 1.5,
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // ======================================================
  // LOGOUT
  // ======================================================

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Logout',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          content: const Text(
            'Are you sure you want to logout?',
          ),

          actions: [

            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Logout functionality will be connected later.',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),

              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}