import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyQuestionsScreen extends StatelessWidget {
  const MyQuestionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F2),
      appBar: AppBar(
        title: const Text(
          'My Questions & Answers',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: user == null
          ? const Center(
              child: Text(
                'Please log in to view your questions.',
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('expertQuestions')
                  .where(
                    'userId',
                    isEqualTo: user.uid,
                  )
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Unable to load your questions.\n\n'
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final documents =
                    snapshot.data?.docs ?? [];

                if (documents.isEmpty) {
                  return _buildEmptyState();
                }

                // Sort newest questions first.
                documents.sort((a, b) {
                  final aData =
                      a.data() as Map<String, dynamic>;
                  final bData =
                      b.data() as Map<String, dynamic>;

                  final aTime = aData['createdAt'];
                  final bTime = bData['createdAt'];

                  if (aTime is Timestamp &&
                      bTime is Timestamp) {
                    return bTime.compareTo(aTime);
                  }

                  return 0;
                });

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: documents.length,
                  itemBuilder: (context, index) {
                    final document = documents[index];

                    final data = document.data()
                        as Map<String, dynamic>;

                    return _QuestionAnswerCard(
                      data: data,
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFF8FA3B5)
                    .withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.question_answer_outlined,
                size: 45,
                color: Color(0xFF7B8FA1),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Questions Yet',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Questions you ask experts will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionAnswerCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _QuestionAnswerCard({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final String expertName =
        (data['expertName'] ?? 'Expert').toString();

    final String question =
        (data['question'] ?? '').toString();

    final String answer =
        (data['answer'] ?? '').toString();

    final String status =
        (data['status'] ?? 'pending').toString();

    final bool isAnswered =
        status.toLowerCase() == 'answered' &&
        answer.trim().isNotEmpty;

    final Timestamp? createdAt =
        data['createdAt'] is Timestamp
            ? data['createdAt'] as Timestamp
            : null;

    final Timestamp? answeredAt =
        data['answeredAt'] is Timestamp
            ? data['answeredAt'] as Timestamp
            : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 18),
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // --------------------------------------------------
            // EXPERT + STATUS
            // --------------------------------------------------

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8FA3B5)
                        .withOpacity(0.12),
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.medical_services_outlined,
                    color: Color(0xFF6F8497),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Question to',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black45,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        expertName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(isAnswered),
              ],
            ),

            const SizedBox(height: 18),

            // --------------------------------------------------
            // QUESTION
            // --------------------------------------------------

            const Text(
              'Your Question',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius:
                    BorderRadius.circular(13),
              ),
              child: Text(
                question,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.45,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // --------------------------------------------------
            // ANSWERED
            // --------------------------------------------------

            if (isAnswered) ...[
              const Text(
                'Expert Response',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.06),
                  borderRadius:
                      BorderRadius.circular(13),
                  border: Border.all(
                    color:
                        Colors.green.withOpacity(0.15),
                  ),
                ),
                child: Text(
                  answer,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ),

              if (answeredAt != null) ...[
                const SizedBox(height: 10),
                Text(
                  'Answered on ${_formatDate(answeredAt)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black45,
                  ),
                ),
              ],
            ]

            // --------------------------------------------------
            // PENDING
            // --------------------------------------------------

            else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color:
                      Colors.orange.withOpacity(0.07),
                  borderRadius:
                      BorderRadius.circular(13),
                ),
                child: const Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 20,
                      color: Colors.orange,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your question is waiting for a response from the expert.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // --------------------------------------------------
            // QUESTION DATE
            // --------------------------------------------------

            if (createdAt != null) ...[
              const SizedBox(height: 12),
              Text(
                'Asked on ${_formatDate(createdAt)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black38,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(bool isAnswered) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: isAnswered
            ? Colors.green.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isAnswered ? 'Answered' : 'Pending',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isAnswered
              ? Colors.green.shade700
              : Colors.orange.shade700,
        ),
      ),
    );
  }

  static String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();

    final day =
        date.day.toString().padLeft(2, '0');

    final month =
        date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }
}