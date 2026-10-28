import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'login_screen.dart';
import 'expert_register_screen.dart';
import '../theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // ======================================================
  // ACCOUNT DETAILS
  // ======================================================

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // ======================================================
  // PERSONAL DETAILS
  // ======================================================

  final ageController = TextEditingController();
  final otherOccupationController = TextEditingController();

  String? selectedGender;
  String? selectedOccupation;
  String? selectedDistrict;

  // ======================================================
  // VITILIGO DETAILS
  // ======================================================

  String? vitiligoDuration;
  String? spreading;
  String? diagnosis;

  final List<String> affectedAreas = [];

  // ======================================================
  // HEALTH DETAILS
  // ======================================================

  String? bloodGroup;
  final allergyController = TextEditingController();

  String? treatmentStatus;
  String? previousTreatment;

  // ======================================================
  // SUPPORT
  // ======================================================

  final List<String> supportInterests = [];

  // ======================================================
  // ACCOUNT TYPE
  // ======================================================

  String? selectedAccountType;

  // ======================================================
  // STATE
  // ======================================================

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool isLoading = false;

  int currentStep = 0;

  final List<String> stepTitles = [
    'Create Account',
    'About You',
    'Vitiligo Journey',
    'Health & Support',
  ];

  // ======================================================
  // KERALA DISTRICTS
  // ======================================================

  final List<String> keralaDistricts = const [
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

  // ======================================================
  // OCCUPATIONS
  // ======================================================

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

  // ======================================================
  // DISPOSE
  // ======================================================

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    ageController.dispose();
    otherOccupationController.dispose();
    allergyController.dispose();

    super.dispose();
  }

  // ======================================================
  // NEXT STEP
  // ======================================================

  void nextStep() {
    if (!_validateCurrentStep()) {
      return;
    }

    // --------------------------------------------------
    // EXPERT
    // --------------------------------------------------

    if (selectedAccountType == 'Expert') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ExpertRegisterScreen(),
        ),
      );

      return;
    }

    // --------------------------------------------------
    // USER
    // --------------------------------------------------

    if (currentStep < 3) {
      setState(() {
        currentStep++;
      });
    } else {
      register();
    }
  }

  // ======================================================
  // PREVIOUS STEP
  // ======================================================

  void previousStep() {
    if (currentStep > 0) {
      setState(() {
        currentStep--;
      });
    }
  }

  // ======================================================
  // VALIDATE CURRENT STEP
  // ======================================================

  bool _validateCurrentStep() {
    switch (currentStep) {
      case 0:
        if (!_formKey.currentState!.validate()) {
          return false;
        }

        if (selectedAccountType == null) {
          _showMessage(
            'Please select whether you are registering as a User or Expert.',
          );
          return false;
        }

        return true;

      case 1:
        return _validatePersonalDetails();

      case 2:
        return _validateVitiligoDetails();

      case 3:
        return _validateHealthSupport();

      default:
        return true;
    }
  }

  // ======================================================
  // PERSONAL DETAILS VALIDATION
  // ======================================================

  bool _validatePersonalDetails() {
    final ageText = ageController.text.trim();

    if (ageText.isEmpty) {
      _showMessage('Please enter your age.');
      return false;
    }

    final age = int.tryParse(ageText);

    if (age == null || age < 1 || age > 120) {
      _showMessage('Please enter a valid age.');
      return false;
    }

    if (selectedGender == null) {
      _showMessage('Please select your gender.');
      return false;
    }

    if (selectedOccupation == null) {
      _showMessage('Please select your occupation.');
      return false;
    }

    if (selectedOccupation == 'Other' &&
        otherOccupationController.text.trim().isEmpty) {
      _showMessage('Please enter your occupation.');
      return false;
    }

    if (selectedDistrict == null) {
      _showMessage('Please select your district.');
      return false;
    }

    return true;
  }

  // ======================================================
  // VITILIGO VALIDATION
  // ======================================================

  bool _validateVitiligoDetails() {
    if (vitiligoDuration == null) {
      _showMessage(
        'Please select how long you have had vitiligo.',
      );
      return false;
    }

    if (affectedAreas.isEmpty) {
      _showMessage(
        'Please select at least one affected body area.',
      );
      return false;
    }

    if (spreading == null) {
      _showMessage(
        'Please select whether your vitiligo is currently spreading.',
      );
      return false;
    }

    if (diagnosis == null) {
      _showMessage(
        'Please select your diagnosis status.',
      );
      return false;
    }

    return true;
  }

  // ======================================================
  // HEALTH & SUPPORT VALIDATION
  // ======================================================

  bool _validateHealthSupport() {
    if (treatmentStatus == null) {
      _showMessage(
        'Please select your current treatment status.',
      );
      return false;
    }

    if (supportInterests.isEmpty) {
      _showMessage(
        'Please select at least one support interest.',
      );
      return false;
    }

    return true;
  }

  // ======================================================
  // USER REGISTRATION - FIREBASE
  // ======================================================

  Future<void> register() async {
    if (!_validateCurrentStep()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // ==================================================
      // CREATE FIREBASE AUTHENTICATION ACCOUNT
      // ==================================================

      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      final user = credential.user;

      if (user == null) {
        throw Exception('Unable to create account.');
      }

      // ==================================================
      // UPDATE DISPLAY NAME
      // ==================================================

      await user.updateDisplayName(
        nameController.text.trim(),
      );

      // ==================================================
      // CREATE USER PROFILE IN FIRESTORE
      // ==================================================

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'uid': user.uid,
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),

        // Account information
        'role': 'user',
        'status': 'active',

        // Personal information
        'age': int.parse(ageController.text.trim()),
        'gender': selectedGender,
        'occupation': selectedOccupation == 'Other'
            ? otherOccupationController.text.trim()
            : selectedOccupation,
        'district': selectedDistrict,

        // Vitiligo information
        'vitiligoDuration': vitiligoDuration,
        'affectedAreas': List<String>.from(affectedAreas),
        'spreading': spreading,
        'diagnosis': diagnosis,

        // Health information
        'bloodGroup': bloodGroup,
        'allergies': allergyController.text.trim(),
        'treatmentStatus': treatmentStatus,
        'previousTreatment': previousTreatment,

        // Support preferences
        'supportInterests': List<String>.from(supportInterests),

        // Account creation time
        'createdAt': FieldValue.serverTimestamp(),
      });

      // ==================================================
      // SIGN OUT
      // ==================================================
      //
      // Firebase automatically signs the user in after
      // createUserWithEmailAndPassword().
      //
      // Since your app flow is:
      // Register -> Login -> Home
      //
      // we sign the user out here so they can login normally.
      // ==================================================

      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      // ==================================================
      // SUCCESS MESSAGE
      // ==================================================

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Registration successful! Please login.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // ==================================================
      // GO TO LOGIN
      // ==================================================

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
    }

    // ====================================================
    // FIREBASE AUTHENTICATION ERRORS
    // ====================================================

    on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      String message;

      switch (e.code) {
        case 'email-already-in-use':
          message =
              'An account already exists with this email.';
          break;

        case 'invalid-email':
          message =
              'Please enter a valid email address.';
          break;

        case 'weak-password':
          message =
              'Password is too weak. Please choose a stronger password.';
          break;

        case 'network-request-failed':
          message =
              'Network error. Please check your internet connection.';
          break;

        case 'operation-not-allowed':
          message =
              'Email/password registration is not enabled in Firebase.';
          break;

        default:
          message =
              e.message ?? 'Registration failed. Please try again.';
      }

      _showMessage(message);
    }

    // ====================================================
    // OTHER ERRORS
    // ====================================================

    catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      _showMessage(
        'Something went wrong. Please try again.',
      );
    }
  }

  // ======================================================
  // MESSAGE
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
  // BUILD
  // ======================================================

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

        title: Text(
          stepTitles[currentStep],
          style: const TextStyle(
            color: AppTheme.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SafeArea(
        child: Column(
          children: [
            // ==================================================
            // PROGRESS
            // ==================================================

            Padding(
              padding: const EdgeInsets.fromLTRB(
                24,
                5,
                24,
                5,
              ),

              child: Column(
                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,

                    children: [
                      Text(
                        'Step ${currentStep + 1} of 4',

                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textGrey,
                        ),
                      ),

                      Text(
                        '${((currentStep + 1) / 4 * 100).round()}%',

                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 7),

                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(10),

                    child: LinearProgressIndicator(
                      value: (currentStep + 1) / 4,
                      minHeight: 7,

                      backgroundColor:
                          AppTheme.pastelBlue,

                      valueColor:
                          const AlwaysStoppedAnimation(
                        AppTheme.primaryDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ==================================================
            // CONTENT
            // ==================================================

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  24,
                  15,
                  24,
                  30,
                ),

                child: Form(
                  key: _formKey,
                  child: _buildCurrentStep(),
                ),
              ),
            ),

            // ==================================================
            // BUTTONS
            // ==================================================

            Container(
              padding: const EdgeInsets.fromLTRB(
                24,
                12,
                24,
                18,
              ),

              decoration: BoxDecoration(
                color: AppTheme.background,

                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: 0.05,
                    ),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),

              child: Row(
                children: [
                  if (currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            isLoading
                                ? null
                                : previousStep,

                        style:
                            OutlinedButton.styleFrom(
                          foregroundColor:
                              AppTheme.primaryDark,

                          side: const BorderSide(
                            color:
                                AppTheme.primaryDark,
                          ),

                          minimumSize:
                              const Size.fromHeight(52),

                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                        ),

                        child: const Text(
                          'Back',

                          style: TextStyle(
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                  if (currentStep > 0)
                    const SizedBox(width: 12),

                  Expanded(
                    flex:
                        currentStep == 0
                            ? 1
                            : 2,

                    child: ElevatedButton(
                      onPressed:
                          isLoading
                              ? null
                              : nextStep,

                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            AppTheme.primaryDark,

                        foregroundColor:
                            Colors.white,

                        minimumSize:
                            const Size.fromHeight(52),

                        elevation: 0,

                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                      ),

                      child: isLoading
                          ? const SizedBox(
                              width: 23,
                              height: 23,

                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              currentStep == 3
                                  ? 'Complete Registration'
                                  : 'Continue',

                              style:
                                  const TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ======================================================
  // CURRENT STEP
  // ======================================================

  Widget _buildCurrentStep() {
    switch (currentStep) {
      case 0:
        return _buildAccountStep();

      case 1:
        return _buildAboutStep();

      case 2:
        return _buildVitiligoStep();

      case 3:
        return _buildHealthSupportStep();

      default:
        return const SizedBox();
    }
  }

  // ======================================================
  // STEP 1 - ACCOUNT
  // ======================================================

  Widget _buildAccountStep() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        _stepIcon(
          Icons.person_add_alt_1_rounded,
          AppTheme.pastelBlue,
        ),

        const SizedBox(height: 20),

        const Text(
          'Create your account',

          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Choose how you want to join Vitiligo Connect.',

          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textGrey,
          ),
        ),

        const SizedBox(height: 28),

        // ==================================================
        // ACCOUNT TYPE
        // ==================================================

        _label('I want to register as *'),

        const SizedBox(height: 8),

        _buildAccountTypeSelector(),

        const SizedBox(height: 25),

        // ==================================================
        // NAME
        // ==================================================

        _label('Full Name *'),

        const SizedBox(height: 8),

        TextFormField(
          controller: nameController,

          textCapitalization:
              TextCapitalization.words,

          decoration: _inputDecoration(
            hint: 'Enter your full name',
            icon:
                Icons.person_outline_rounded,
          ),

          validator: (value) {
            if (value == null ||
                value.trim().isEmpty) {
              return 'Please enter your name';
            }

            if (value.trim().length < 2) {
              return 'Name must be at least 2 characters';
            }

            return null;
          },
        ),

        const SizedBox(height: 18),

        // ==================================================
        // EMAIL
        // ==================================================

        _label('Email *'),

        const SizedBox(height: 8),

        TextFormField(
          controller: emailController,

          keyboardType:
              TextInputType.emailAddress,

          decoration: _inputDecoration(
            hint: 'Enter your email',
            icon:
                Icons.email_outlined,
          ),

          validator: (value) {
            if (value == null ||
                value.trim().isEmpty) {
              return 'Please enter your email';
            }

            if (!RegExp(
              r'^[\w\.-]+@[\w\.-]+\.\w+$',
            ).hasMatch(value.trim())) {
              return 'Please enter a valid email';
            }

            return null;
          },
        ),

        const SizedBox(height: 18),

        // ==================================================
        // PASSWORD
        // ==================================================

        _label('Password *'),

        const SizedBox(height: 8),

        TextFormField(
          controller:
              passwordController,

          obscureText:
              obscurePassword,

          decoration:
              _inputDecoration(
            hint:
                'Create a password',

            icon:
                Icons.lock_outline_rounded,

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
          ),

          validator: (value) {
            if (value == null ||
                value.isEmpty) {
              return 'Please enter a password';
            }

            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }

            return null;
          },
        ),

        const SizedBox(height: 18),

        // ==================================================
        // CONFIRM PASSWORD
        // ==================================================

        _label('Confirm Password *'),

        const SizedBox(height: 8),

        TextFormField(
          controller:
              confirmPasswordController,

          obscureText:
              obscureConfirmPassword,

          decoration:
              _inputDecoration(
            hint:
                'Confirm your password',

            icon:
                Icons.lock_reset_outlined,

            suffixIcon:
                IconButton(
              onPressed: () {
                setState(() {
                  obscureConfirmPassword =
                      !obscureConfirmPassword;
                });
              },

              icon: Icon(
                obscureConfirmPassword
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
              return 'Please confirm your password';
            }

            if (value !=
                passwordController.text) {
              return 'Passwords do not match';
            }

            return null;
          },
        ),

        const SizedBox(height: 20),

        const Text(
          '* Required fields',

          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textGrey,
          ),
        ),

        const SizedBox(height: 5),

        _loginLink(),
      ],
    );
  }

  // ======================================================
  // ACCOUNT TYPE SELECTOR
  // ======================================================

  Widget _buildAccountTypeSelector() {
    return Column(
      children: [
        _accountTypeCard(
          title: 'User',

          subtitle:
              'Join the community, learn about vitiligo and connect with experts.',

          icon:
              Icons.person_outline_rounded,

          value: 'User',
        ),

        const SizedBox(height: 12),

        _accountTypeCard(
          title: 'Expert',

          subtitle:
              'Apply as a dermatologist or psychologist and support the community.',

          icon:
              Icons.medical_services_outlined,

          value: 'Expert',
        ),
      ],
    );
  }

  // ======================================================
  // ACCOUNT TYPE CARD
  // ======================================================

  Widget _accountTypeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
  }) {
    final isSelected =
        selectedAccountType == value;

    return InkWell(
      borderRadius:
          BorderRadius.circular(16),

      onTap: () {
        setState(() {
          selectedAccountType = value;
        });
      },

      child: Container(
        width: double.infinity,

        padding:
            const EdgeInsets.all(16),

        decoration:
            BoxDecoration(
          color: isSelected
              ? AppTheme.pastelGreen
              : Colors.white,

          borderRadius:
              BorderRadius.circular(16),

          border: Border.all(
            color: isSelected
                ? AppTheme.primaryDark
                : const Color(
                    0xFFE4E8E5,
                  ),

            width:
                isSelected ? 1.5 : 1,
          ),
        ),

        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,

              decoration:
                  BoxDecoration(
                color: isSelected
                    ? Colors.white
                    : AppTheme.pastelBlue,

                shape: BoxShape.circle,
              ),

              child: Icon(
                icon,

                color:
                    AppTheme.primaryDark,

                size: 26,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Text(
                    title,

                    style:
                        const TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                      color:
                          AppTheme.textDark,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    subtitle,

                    style:
                        const TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color:
                          AppTheme.textGrey,
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              isSelected
                  ? Icons
                      .radio_button_checked
                  : Icons
                      .radio_button_unchecked,

              color: isSelected
                  ? AppTheme.primaryDark
                  : AppTheme.textGrey,
            ),
          ],
        ),
      ),
    );
  }

  // ======================================================
  // STEP 2 - ABOUT
  // ======================================================

  Widget _buildAboutStep() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        _stepIcon(
          Icons.person_outline_rounded,
          AppTheme.pastelGreen,
        ),

        const SizedBox(height: 20),

        const Text(
          'Tell us about yourself',

          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'These details help us provide relevant content and community activities.',

          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textGrey,
          ),
        ),

        const SizedBox(height: 28),

        // AGE

        _label('Age *'),

        const SizedBox(height: 8),

        TextFormField(
          controller: ageController,

          keyboardType:
              TextInputType.number,

          decoration: _inputDecoration(
            hint: 'Enter your age',
            icon:
                Icons.cake_outlined,
          ),
        ),

        const SizedBox(height: 20),

        // GENDER

        _label('Gender *'),

        const SizedBox(height: 8),

        _dropdown<String>(
          value: selectedGender,

          hint: 'Select gender',

          icon:
              Icons.people_outline_rounded,

          items: const [
            'Female',
            'Male',
            'Other',
            'Prefer not to say',
          ],

          onChanged: (value) {
            setState(() {
              selectedGender = value;
            });
          },
        ),

        const SizedBox(height: 20),

        // OCCUPATION

        _label('Occupation *'),

        const SizedBox(height: 8),

        _dropdown<String>(
          value:
              selectedOccupation,

          hint:
              'Select your occupation',

          icon:
              Icons.work_outline_rounded,

          items: occupations,

          onChanged: (value) {
            setState(() {
              selectedOccupation =
                  value;

              if (value != 'Other') {
                otherOccupationController
                    .clear();
              }
            });
          },
        ),

        if (selectedOccupation ==
            'Other') ...[
          const SizedBox(height: 12),

          TextFormField(
            controller:
                otherOccupationController,

            textCapitalization:
                TextCapitalization.words,

            decoration:
                _inputDecoration(
              hint:
                  'Enter your occupation',

              icon:
                  Icons.edit_outlined,
            ),
          ),
        ],

        const SizedBox(height: 20),

        // DISTRICT

        _label('District *'),

        const SizedBox(height: 8),

        _dropdown<String>(
          value:
              selectedDistrict,

          hint:
              'Select your Kerala district',

          icon:
              Icons.location_on_outlined,

          items:
              keralaDistricts,

          onChanged: (value) {
            setState(() {
              selectedDistrict =
                  value;
            });
          },
        ),

        const SizedBox(height: 20),

        _infoBox(
          'Your district can later help us show relevant awareness events and community activities near you.',
        ),
      ],
    );
  }

  // ======================================================
  // STEP 3 - VITILIGO
  // ======================================================

  Widget _buildVitiligoStep() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        _stepIcon(
          Icons.health_and_safety_outlined,
          AppTheme.pastelYellow,
        ),

        const SizedBox(height: 20),

        const Text(
          'Your Vitiligo Journey',

          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Tell us a little about your vitiligo journey.',

          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textGrey,
          ),
        ),

        const SizedBox(height: 28),

        // DURATION

        _label(
          'How long have you had vitiligo? *',
        ),

        const SizedBox(height: 8),

        _dropdown<String>(
          value:
              vitiligoDuration,

          hint:
              'Select duration',

          icon:
              Icons.calendar_month_outlined,

          items: const [
            'Less than 1 year',
            '1 - 3 years',
            '3 - 5 years',
            '5 - 10 years',
            'More than 10 years',
          ],

          onChanged: (value) {
            setState(() {
              vitiligoDuration =
                  value;
            });
          },
        ),

        const SizedBox(height: 22),

        // AFFECTED AREAS

        _label(
          'Where do you have vitiligo? *',
        ),

        const SizedBox(height: 5),

        const Text(
          'Select all areas that apply.',

          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textGrey,
          ),
        ),

        const SizedBox(height: 10),

        _buildAreaGrid(),

        const SizedBox(height: 22),

        // SPREADING

        _label(
          'Is it currently spreading? *',
        ),

        const SizedBox(height: 8),

        _radioGroup(
          options: const [
            'Yes',
            'No',
            'Not sure',
          ],

          selected:
              spreading,

          onChanged: (value) {
            setState(() {
              spreading = value;
            });
          },
        ),

        const SizedBox(height: 20),

        // DIAGNOSIS

        _label(
          'Have you received a diagnosis? *',
        ),

        const SizedBox(height: 8),

        _radioGroup(
          options: const [
            'Yes',
            'No',
            'Not sure',
          ],

          selected:
              diagnosis,

          onChanged: (value) {
            setState(() {
              diagnosis = value;
            });
          },
        ),
      ],
    );
  }

  // ======================================================
  // STEP 4 - HEALTH & SUPPORT
  // ======================================================

  Widget _buildHealthSupportStep() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        _stepIcon(
          Icons.favorite_outline_rounded,
          AppTheme.pastelPink,
        ),

        const SizedBox(height: 20),

        const Text(
          'Health & Support',

          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Some health details are optional. Support preferences help personalize your experience.',

          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textGrey,
          ),
        ),

        const SizedBox(height: 28),

        // BLOOD GROUP

        _label(
          'Blood Group (Optional)',
        ),

        const SizedBox(height: 8),

        _dropdown<String>(
          value:
              bloodGroup,

          hint:
              'Select blood group',

          icon:
              Icons.bloodtype_outlined,

          items: const [
            'A+',
            'A-',
            'B+',
            'B-',
            'AB+',
            'AB-',
            'O+',
            'O-',
            'Unknown',
            'Prefer not to say',
          ],

          onChanged: (value) {
            setState(() {
              bloodGroup = value;
            });
          },
        ),

        const SizedBox(height: 20),

        // ALLERGIES

        _label(
          'Known Allergies (Optional)',
        ),

        const SizedBox(height: 8),

        TextFormField(
          controller:
              allergyController,

          maxLines: 2,

          decoration:
              _inputDecoration(
            hint:
                'Enter known allergies',

            icon:
                Icons.warning_amber_outlined,
          ),
        ),

        const SizedBox(height: 20),

        // TREATMENT

        _label(
          'Current Treatment Status *',
        ),

        const SizedBox(height: 8),

        _radioGroup(
          options: const [
            'Currently receiving treatment',
            'Previously treated',
            'Not receiving treatment',
            'Prefer not to say',
          ],

          selected:
              treatmentStatus,

          onChanged: (value) {
            setState(() {
              treatmentStatus =
                  value;
            });
          },
        ),

        const SizedBox(height: 20),

        // PREVIOUS TREATMENT

        _label(
          'Previous Vitiligo Treatment (Optional)',
        ),

        const SizedBox(height: 8),

        _radioGroup(
          options: const [
            'Topical treatment',
            'Phototherapy',
            'Other treatment',
            'None',
            'Prefer not to say',
          ],

          selected:
              previousTreatment,

          onChanged: (value) {
            setState(() {
              previousTreatment =
                  value;
            });
          },
        ),

        const SizedBox(height: 22),

        // SUPPORT

        _label(
          'What kind of support are you interested in? *',
        ),

        const SizedBox(height: 5),

        const Text(
          'Select at least one.',

          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textGrey,
          ),
        ),

        const SizedBox(height: 8),

        _buildSupportOptions(),

        const SizedBox(height: 20),

        _infoBox(
          'You can change your support preferences later from your profile.',
        ),
      ],
    );
  }

  // ======================================================
  // AFFECTED AREA GRID
  // ======================================================

  Widget _buildAreaGrid() {
    const areas = [
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

    return Wrap(
      spacing: 8,
      runSpacing: 8,

      children:
          areas.map((area) {
        final selected =
            affectedAreas.contains(
          area,
        );

        return FilterChip(
          label: Text(area),

          selected: selected,

          onSelected: (value) {
            setState(() {
              if (value) {
                if (!affectedAreas
                    .contains(area)) {
                  affectedAreas
                      .add(area);
                }
              } else {
                affectedAreas
                    .remove(area);
              }
            });
          },

          selectedColor:
              AppTheme.pastelGreen,

          checkmarkColor:
              AppTheme.primaryDark,

          labelStyle:
              TextStyle(
            color: selected
                ? AppTheme.primaryDark
                : AppTheme.textDark,

            fontWeight: selected
                ? FontWeight.w600
                : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  // ======================================================
  // SUPPORT OPTIONS
  // ======================================================

  Widget _buildSupportOptions() {
    const options = [
      'Learn about vitiligo',
      'Emotional support',
      'Expert advice',
      'Workplace support',
      'Relationship & family support',
      'Community discussions',
      'Awareness events',
    ];

    return Column(
      children:
          options.map((option) {
        final selected =
            supportInterests
                .contains(option);

        return CheckboxListTile(
          contentPadding:
              EdgeInsets.zero,

          title: Text(
            option,

            style:
                const TextStyle(
              fontSize: 14,
            ),
          ),

          value: selected,

          activeColor:
              AppTheme.primaryDark,

          onChanged: (value) {
            setState(() {
              if (value == true) {
                if (!supportInterests
                    .contains(option)) {
                  supportInterests
                      .add(option);
                }
              } else {
                supportInterests
                    .remove(option);
              }
            });
          },
        );
      }).toList(),
    );
  }

  // ======================================================
  // RADIO GROUP
  // ======================================================

  Widget _radioGroup({
    required List<String> options,
    required String? selected,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      children:
          options.map((option) {
        return RadioListTile<String>(
          contentPadding:
              EdgeInsets.zero,

          title: Text(
            option,

            style:
                const TextStyle(
              fontSize: 14,
            ),
          ),

          value: option,

          groupValue: selected,

          activeColor:
              AppTheme.primaryDark,

          onChanged: onChanged,
        );
      }).toList(),
    );
  }

  // ======================================================
  // DROPDOWN
  // ======================================================

  Widget _dropdown<T>({
    required T? value,
    required String hint,
    required IconData icon,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,

      decoration:
          _inputDecoration(
        hint: hint,
        icon: icon,
      ),

      items:
          items.map((item) {
        return DropdownMenuItem<T>(
          value: item,

          child: Text(
            item.toString(),
          ),
        );
      }).toList(),

      onChanged: onChanged,
    );
  }

  // ======================================================
  // STEP ICON
  // ======================================================

  Widget _stepIcon(
    IconData icon,
    Color background,
  ) {
    return Container(
      width: 72,
      height: 72,

      decoration:
          BoxDecoration(
        color: background,
        shape: BoxShape.circle,
      ),

      child: Icon(
        icon,
        size: 36,
        color: AppTheme.primaryDark,
      ),
    );
  }

  // ======================================================
  // LABEL
  // ======================================================

  Widget _label(String text) {
    return Text(
      text,

      style:
          const TextStyle(
        fontSize: 14,
        fontWeight:
            FontWeight.w600,
        color:
            AppTheme.textDark,
      ),
    );
  }

  // ======================================================
  // INFO BOX
  // ======================================================

  Widget _infoBox(String text) {
    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.all(14),

      decoration:
          BoxDecoration(
        color:
            AppTheme.pastelBlue,

        borderRadius:
            BorderRadius.circular(14),
      ),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 20,
            color:
                AppTheme.primaryDark,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              text,

              style:
                  const TextStyle(
                fontSize: 12,
                height: 1.4,
                color:
                    AppTheme.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ======================================================
  // LOGIN LINK
  // ======================================================

  Widget _loginLink() {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.center,

      children: [
        const Text(
          'Already have an account?',

          style: TextStyle(
            color: AppTheme.textGrey,
          ),
        ),

        TextButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,

              MaterialPageRoute(
                builder: (context) =>
                    const LoginScreen(),
              ),
            );
          },

          child: const Text(
            'Login',

            style: TextStyle(
              color:
                  AppTheme.primaryDark,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ======================================================
  // INPUT DECORATION
  // ======================================================

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,

      prefixIcon:
          Icon(icon),

      suffixIcon:
          suffixIcon,

      filled: true,

      fillColor:
          Colors.white,

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
    );
  }
}