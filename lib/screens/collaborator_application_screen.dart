import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class CollaboratorApplicationScreen extends StatefulWidget {
  const CollaboratorApplicationScreen({super.key});

  @override
  State<CollaboratorApplicationScreen> createState() =>
      _CollaboratorApplicationScreenState();
}

class _CollaboratorApplicationScreenState
    extends State<CollaboratorApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  bool _isSubmitting = false;
  bool _isLoading = true;

  String? _applicationStatus;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _checkApplication();
  }

  Future<void> _checkApplication() async {
    final user = _auth.currentUser;

    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final doc = await _firestore
          .collection('collaboratorApplications')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        setState(() {
          _applicationStatus = doc.data()?['status'] ?? 'pending';
        });
      }
    } catch (e) {
      debugPrint('Error checking collaborator application: $e');
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = _auth.currentUser;

    if (user == null) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      final userData = userDoc.data() ?? {};

      await _firestore
          .collection('collaboratorApplications')
          .doc(user.uid)
          .set({
        'userId': user.uid,
        'name': userData['name'] ?? '',
        'email': user.email ?? '',
        'reason': _reasonController.text.trim(),
        'status': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      setState(() {
        _applicationStatus = 'pending';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your Community Collaborator application has been submitted.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not submit application: $e',
          ),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Community Collaborator'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _buildContent(),
            ),
    );
  }

  Widget _buildContent() {
    if (_applicationStatus == 'pending') {
      return _statusCard(
        icon: Icons.hourglass_top_rounded,
        title: 'Application Under Review',
        message:
            'Your application has been submitted. An admin will review it before you can collaborate with experts.',
      );
    }

    if (_applicationStatus == 'approved') {
      return _statusCard(
        icon: Icons.verified_rounded,
        title: 'You are a Community Collaborator',
        message:
            'Your application has been approved. You can now collaborate with verified experts to create community events.',
      );
    }

    if (_applicationStatus == 'rejected') {
      return _applicationForm(
        heading: 'Apply Again',
        description:
            'Your previous application was not approved. You can submit a new application explaining your experience and motivation.',
      );
    }

    return _applicationForm(
      heading: 'Become a Community Collaborator',
      description:
          'Community Collaborators share their lived experiences and work with verified professionals to create supportive events for the vitiligo community.',
    );
  }

  Widget _applicationForm({
    required String heading,
    required String description,
  }) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.pastelGreen,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.people_alt_outlined,
                  size: 48,
                  color: AppTheme.primaryDark,
                ),
                const SizedBox(height: 12),
                Text(
                  heading,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: AppTheme.textGrey,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Why would you like to become a Community Collaborator?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),

          const SizedBox(height: 10),

          TextFormField(
            controller: _reasonController,
            maxLines: 7,
            decoration: InputDecoration(
              hintText:
                  'Share your experience, motivation, or how you would like to support others...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Colors.grey.shade300,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: AppTheme.primaryDark,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please tell us why you want to become a collaborator.';
              }

              if (value.trim().length < 30) {
                return 'Please provide a little more detail.';
              }

              return null;
            },
          ),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.pastelBlue,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppTheme.primaryDark,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Community Collaborators are not medical professionals. '
                    'They share lived experiences and work together with verified experts.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitApplication,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Submit Application',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusCard({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 60,
              color: AppTheme.primaryDark,
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppTheme.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}