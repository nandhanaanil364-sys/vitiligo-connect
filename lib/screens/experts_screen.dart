import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'expert_profile_screen.dart';
import 'my_questions_screen.dart';

class ExpertsScreen extends StatelessWidget {
  const ExpertsScreen({super.key});

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,

      // ==========================================================
      // APP BAR
      // ==========================================================

      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        automaticallyImplyLeading: false,

        title: const Text(
          'Expert Support',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),

        // ========================================================
        // MY QUESTIONS & ANSWERS
        // ========================================================

        actions: [
          IconButton(
            tooltip: 'My Questions & Answers',
            icon: const Icon(
              Icons.question_answer_outlined,
              color: AppTheme.primaryDark,
              size: 25,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const MyQuestionsScreen(),
                ),
              );
            },
          ),

          const SizedBox(width: 6),
        ],
      ),

      // ==========================================================
      // BODY
      // ==========================================================

      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('experts')
            .where(
              'status',
              isEqualTo: 'approved',
            )
            .snapshots(),

        builder: (context, snapshot) {
          // =====================================================
          // LOADING
          // =====================================================

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // =====================================================
          // ERROR
          // =====================================================

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 55,
                      color: Colors.redAccent,
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'Unable to load experts',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppTheme.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final experts =
              snapshot.data?.docs ?? [];

          // =====================================================
          // NO EXPERTS
          // =====================================================

          if (experts.isEmpty) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                20,
                10,
                20,
                30,
              ),
              children: [
                _buildIntroduction(),

                const SizedBox(height: 28),

                const Center(
                  child: Icon(
                    Icons.people_outline_rounded,
                    size: 65,
                    color: AppTheme.primary,
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  'No verified experts available yet',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Verified dermatologists and psychologists '
                  'will appear here after admin approval.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textGrey,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 30),

                _buildHowItWorks(),
              ],
            );
          }

          // =====================================================
          // EXPERT LIST
          // =====================================================

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              20,
              10,
              20,
              30,
            ),
            children: [
              _buildIntroduction(),

              const SizedBox(height: 28),

              const Text(
                'Verified Professionals',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'View their professional profiles before '
                'choosing an expert.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textGrey,
                ),
              ),

              const SizedBox(height: 16),

              ...experts.map((doc) {
                final data =
                    doc.data()
                        as Map<String, dynamic>;

                return Padding(
                  padding:
                      const EdgeInsets.only(bottom: 14),
                  child: _ExpertProfileCard(
                    expertId: doc.id,
                    data: data,
                  ),
                );
              }),

              const SizedBox(height: 18),

              _buildHowItWorks(),

              const SizedBox(height: 25),

              _buildImportantNote(),
            ],
          );
        },
      ),
    );
  }

  // ==========================================================
  // INTRODUCTION
  // ==========================================================

  static Widget _buildIntroduction() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.pastelGreen,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.support_agent_rounded,
            size: 42,
            color: AppTheme.primaryDark,
          ),

          SizedBox(height: 12),

          Text(
            'You are not alone',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),

          SizedBox(height: 8),

          Text(
            'Connect with verified professionals and '
            'choose an expert after viewing their profile.',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textGrey,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // HOW IT WORKS
  // ==========================================================

  static Widget _buildHowItWorks() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'How It Works',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),

        const SizedBox(height: 12),

        const _StepCard(
          number: '1',
          icon: Icons.person_search_rounded,
          title: 'Choose an expert',
          description:
              'Browse verified dermatologists and psychologists.',
        ),

        const SizedBox(height: 10),

        const _StepCard(
          number: '2',
          icon: Icons.badge_outlined,
          title: 'View their profile',
          description:
              'Check their qualification, experience and professional information.',
        ),

        const SizedBox(height: 10),

        const _StepCard(
          number: '3',
          icon: Icons.chat_bubble_outline_rounded,
          title: 'Ask your question',
          description:
              'Choose the expert and send your question or support request.',
        ),
      ],
    );
  }

  // ==========================================================
  // IMPORTANT NOTE
  // ==========================================================

  static Widget _buildImportantNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.pastelYellow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppTheme.primaryDark,
          ),

          SizedBox(width: 10),

          Expanded(
            child: Text(
              'Professional responses are intended for general '
              'information and support. They do not replace an '
              'in-person medical examination or professional diagnosis.',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textDark,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// EXPERT PROFILE CARD
// ============================================================

class _ExpertProfileCard extends StatelessWidget {
  final String expertId;
  final Map<String, dynamic> data;

  const _ExpertProfileCard({
    required this.expertId,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final String name =
        data['name']?.toString() ??
            'Unknown Expert';

    final String expertType =
        data['expertType']?.toString() ??
            'Professional';

    final String qualification =
        data['qualification']?.toString() ??
            'Qualification not available';

    final String experience =
        data['experience']?.toString() ??
            'Experience not available';

    final String workplace =
        data['workplace']?.toString() ??
            'Workplace not available';

    final String district =
        data['district']?.toString() ??
            'Location not available';

    final bool isDermatologist =
        expertType.toLowerCase().contains(
              'dermatologist',
            );

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius:
            BorderRadius.circular(18),

        // =====================================================
        // OPEN FULL EXPERT PROFILE
        // =====================================================

        onTap: () {
          _openExpertProfile(context);
        },

        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: isDermatologist
                          ? AppTheme.pastelBlue
                          : AppTheme.pastelPink,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isDermatologist
                          ? Icons
                              .health_and_safety_rounded
                          : Icons
                              .psychology_rounded,
                      color:
                          AppTheme.primaryDark,
                      size: 30,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style:
                                    const TextStyle(
                                  fontSize: 18,
                                  fontWeight:
                                      FontWeight.bold,
                                  color:
                                      AppTheme.textDark,
                                ),
                              ),
                            ),

                            const Icon(
                              Icons.verified_rounded,
                              size: 20,
                              color:
                                  AppTheme.primaryDark,
                            ),
                          ],
                        ),

                        const SizedBox(height: 5),

                        Text(
                          expertType,
                          style:
                              const TextStyle(
                            fontSize: 14,
                            fontWeight:
                                FontWeight.w600,
                            color:
                                AppTheme.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _InfoRow(
                icon: Icons.school_outlined,
                text: qualification,
              ),

              const SizedBox(height: 8),

              _InfoRow(
                icon:
                    Icons.work_outline_rounded,
                text:
                    '$experience experience',
              ),

              const SizedBox(height: 8),

              _InfoRow(
                icon:
                    Icons.local_hospital_outlined,
                text: workplace,
              ),

              const SizedBox(height: 8),

              _InfoRow(
                icon:
                    Icons.location_on_outlined,
                text: district,
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _openExpertProfile(context);
                  },
                  icon: const Icon(
                    Icons.person_outline_rounded,
                  ),
                  label: const Text(
                    'View Profile',
                  ),
                  style:
                      OutlinedButton.styleFrom(
                    foregroundColor:
                        AppTheme.primaryDark,
                    side: const BorderSide(
                      color:
                          AppTheme.primaryDark,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // OPEN EXPERT PROFILE SCREEN
  // ==========================================================

  void _openExpertProfile(
    BuildContext context,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ExpertProfileScreen(
          expertId: expertId,
          expertData: data,
        ),
      ),
    );
  }
}

// ============================================================
// INFO ROW
// ============================================================

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: AppTheme.primaryDark,
        ),

        const SizedBox(width: 9),

        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textGrey,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// STEP CARD
// ============================================================

class _StepCard extends StatelessWidget {
  final String number;
  final IconData icon;
  final String title;
  final String description;

  const _StepCard({
    required this.number,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE8ECE9),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration:
                const BoxDecoration(
              color: AppTheme.pastelGreen,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      AppTheme.primaryDark,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          Icon(
            icon,
            color:
                AppTheme.primaryDark,
            size: 24,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                      const TextStyle(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w600,
                    color:
                        AppTheme.textDark,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  description,
                  style:
                      const TextStyle(
                    fontSize: 12,
                    color:
                        AppTheme.textGrey,
                    height: 1.3,
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