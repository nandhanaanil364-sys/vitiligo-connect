import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/app_theme.dart';

class AddResourceScreen extends StatefulWidget {
  const AddResourceScreen({super.key});

  @override
  State<AddResourceScreen> createState() =>
      _AddResourceScreenState();
}

class _AddResourceScreenState
    extends State<AddResourceScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController =
      TextEditingController();

  final TextEditingController
      _descriptionController =
      TextEditingController();

  final TextEditingController _contentController =
      TextEditingController();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  String selectedCategory = 'Awareness';

  final List<String> categories = [
    'Awareness',
    'Treatment',
    'Skin Care',
    'Mental Health',
    'Lifestyle',
    'Nutrition',
    'FAQ',
  ];

  bool _isSaving = false;

  // ======================================================
  // SAVE RESOURCE
  // ======================================================

  Future<void> _saveResource() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = _auth.currentUser;

    if (user == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Get expert profile
      final expertDocument = await _firestore
          .collection('experts')
          .doc(user.uid)
          .get();

      String expertName =
          user.displayName ?? 'Expert';

      if (expertDocument.exists) {
        final data =
            expertDocument.data();

        if (data != null &&
            data['name'] != null) {
          expertName =
              data['name'].toString();
        }
      }

      await _firestore
          .collection('educationalResources')
          .add({
        'title':
            _titleController.text.trim(),

        'category':
            selectedCategory,

        'shortDescription':
            _descriptionController.text
                .trim(),

        'content':
            _contentController.text
                .trim(),

        'expertId':
            user.uid,

        'expertName':
            expertName,

        // New resources need approval
        'status':
            'pending',

        'createdAt':
            FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      await showDialog(
        context: context,

        builder: (context) {
          return AlertDialog(
            title: const Text(
              'Resource Submitted',
            ),

            content: const Text(
              'Your educational resource has been submitted successfully and is waiting for admin approval.',
            ),

            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },

                child: const Text(
                  'OK',
                ),
              ),
            ],
          );
        },
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      debugPrint(
        'RESOURCE: Save error: $e',
      );

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              'Unable to submit resource.\n$e',
            ),
            behavior:
                SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ======================================================
  // DISPOSE
  // ======================================================

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _contentController.dispose();

    super.dispose();
  }

  // ======================================================
  // BUILD
  // ======================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppTheme.background,

      appBar: AppBar(
        backgroundColor:
            AppTheme.background,

        elevation: 0,

        title: const Text(
          'Add Resource',
          style: TextStyle(
            fontSize: 21,
            fontWeight:
                FontWeight.bold,
            color:
                AppTheme.textDark,
          ),
        ),
      ),

      body: Form(
        key: _formKey,

        child: ListView(
          padding:
              const EdgeInsets.fromLTRB(
            20,
            10,
            20,
            30,
          ),

          children: [
            // ==================================================
            // TITLE
            // ==================================================

            const Text(
              'Resource Title',
              style: TextStyle(
                fontSize: 14,
                fontWeight:
                    FontWeight.w600,
                color:
                    AppTheme.textDark,
              ),
            ),

            const SizedBox(height: 8),

            TextFormField(
              controller:
                  _titleController,

              decoration:
                  const InputDecoration(
                hintText:
                    'Enter resource title',
              ),

              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Please enter a title';
                }

                return null;
              },
            ),

            const SizedBox(height: 20),

            // ==================================================
            // CATEGORY
            // ==================================================

            const Text(
              'Category',
              style: TextStyle(
                fontSize: 14,
                fontWeight:
                    FontWeight.w600,
                color:
                    AppTheme.textDark,
              ),
            ),

            const SizedBox(height: 8),

            DropdownButtonFormField<
                String>(
              value: selectedCategory,

              decoration:
                  const InputDecoration(
                hintText:
                    'Select category',
              ),

              items: categories
                  .map(
                    (category) =>
                        DropdownMenuItem(
                      value: category,
                      child:
                          Text(category),
                    ),
                  )
                  .toList(),

              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedCategory =
                        value;
                  });
                }
              },
            ),

            const SizedBox(height: 20),

            // ==================================================
            // SHORT DESCRIPTION
            // ==================================================

            const Text(
              'Short Description',
              style: TextStyle(
                fontSize: 14,
                fontWeight:
                    FontWeight.w600,
                color:
                    AppTheme.textDark,
              ),
            ),

            const SizedBox(height: 8),

            TextFormField(
              controller:
                  _descriptionController,

              maxLines: 3,

              decoration:
                  const InputDecoration(
                hintText:
                    'Briefly describe this resource',
              ),

              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Please enter a short description';
                }

                return null;
              },
            ),

            const SizedBox(height: 20),

            // ==================================================
            // CONTENT
            // ==================================================

            const Text(
              'Resource Content',
              style: TextStyle(
                fontSize: 14,
                fontWeight:
                    FontWeight.w600,
                color:
                    AppTheme.textDark,
              ),
            ),

            const SizedBox(height: 8),

            TextFormField(
              controller:
                  _contentController,

              maxLines: 10,

              decoration:
                  const InputDecoration(
                hintText:
                    'Enter the educational content here',
                alignLabelWithHint:
                    true,
              ),

              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Please enter resource content';
                }

                return null;
              },
            ),

            const SizedBox(height: 25),

            // ==================================================
            // APPROVAL NOTICE
            // ==================================================

            Container(
              padding:
                  const EdgeInsets.all(15),

              decoration:
                  BoxDecoration(
                color:
                    AppTheme.pastelYellow,

                borderRadius:
                    BorderRadius.circular(
                  16,
                ),
              ),

              child: const Row(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                children: [
                  Icon(
                    Icons.info_outline,
                    color:
                        AppTheme.textDark,
                  ),

                  SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      'Your resource will be reviewed by the administrator before it becomes visible to users.',
                      style:
                          TextStyle(
                        fontSize: 13,
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

            // ==================================================
            // SUBMIT BUTTON
            // ==================================================

            ElevatedButton(
              onPressed: _isSaving
                  ? null
                  : _saveResource,

              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,

                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                        color:
                            Colors.white,
                      ),
                    )
                  : const Text(
                      'Submit for Approval',
                    ),
            ),
          ],
        ),
      ),
    );
  }
}