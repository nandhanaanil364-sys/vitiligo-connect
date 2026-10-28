
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme/app_theme.dart';
import 'settings_screen.dart';
import 'login_screen.dart';
import 'collaborator_application_screen.dart';
import 'collaborative_event_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Map<String, dynamic> profile = {};
  bool isLoading = true;
  bool isSaving = false;

  final List<String> districts = const [
    'Alappuzha',
    'Ernakulam',
    'Idukki',
    'Kannur',
    'Kasaragod',
    'Kollam',
    'Kottayam',
    'Kozhikode',
    'Malappuram',
    'Palakkad',
    'Pathanamthitta',
    'Thiruvananthapuram',
    'Thrissur',
    'Wayanad',
  ];

  final List<String> occupations = const [
    'School Student',
    'College/University Student',
    'Employed',
    'Self-employed',
    'Business Owner',
    'Homemaker',
    'Job Seeking',
    'Retired',
    'Other',
  ];

  final List<String> genders = const [
    'Female',
    'Male',
    'Other',
    'Prefer not to say',
  ];

  final List<String> durations = const [
    'Less than 1 year',
    '1 - 3 years',
    '3 - 5 years',
    '5 - 10 years',
    'More than 10 years',
  ];

  final List<String> areas = const [
    'Face',
    'Hands',
    'Arms',
    'Legs',
    'Feet',
    'Back',
    'Chest',
    'Around Eyes',
    'Around Mouth',
    'Other',
  ];

  final List<String> yesNoOptions = const [
    'Yes',
    'No',
    'Not sure',
  ];

  final List<String> bloodGroups = const [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-',
    'O+', 'O-', 'Unknown', 'Prefer not to say',
  ];

  final List<String> treatmentOptions = const [
    'Currently receiving treatment',
    'Previously treated',
    'Not receiving treatment',
    'Prefer not to say',
  ];

  final List<String> previousTreatmentOptions = const [
    'Topical treatment',
    'Phototherapy',
    'Other treatment',
    'None',
    'Prefer not to say',
  ];

  final List<String> supportOptions = const [
    'Learn about vitiligo',
    'Emotional support',
    'Expert advice',
    'Workplace support',
    'Relationship & family support',
    'Community discussions',
    'Awareness events',
  ];

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  String _stringValue(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  List<String> _stringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return [];
  }

  Future<void> loadProfile() async {
    final user = _auth.currentUser;

    if (user == null) {
      if (mounted) setState(() => isLoading = false);
      return;
    }

    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      final data = doc.data() ?? {};

      if (!mounted) return;

      setState(() {
        profile = {
          ...data,
          'name': data['name'] ?? user.displayName ?? '',
          'email': data['email'] ?? user.email ?? '',
          'age': data['age'],
          'gender': data['gender'],
          'occupation': data['occupation'],
          'district': data['district'],
          'vitiligoDuration': data['vitiligoDuration'],
          'affectedAreas': _stringList(data['affectedAreas']),
          'spreading': data['spreading'],
          'diagnosis': data['diagnosis'],
          'bloodGroup': data['bloodGroup'],
          'allergies': data['allergies'],
          'treatmentStatus': data['treatmentStatus'],
          'previousTreatment': data['previousTreatment'],
          'supportInterests': _stringList(data['supportInterests']),
        };
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      _message('Unable to load your profile. Please try again.');
    }
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _saveProfile(
    BuildContext dialogContext,
    Map<String, dynamic> updated,
  ) async {
    final user = _auth.currentUser;
    if (user == null) {
      _message('Please log in again.');
      return;
    }

    final age = int.tryParse(_stringValue(updated['age']).trim());
    if (age == null || age < 1 || age > 120) {
      _message('Please enter a valid age between 1 and 120.');
      return;
    }

    setState(() => isSaving = true);

    try {
      final name = _stringValue(updated['name']).trim();

      await _db.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': name,
        'email': user.email ?? profile['email'] ?? '',
        'age': age,
        'gender': updated['gender'],
        'occupation': updated['occupation'],
        'district': updated['district'],
        'vitiligoDuration': updated['vitiligoDuration'],
        'affectedAreas': List<String>.from(updated['affectedAreas'] ?? []),
        'spreading': updated['spreading'],
        'diagnosis': updated['diagnosis'],
        'bloodGroup': updated['bloodGroup'],
        'allergies': _stringValue(updated['allergies']).trim(),
        'treatmentStatus': updated['treatmentStatus'],
        'previousTreatment': updated['previousTreatment'],
        'supportInterests':
            List<String>.from(updated['supportInterests'] ?? []),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await user.updateDisplayName(name);

      if (!mounted) return;

      setState(() {
        profile = {
          ...profile,
          ...updated,
          'name': name,
          'email': user.email ?? profile['email'] ?? '',
          'age': age,
        };
        isSaving = false;
      });

      Navigator.of(dialogContext).pop();
      _message('Profile updated successfully.');
    } catch (e) {
      if (!mounted) return;
      setState(() => isSaving = false);
      _message('Could not save your profile. Please try again.');
    }
  }

  Future<void> _editProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      _message('Please log in again.');
      return;
    }

    final nameController =
        TextEditingController(text: _stringValue(profile['name']));
    final ageController =
        TextEditingController(text: _stringValue(profile['age']));
    final allergiesController =
        TextEditingController(text: _stringValue(profile['allergies']));

    String? gender = profile['gender']?.toString();
    String? occupation = profile['occupation']?.toString();
    String? district = profile['district']?.toString();
    String? duration = profile['vitiligoDuration']?.toString();
    String? spreadingValue = profile['spreading']?.toString();
    String? diagnosisValue = profile['diagnosis']?.toString();
    String? bloodGroup = profile['bloodGroup']?.toString();
    String? treatment = profile['treatmentStatus']?.toString();
    String? previousTreatment =
        profile['previousTreatment']?.toString();

    List<String> selectedAreas =
        _stringList(profile['affectedAreas']);
    List<String> selectedSupport =
        _stringList(profile['supportInterests']);

    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      barrierDismissible: !isSaving,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Widget sectionTitle(String title) {
              return Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 10),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryDark,
                  ),
                ),
              );
            }

            InputDecoration decoration(String label) {
              return InputDecoration(
                labelText: label,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              );
            }

            Widget dropdownField({
              required String label,
              required String? value,
              required List<String> options,
              required ValueChanged<String?> onChanged,
            }) {
              // Preserve existing values even if they are not in the
              // current registration options.
              final available = List<String>.from(options);
              if (value != null &&
                  value.isNotEmpty &&
                  !available.contains(value)) {
                available.insert(0, value);
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: DropdownButtonFormField<String>(
                  value: value != null && value.isNotEmpty
                      ? value
                      : null,
                  isExpanded: true,
                  decoration: decoration(label),
                  items: available.map((item) {
                    return DropdownMenuItem<String>(
                      value: item,
                      child: Text(item, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: onChanged,
                ),
              );
            }

            Widget multiSelect({
              required String label,
              required List<String> options,
              required List<String> selected,
            }) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: options.map((item) {
                      return FilterChip(
                        label: Text(item),
                        selected: selected.contains(item),
                        onSelected: (checked) {
                          setDialogState(() {
                            if (checked) {
                              if (!selected.contains(item)) {
                                selected.add(item);
                              }
                            } else {
                              selected.remove(item);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              );
            }

            return AlertDialog(
              title: const Text('Edit Full Profile'),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        sectionTitle('Account Details'),
                        TextFormField(
                          controller: nameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: decoration('Full name *'),
                          validator: (value) {
                            if (value == null || value.trim().length < 2) {
                              return 'Enter your full name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          initialValue: user.email ?? _stringValue(profile['email']),
                          readOnly: true,
                          decoration: decoration('Email (cannot be changed here)'),
                        ),

                        sectionTitle('Personal Details'),
                        TextFormField(
                          controller: ageController,
                          keyboardType: TextInputType.number,
                          decoration: decoration('Age *'),
                          validator: (value) {
                            final age = int.tryParse(value?.trim() ?? '');
                            if (age == null || age < 1 || age > 120) {
                              return 'Enter an age from 1 to 120';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        dropdownField(
                          label: 'Gender',
                          value: gender,
                          options: genders,
                          onChanged: (value) =>
                              setDialogState(() => gender = value),
                        ),
                        dropdownField(
                          label: 'Occupation',
                          value: occupation,
                          options: occupations,
                          onChanged: (value) =>
                              setDialogState(() => occupation = value),
                        ),
                        dropdownField(
                          label: 'District',
                          value: district,
                          options: districts,
                          onChanged: (value) =>
                              setDialogState(() => district = value),
                        ),

                        sectionTitle('Vitiligo Journey'),
                        dropdownField(
                          label: 'How long have you had vitiligo?',
                          value: duration,
                          options: durations,
                          onChanged: (value) =>
                              setDialogState(() => duration = value),
                        ),
                        multiSelect(
                          label: 'Affected body areas',
                          options: areas,
                          selected: selectedAreas,
                        ),
                        dropdownField(
                          label: 'Is it currently spreading?',
                          value: spreadingValue,
                          options: yesNoOptions,
                          onChanged: (value) =>
                              setDialogState(() => spreadingValue = value),
                        ),
                        dropdownField(
                          label: 'Have you received a diagnosis?',
                          value: diagnosisValue,
                          options: yesNoOptions,
                          onChanged: (value) =>
                              setDialogState(() => diagnosisValue = value),
                        ),

                        sectionTitle('Health Details'),
                        dropdownField(
                          label: 'Blood group',
                          value: bloodGroup,
                          options: bloodGroups,
                          onChanged: (value) =>
                              setDialogState(() => bloodGroup = value),
                        ),
                        TextFormField(
                          controller: allergiesController,
                          maxLines: 3,
                          decoration: decoration('Known allergies'),
                        ),
                        const SizedBox(height: 14),
                        dropdownField(
                          label: 'Current treatment status',
                          value: treatment,
                          options: treatmentOptions,
                          onChanged: (value) =>
                              setDialogState(() => treatment = value),
                        ),
                        dropdownField(
                          label: 'Previous vitiligo treatment',
                          value: previousTreatment,
                          options: previousTreatmentOptions,
                          onChanged: (value) =>
                              setDialogState(() => previousTreatment = value),
                        ),

                        sectionTitle('Support Preferences'),
                        multiSelect(
                          label: 'Select all that interest you',
                          options: supportOptions,
                          selected: selectedSupport,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () {
                          if (!(formKey.currentState?.validate() ?? false)) {
                            return;
                          }

                          _saveProfile(dialogContext, {
                            'name': nameController.text.trim(),
                            'age': ageController.text.trim(),
                            'gender': gender,
                            'occupation': occupation,
                            'district': district,
                            'vitiligoDuration': duration,
                            'affectedAreas': selectedAreas,
                            'spreading': spreadingValue,
                            'diagnosis': diagnosisValue,
                            'bloodGroup': bloodGroup,
                            'allergies': allergiesController.text.trim(),
                            'treatmentStatus': treatment,
                            'previousTreatment': previousTreatment,
                            'supportInterests': selectedSupport,
                          });
                        },
                  child: isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    ageController.dispose();
    allergiesController.dispose();
  }

  String _display(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return 'Not provided';
    }
    return value.toString();
  }

  String _displayList(dynamic value) {
    final items = _stringList(value);
    return items.isEmpty ? 'Not provided' : items.join(', ');
  }

  Widget _section(String title, IconData icon, List<Widget> children) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4E8E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryDark),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textGrey,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              _display(value),
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _option({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppTheme.pastelBlue,
        child: Icon(icon, color: AppTheme.primaryDark),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }

  Widget _collaboratorSection() {
    final user = _auth.currentUser;

    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _db
          .collection('collaboratorApplications')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _section(
            'Community',
            Icons.groups_outlined,
            [
              const Text(
                'Unable to load collaborator status. Please try again later.',
              ),
            ],
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _section(
            'Community',
            Icons.groups_outlined,
            [
              const Center(child: CircularProgressIndicator()),
            ],
          );
        }

        final document = snapshot.data;
        final data = document?.data();

        if (document == null || !document.exists || data == null) {
          return _section(
            'Community',
            Icons.groups_outlined,
            [
              _option(
                icon: Icons.volunteer_activism_outlined,
                title: 'Community Collaborator',
                subtitle: 'Apply to support vitiligo awareness.',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CollaboratorApplicationScreen(),
                    ),
                  );
                },
              ),
            ],
          );
        }

        final status = _stringValue(data['status']).toLowerCase();

        if (status == 'approved') {
          return _section(
            'Community',
            Icons.groups_outlined,
            [
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.check_circle, color: Colors.green),
                title: Text('Community Collaborator'),
                subtitle: Text('Your application has been approved.'),
              ),
              _option(
                icon: Icons.event_available_outlined,
                title: 'Create Collaborative Event',
                subtitle: 'Propose an event for review.',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CollaborativeEventScreen(),
                    ),
                  );
                },
              ),
            ],
          );
        }

        if (status == 'pending') {
          return _section(
            'Community',
            Icons.groups_outlined,
            [
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.hourglass_top, color: Colors.orange),
                title: Text('Application Pending'),
                subtitle: Text('Your application is awaiting review.'),
              ),
            ],
          );
        }

        return _section(
          'Community',
          Icons.groups_outlined,
          [
            _option(
              icon: Icons.volunteer_activism_outlined,
              title: 'Community Collaborator',
              subtitle: 'View the application or apply again.',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CollaboratorApplicationScreen(),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await _auth.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _showHelp() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Text(
          'For account or app issues, please contact your Vitiligo Connect '
          'project administrator. If you need medical advice, consult a '
          'qualified healthcare professional.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showNotificationsInfo() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Notifications'),
        content: const Text(
          'Notification preferences are not configured in this profile yet. '
          'This option will be connected when notification settings are implemented.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'Vitiligo Connect',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.favorite_rounded,
        color: AppTheme.primaryDark,
        size: 36,
      ),
      children: const [
        Text(
          'A safe space to learn about vitiligo, connect with others, '
          'and find community support.',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = _display(profile['name']);
    final email = _display(profile['email']);

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: AppTheme.background,
        foregroundColor: AppTheme.textDark,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: loadProfile,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: AppTheme.pastelBlue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 38,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person_rounded,
                      size: 44,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    email,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.textGrey),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: _editProfile,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit Full Profile'),
                  ),
                ],
              ),
            ),

            _section(
              'Personal Details',
              Icons.person_outline_rounded,
              [
                _infoRow('Full name', profile['name']),
                _infoRow('Email', profile['email']),
                _infoRow('Age', profile['age']),
                _infoRow('Gender', profile['gender']),
                _infoRow('Occupation', profile['occupation']),
                _infoRow('District', profile['district']),
              ],
            ),

            _section(
              'Vitiligo Journey',
              Icons.health_and_safety_outlined,
              [
                _infoRow('Duration', profile['vitiligoDuration']),
                _infoRow(
                  'Affected areas',
                  _displayList(profile['affectedAreas']),
                ),
                _infoRow('Currently spreading', profile['spreading']),
                _infoRow('Diagnosis received', profile['diagnosis']),
              ],
            ),

            _section(
              'Health Details',
              Icons.favorite_border_rounded,
              [
                _infoRow('Blood group', profile['bloodGroup']),
                _infoRow('Known allergies', profile['allergies']),
                _infoRow('Current treatment', profile['treatmentStatus']),
                _infoRow(
                  'Previous treatment',
                  profile['previousTreatment'],
                ),
              ],
            ),

            _section(
              'Support Preferences',
              Icons.support_agent_rounded,
              [
                _infoRow(
                  'Interested in',
                  _displayList(profile['supportInterests']),
                ),
              ],
            ),

            _collaboratorSection(),

            _section(
              'Account',
              Icons.settings_outlined,
              [
                _option(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notifications',
                  subtitle: 'Notification preferences',
                  onTap: _showNotificationsInfo,
                ),
                _option(
                  icon: Icons.lock_outline_rounded,
                  title: 'Privacy & Security',
                  subtitle: 'Account privacy and security options',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
                _option(
                  icon: Icons.help_outline_rounded,
                  title: 'Help & Support',
                  subtitle: 'Get help using Vitiligo Connect',
                  onTap: _showHelp,
                ),
                _option(
                  icon: Icons.info_outline_rounded,
                  title: 'About Vitiligo Connect',
                  subtitle: 'About this application',
                  onTap: _showAbout,
                ),
                _option(
                  icon: Icons.logout_rounded,
                  title: 'Log Out',
                  subtitle: 'Sign out of your account',
                  onTap: _logout,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
