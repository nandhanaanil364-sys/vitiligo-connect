import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminCollaboratorApplicationsScreen extends StatelessWidget {
  const AdminCollaboratorApplicationsScreen({super.key});

  final Color green = const Color(0xFFB7D9C4);
  final Color darkText = const Color(0xFF333333);

  Future<void> _updateStatus(
    BuildContext context,
    String userId,
    String status,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('collaboratorApplications')
          .doc(userId)
          .update({
        'status': status,
        if (status == 'approved')
          'approvedAt': FieldValue.serverTimestamp(),
        if (status == 'approved') 'approvedBy': 'admin',
        if (status == 'rejected')
          'rejectedAt': FieldValue.serverTimestamp(),
        if (status == 'rejected') 'rejectedBy': 'admin',
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'approved'
                  ? 'Collaborator approved successfully.'
                  : 'Application rejected.',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating application: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collaborator Applications'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('collaboratorApplications')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'FIRESTORE ERROR:\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Text('No Firestore data received.'),
            );
          }

          final applications = snapshot.data!.docs;

          if (applications.isEmpty) {
            return const Center(
              child: Text(
                'Firestore returned 0 collaborator applications.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: applications.length,
            itemBuilder: (context, index) {
              final doc = applications[index];
              final data = doc.data() as Map<String, dynamic>;

              final name = data['name'] ?? 'Unknown User';
              final email = data['email'] ?? '';
              final reason = data['reason'] ?? '';
              final status = data['status'] ?? 'unknown';

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: green,
                            child: Icon(
                              Icons.person,
                              color: darkText,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name.toString(),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: darkText,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  email.toString(),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      Text(
                        'Status: $status',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: darkText,
                        ),
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        'Why they want to become a collaborator',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        reason.toString(),
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: status == 'pending'
                                  ? () {
                                      _updateStatus(
                                        context,
                                        doc.id,
                                        'rejected',
                                      );
                                    }
                                  : null,
                              icon: const Icon(Icons.close),
                              label: const Text('Reject'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: status == 'pending'
                                  ? () {
                                      _updateStatus(
                                        context,
                                        doc.id,
                                        'approved',
                                      );
                                    }
                                  : null,
                              icon: const Icon(Icons.check),
                              label: const Text('Approve'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: green,
                                foregroundColor: darkText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}