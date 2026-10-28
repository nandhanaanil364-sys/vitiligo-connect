import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme/app_theme.dart';
import 'login_screen.dart';

class ExpertRegisterScreen extends StatefulWidget {
  const ExpertRegisterScreen({super.key});

  @override
  State<ExpertRegisterScreen> createState() =>
      _ExpertRegisterScreenState();
}

class _ExpertRegisterScreenState extends State<ExpertRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // ======================================================
  // FIREBASE
  // ======================================================

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ======================================================
  // ACCOUNT DETAILS
  // ======================================================

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // ======================================================
  // PROFESSIONAL DETAILS
  // ======================================================

  final phoneController = TextEditingController();
  final qualificationController = TextEditingController();
  final experienceController = TextEditingController();
  final workplaceController = TextEditingController();
  final registrationNumberController = TextEditingController();
  final bioController = TextEditingController();

  String? selectedExpertType;
  String? selectedDistrict;

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool isLoading = false;

  // ======================================================
  // EXPERT TYPES
  // ======================================================

  final List<String> expertTypes = const [
    'Dermatologist',
    'Psychologist',
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
  // DISPOSE
  // ======================================================

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();

    phoneController.dispose();
    qualificationController.dispose();
    experienceController.dispose();
    workplaceController.dispose();
    registrationNumberController.dispose();
    bioController.dispose();

    super.dispose();
  }

  // ======================================================
  // REGISTER EXPERT
  // ======================================================

  Future<void> registerExpert() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedExpertType == null) {
      _showMessage(
        'Please select your professional type.',
      );
      return;
    }

    if (selectedDistrict == null) {
      _showMessage(
        'Please select your district.',
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // ==================================================
      // STEP 1: CREATE FIREBASE AUTH ACCOUNT
      // ==================================================

      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final User? user = userCredential.user;

      if (user == null) {
        throw Exception('Unable to create expert account.');
      }

      // ==================================================
      // STEP 2: UPDATE AUTH DISPLAY NAME
      // ==================================================

      await user.updateDisplayName(
        nameController.text.trim(),
      );

      // ==================================================
      // STEP 3: CREATE EXPERT PROFILE
      // ==================================================

      await _firestore
          .collection('experts')
          .doc(user.uid)
          .set({
        'uid': user.uid,

        // Basic details
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'phone': phoneController.text.trim(),

        // Professional details
        'expertType': selectedExpertType,
        'qualification': qualificationController.text.trim(),
        'experience': experienceController.text.trim(),
        'workplace': workplaceController.text.trim(),
        'registrationNumber':
            registrationNumberController.text.trim(),
        'district': selectedDistrict,
        'bio': bioController.text.trim(),

        // Verification
        'role': 'expert',
        'status': 'pending',

        // Timestamps
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // ==================================================
      // STEP 4: SIGN OUT
      // ==================================================
      //
      // The expert should not automatically enter the
      // dashboard because admin approval is required.
      //

      await _auth.signOut();

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      // ==================================================
      // STEP 5: SHOW SUCCESS MESSAGE
      // ==================================================

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: const Row(
              children: [
                Icon(
                  Icons.verified_outlined,
                  color: AppTheme.primaryDark,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Application Submitted',
                  ),
                ),
              ],
            ),
            content: const Text(
              'Your expert registration has been submitted successfully.\n\n'
              'Your profile is now pending administrator verification. '
              'After your professional details are verified and approved, '
              'you will be able to log in and access the Expert Dashboard.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);

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
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      String message;

      switch (e.code) {
        case 'email-already-in-use':
          message =
              'An account already exists with this email address.';
          break;

        case 'invalid-email':
          message =
              'Please enter a valid email address.';
          break;

        case 'weak-password':
          message =
              'Password is too weak. Use at least 6 characters.';
          break;

        case 'operation-not-allowed':
          message =
              'Email/password authentication is not enabled in Firebase.';
          break;

        case 'network-request-failed':
          message =
              'Network error. Please check your internet connection.';
          break;

        default:
          message =
              e.message ?? 'Unable to create expert account.';
      }

      _showMessage(message);
    } on FirebaseException catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      _showMessage(
        'Firebase error: ${e.message ?? 'Unable to save expert profile.'}',
      );
    } catch (e) {
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

        title: const Text(
          'Expert Registration',
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
            15,
            24,
            35,
          ),

          child: Form(
            key: _formKey,

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                // ==================================================
                // ICON
                // ==================================================

                Center(
                  child: Container(
                    width: 85,
                    height: 85,

                    decoration:
                        const BoxDecoration(
                      color: AppTheme.pastelBlue,
                      shape: BoxShape.circle,
                    ),

                    child: const Icon(
                      Icons.medical_services_outlined,
                      size: 42,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Center(
                  child: Text(
                    'Join as an Expert',
                    textAlign: TextAlign.center,

                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                const Center(
                  child: Text(
                    'Create your professional profile and help '
                    'the Vitiligo Connect community.',
                    textAlign: TextAlign.center,

                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: AppTheme.textGrey,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                _infoBox(
                  'Expert profiles are reviewed by an administrator '
                  'before they become visible to users.',
                ),

                const SizedBox(height: 28),

                // ==================================================
                // EXPERT TYPE
                // ==================================================

                _label('Professional Type *'),

                const SizedBox(height: 8),

                _dropdown<String>(
                  value: selectedExpertType,
                  hint: 'Select professional type',
                  icon: Icons.badge_outlined,
                  items: expertTypes,

                  onChanged: (value) {
                    setState(() {
                      selectedExpertType = value;
                    });
                  },
                ),

                const SizedBox(height: 20),

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
                    icon: Icons.person_outline_rounded,
                  ),

                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Please enter your name';
                    }

                    if (value.trim().length < 2) {
                      return 'Please enter a valid name';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 20),

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
                    icon: Icons.email_outlined,
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

                const SizedBox(height: 20),

                // ==================================================
                // PHONE
                // ==================================================

                _label('Phone Number *'),

                const SizedBox(height: 8),

                TextFormField(
                  controller: phoneController,

                  keyboardType:
                      TextInputType.phone,

                  decoration: _inputDecoration(
                    hint:
                        'Enter your 10-digit phone number',
                    icon: Icons.phone_outlined,
                  ),

                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Please enter your phone number';
                    }

                    if (!RegExp(
                      r'^[0-9]{10}$',
                    ).hasMatch(value.trim())) {
                      return 'Enter a valid 10-digit phone number';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // ==================================================
                // QUALIFICATION
                // ==================================================

                _label('Qualification *'),

                const SizedBox(height: 8),

                TextFormField(
                  controller:
                      qualificationController,

                  decoration: _inputDecoration(
                    hint:
                        'e.g. MBBS, MD Dermatology, MSc Psychology',
                    icon: Icons.school_outlined,
                  ),

                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Please enter your qualification';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // ==================================================
                // EXPERIENCE
                // ==================================================

                _label('Years of Experience *'),

                const SizedBox(height: 8),

                TextFormField(
                  controller:
                      experienceController,

                  keyboardType:
                      TextInputType.number,

                  decoration: _inputDecoration(
                    hint:
                        'Enter years of experience',
                    icon:
                        Icons.work_history_outlined,
                  ),

                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Please enter your experience';
                    }

                    final years =
                        int.tryParse(value.trim());

                    if (years == null ||
                        years < 0 ||
                        years > 70) {
                      return 'Enter a valid number of years';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // ==================================================
                // WORKPLACE
                // ==================================================

                _label(
                  'Hospital / Clinic / Workplace *',
                ),

                const SizedBox(height: 8),

                TextFormField(
                  controller:
                      workplaceController,

                  textCapitalization:
                      TextCapitalization.words,

                  decoration: _inputDecoration(
                    hint:
                        'Enter your hospital, clinic or workplace',
                    icon:
                        Icons.local_hospital_outlined,
                  ),

                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Please enter your workplace';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // ==================================================
                // REGISTRATION NUMBER
                // ==================================================

                _label(
                  'Professional Registration Number *',
                ),

                const SizedBox(height: 8),

                TextFormField(
                  controller:
                      registrationNumberController,

                  decoration: _inputDecoration(
                    hint:
                        'Enter professional registration number',
                    icon:
                        Icons.assignment_ind_outlined,
                  ),

                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Please enter your registration number';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // ==================================================
                // DISTRICT
                // ==================================================

                _label('District *'),

                const SizedBox(height: 8),

                _dropdown<String>(
                  value: selectedDistrict,
                  hint: 'Select your Kerala district',
                  icon: Icons.location_on_outlined,
                  items: keralaDistricts,

                  onChanged: (value) {
                    setState(() {
                      selectedDistrict = value;
                    });
                  },
                ),

                const SizedBox(height: 20),

                // ==================================================
                // BIO
                // ==================================================

                _label('Professional Bio *'),

                const SizedBox(height: 8),

                TextFormField(
                  controller: bioController,

                  maxLines: 4,

                  decoration: _inputDecoration(
                    hint:
                        'Briefly describe your professional experience',
                    icon:
                        Icons.description_outlined,
                  ),

                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Please enter a professional bio';
                    }

                    if (value.trim().length < 20) {
                      return 'Bio should contain at least 20 characters';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // ==================================================
                // PASSWORD
                // ==================================================

                _label('Password *'),

                const SizedBox(height: 8),

                TextFormField(
                  controller:
                      passwordController,

                  obscureText: obscurePassword,

                  decoration: _inputDecoration(
                    hint: 'Create a password',
                    icon: Icons.lock_outline_rounded,

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
                      return 'Please enter a password';
                    }

                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 20),

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

                  decoration: _inputDecoration(
                    hint: 'Confirm your password',
                    icon: Icons.lock_reset_outlined,

                    suffixIcon: IconButton(
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

                const SizedBox(height: 28),

                // ==================================================
                // SUBMIT
                // ==================================================

                SizedBox(
                  width: double.infinity,
                  height: 55,

                  child: ElevatedButton(
                    onPressed:
                        isLoading
                            ? null
                            : registerExpert,

                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          AppTheme.primaryDark,

                      foregroundColor:
                          Colors.white,

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
                        : const Text(
                            'Submit for Verification',

                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                // ==================================================
                // LOGIN
                // ==================================================

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,

                  children: [
                    const Text(
                      'Already have an account?',

                      style: TextStyle(
                        color:
                            AppTheme.textGrey,
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
                ),
              ],
            ),
          ),
        ),
      ),
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

      decoration: _inputDecoration(
        hint: hint,
        icon: icon,
      ),

      items: items.map((item) {
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
  // LABEL
  // ======================================================

  Widget _label(String text) {
    return Text(
      text,

      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppTheme.textDark,
      ),
    );
  }

  // ======================================================
  // INFO BOX
  // ======================================================

  Widget _infoBox(String text) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: AppTheme.pastelBlue,

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

            color: AppTheme.primaryDark,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              text,

              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                color: AppTheme.textDark,
              ),
            ),
          ),
        ],
      ),
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

      prefixIcon: Icon(icon),

      suffixIcon: suffixIcon,

      filled: true,

      fillColor: Colors.white,

      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),

        borderSide: BorderSide.none,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),

        borderSide: const BorderSide(
          color: Color(0xFFE4E8E5),
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),

        borderSide: const BorderSide(
          color: AppTheme.primaryDark,
          width: 1.5,
        ),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),

        borderSide: const BorderSide(
          color: Colors.redAccent,
        ),
      ),

      focusedErrorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),

        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1.5,
        ),
      ),
    );
  }
}