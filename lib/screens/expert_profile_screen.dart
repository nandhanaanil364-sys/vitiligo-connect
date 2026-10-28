import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ExpertProfileScreen extends StatelessWidget {
  final String expertId;
  final Map<String, dynamic> expertData;

  const ExpertProfileScreen({
    super.key,
    required this.expertId,
    required this.expertData,
  });

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  String _value(String key) {
    final value = expertData[key];

    if (value == null || value.toString().trim().isEmpty) {
      return 'Not provided';
    }

    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final name = _value('name');
    final expertType = _value('expertType');
    final qualification = _value('qualification');
    final experience = _value('experience');
    final workplace = _value('workplace');
    final district = _value('district');
    final bio = _value('bio');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expert Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =================================================
            // PROFILE HEADER
            // =================================================

            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundColor: AppTheme.pastelGreen,
                    child: Icon(
                      expertType.toLowerCase().contains('psych')
                          ? Icons.psychology_outlined
                          : Icons.medical_services_outlined,
                      size: 42,
                      color: AppTheme.primaryDark,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium,
                        ),
                      ),

                      const SizedBox(width: 6),

                      const Icon(
                        Icons.verified,
                        color: AppTheme.primaryDark,
                        size: 22,
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.pastelBlue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      expertType,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // =================================================
            // PROFESSIONAL INFORMATION
            // =================================================

            const Text(
              'Professional Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),

            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _ProfileInfoTile(
                      icon: Icons.school_outlined,
                      title: 'Qualification',
                      value: qualification,
                    ),

                    const Divider(),

                    _ProfileInfoTile(
                      icon: Icons.work_history_outlined,
                      title: 'Experience',
                      value: experience,
                    ),

                    const Divider(),

                    _ProfileInfoTile(
                      icon: Icons.local_hospital_outlined,
                      title: 'Workplace',
                      value: workplace,
                    ),

                    const Divider(),

                    _ProfileInfoTile(
                      icon: Icons.location_on_outlined,
                      title: 'District',
                      value: district,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // =================================================
            // ABOUT
            // =================================================

            const Text(
              'About',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),

            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  bio,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // =================================================
            // RESOURCES SHARED
            // =================================================

            Row(
              children: [
                const Icon(
                  Icons.menu_book_outlined,
                  color: AppTheme.primaryDark,
                ),

                const SizedBox(width: 8),

                const Text(
                  'Resources Shared',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('educationalResources')
                  .where(
                    'expertId',
                    isEqualTo: expertId,
                  )
                  .where(
                    'status',
                    isEqualTo: 'approved',
                  )
                  .snapshots(),

              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Unable to load resources right now.',
                        style: TextStyle(
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  );
                }

                final resources = snapshot.data?.docs ?? [];

                if (resources.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.menu_book_outlined,
                            size: 42,
                            color: AppTheme.textGrey,
                          ),

                          const SizedBox(height: 10),

                          const Text(
                            'No resources shared yet.',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark,
                            ),
                          ),

                          const SizedBox(height: 4),

                          const Text(
                            'Approved educational resources will appear here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.textGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: resources.map((doc) {
                    final data =
                        doc.data() as Map<String, dynamic>;

                    return _ResourceCard(
                      title: data['title']?.toString() ??
                          'Untitled Resource',
                      category:
                          data['category']?.toString() ??
                              'General',
                      content:
                          data['content']?.toString() ?? '',
                      onTap: () {
                        _showResource(
                          context,
                          data,
                        );
                      },
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 28),

            // =================================================
            // REVIEWS RECEIVED
            // =================================================

            Row(
              children: [
                const Icon(
                  Icons.star_outline_rounded,
                  color: AppTheme.primaryDark,
                ),

                const SizedBox(width: 8),

                const Text(
                  'Reviews Received',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            _ReviewsSection(
              expertId: expertId,
              firestore: _firestore,
            ),

            const SizedBox(height: 28),

            // =================================================
            // ASK THIS EXPERT
            // =================================================

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _showAskQuestionDialog(
                    context,
                    name,
                  );
                },
                icon: const Icon(
                  Icons.question_answer_outlined,
                ),
                label: const Text(
                  'Ask This Expert',
                ),
              ),
            ),

            const SizedBox(height: 12),

            const Center(
              child: Text(
                'Verified professionals can provide educational and supportive guidance.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textGrey,
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // ASK QUESTION DIALOG
  // ==========================================================

  void _showAskQuestionDialog(
    BuildContext context,
    String expertName,
  ) {
    final questionController = TextEditingController();

    bool isSending = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),

              title: Text(
                'Ask $expertName',
                style: const TextStyle(
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.bold,
                ),
              ),

              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Write your question below. The verified expert can provide educational and supportive guidance.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: AppTheme.textGrey,
                      ),
                    ),

                    const SizedBox(height: 18),

                    TextField(
                      controller: questionController,
                      maxLines: 6,
                      enabled: !isSending,
                      decoration: const InputDecoration(
                        labelText: 'Your Question',
                        hintText:
                            'Write your question here...',
                        alignLabelWithHint: true,
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(
                            bottom: 65,
                          ),
                          child: Icon(
                            Icons.help_outline_rounded,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed: isSending
                      ? null
                      : () {
                          Navigator.pop(
                            dialogContext,
                          );
                        },
                  child: const Text(
                    'Cancel',
                  ),
                ),

                ElevatedButton(
                  onPressed: isSending
                      ? null
                      : () async {
                          final question =
                              questionController.text.trim();

                          if (question.length < 5) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please enter a question.',
                                ),
                              ),
                            );
                            return;
                          }

                          setDialogState(() {
                            isSending = true;
                          });

                          final success =
                              await _sendQuestion(
                            question,
                            expertName,
                            context,
                          );

                          if (success) {
                            Navigator.pop(
                              dialogContext,
                            );

                            _showQuestionSentMessage(
                              context,
                            );
                          } else {
                            setDialogState(() {
                              isSending = false;
                            });
                          }
                        },
                  child: isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Send Question',
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ==========================================================
  // SEND QUESTION
  // ==========================================================

  Future<bool> _sendQuestion(
    String question,
    String expertName,
    BuildContext context,
  ) async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please log in before asking an expert.',
          ),
        ),
      );

      return false;
    }

    try {
      // Get current user's profile
      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      final userData = userDoc.data() ?? {};

      final userName =
          userData['name']?.toString() ??
          user.displayName ??
          'User';

      final userEmail = user.email ?? '';

      // Create expert question
      await _firestore
          .collection('expertQuestions')
          .add({
        'userId': user.uid,
        'userName': userName,
        'userEmail': userEmail,
        'expertId': expertId,
        'expertName': expertName,
        'question': question,
        'answer': '',
        'status': 'pending',
        'createdAt':
            FieldValue.serverTimestamp(),
        'answeredAt': null,
      });

      return true;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to send question: $e',
          ),
        ),
      );

      return false;
    }
  }

  // ==========================================================
  // QUESTION SENT MESSAGE
  // ==========================================================

  void _showQuestionSentMessage(
    BuildContext context,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),

          title: const Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: AppTheme.primaryDark,
              ),

              SizedBox(width: 10),

              Expanded(
                child: Text(
                  'Question Sent',
                  style: TextStyle(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          content: const Text(
            'Your question has been sent to the selected expert. You can check back later for their response.',
            style: TextStyle(
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

  // ==========================================================
  // SHOW RESOURCE
  // ==========================================================

  void _showResource(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final title =
        data['title']?.toString() ?? 'Resource';

    final category =
        data['category']?.toString() ?? 'General';

    final content =
        data['content']?.toString() ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          constraints: const BoxConstraints(
            maxHeight: 650,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),

                const SizedBox(height: 8),

                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.pastelBlue,
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: Text(
                    category,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: AppTheme.textDark,
                  ),
                ),

                const SizedBox(height: 24),

                Container(
                  padding:
                      const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.pastelGreen,
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                  child: const Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.verified_outlined,
                        color:
                            AppTheme.primaryDark,
                      ),

                      SizedBox(width: 10),

                      Expanded(
                        child: Text(
                          'This resource was shared by a verified professional and approved by the Vitiligo Connect admin team.',
                          style: TextStyle(
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
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================
// REVIEWS SECTION
// ============================================================

class _ReviewsSection extends StatelessWidget {
  final String expertId;
  final FirebaseFirestore firestore;

  const _ReviewsSection({
    required this.expertId,
    required this.firestore,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection('expertReviews')
          .where(
            'expertId',
            isEqualTo: expertId,
          )
          .snapshots(),

      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Unable to load reviews right now.',
                style: TextStyle(
                  color: Colors.red.shade700,
                ),
              ),
            ),
          );
        }

        final reviews = snapshot.data?.docs ?? [];

        if (reviews.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(
                    Icons.star_outline_rounded,
                    size: 42,
                    color: AppTheme.textGrey,
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'No reviews yet',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),

                  const SizedBox(height: 4),

                  const Text(
                    'Reviews from users who interact with this expert will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textGrey,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: reviews.map((doc) {
            final data =
                doc.data() as Map<String, dynamic>;

            return _ReviewCard(
              data: data,
            );
          }).toList(),
        );
      },
    );
  }
}

// ============================================================
// REVIEW CARD
// ============================================================

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _ReviewCard({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final userName =
        data['userName']?.toString() ??
            'Anonymous User';

    final comment =
        data['comment']?.toString() ?? '';

    final ratingValue = data['rating'];

    double rating = 0;

    if (ratingValue is num) {
      rating = ratingValue.toDouble();
    } else {
      rating = double.tryParse(
            ratingValue?.toString() ?? '',
          ) ??
          0;
    }

    if (rating < 0) {
      rating = 0;
    }

    if (rating > 5) {
      rating = 5;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor:
                      AppTheme.pastelGreen,
                  child: Text(
                    userName.isNotEmpty
                        ? userName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: List.generate(
                5,
                (index) {
                  return Icon(
                    index < rating.round()
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 20,
                    color: AppTheme.primaryDark,
                  );
                },
              ),
            ),

            if (comment.isNotEmpty) ...[
              const SizedBox(height: 10),

              Text(
                comment,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================
// RESOURCE CARD
// ============================================================

class _ResourceCard extends StatelessWidget {
  final String title;
  final String category;
  final String content;
  final VoidCallback onTap;

  const _ResourceCard({
    required this.title,
    required this.category,
    required this.content,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    String preview = content.trim();

    if (preview.length > 100) {
      preview =
          '${preview.substring(0, 100)}...';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.pastelGreen,
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.menu_book_outlined,
                      color: AppTheme.primaryDark,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.pastelBlue,
                  borderRadius:
                      BorderRadius.circular(15),
                ),
                child: Text(
                  category,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Text(
                preview.isEmpty
                    ? 'No preview available.'
                    : preview,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: AppTheme.textGrey,
                ),
              ),

              const SizedBox(height: 10),

              const Row(
                mainAxisAlignment:
                    MainAxisAlignment.end,
                children: [
                  Text(
                    'Read Resource',
                    style: TextStyle(
                      color: AppTheme.primaryDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  SizedBox(width: 4),

                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: AppTheme.primaryDark,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// PROFILE INFO TILE
// ============================================================

class _ProfileInfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _ProfileInfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 8,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppTheme.primaryDark,
            size: 22,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textGrey,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}