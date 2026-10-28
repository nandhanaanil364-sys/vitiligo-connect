
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CollaborationRequestsScreen extends StatefulWidget {
  const CollaborationRequestsScreen({super.key});

  @override
  State<CollaborationRequestsScreen> createState() =>
      _CollaborationRequestsScreenState();
}

class _CollaborationRequestsScreenState
    extends State<CollaborationRequestsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _processingEventId;

  String _text(dynamic value, [String fallback = 'Not provided']) {
    if (value == null || value.toString().trim().isEmpty) {
      return fallback;
    }
    return value.toString();
  }

  String _formatDate(dynamic value) {
    DateTime? date;

    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    } else if (value is String) {
      date = DateTime.tryParse(value);
    }

    if (date == null) return 'Date not provided';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Future<void> _updateRequest(
    String eventId, {
    required bool accept,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('Please log in again.');
      return;
    }

    setState(() => _processingEventId = eventId);

    try {
      await _firestore.runTransaction((transaction) async {
        final eventRef = _firestore.collection('events').doc(eventId);
        final snapshot = await transaction.get(eventRef);

        if (!snapshot.exists) {
          throw Exception('This event proposal no longer exists.');
        }

        final data = snapshot.data()!;

        // Verify that this proposal belongs to the signed-in expert.
        if (data['expertId'] != user.uid) {
          throw Exception('You are not assigned to this proposal.');
        }

        if (data['eventCreatorType'] != 'communityCollaborator' ||
            data['collaborationStatus'] != 'pendingExpert' ||
            data['status'] != 'pending') {
          throw Exception('This proposal has already been processed.');
        }

        transaction.update(eventRef, {
          'collaborationStatus': accept ? 'pendingAdmin' : 'rejected',
          'status': accept ? 'pending' : 'rejected',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      if (!mounted) return;

      _showMessage(
        accept
            ? 'Proposal accepted and sent to admin for final approval.'
            : 'Proposal declined.',
      );
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => _processingEventId = null);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Collaboration Requests')),
        body: const Center(
          child: Text('Please log in to view collaboration requests.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Collaboration Requests'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        // Query by expert ID; filter the proposal status below.
        stream: _firestore
            .collection('events')
            .where('expertId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load requests.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data?.docs.where((doc) {
                final data = doc.data();
                return data['eventCreatorType'] ==
                        'communityCollaborator' &&
                    data['collaborationStatus'] == 'pendingExpert' &&
                    data['status'] == 'pending';
              }).toList() ??
              [];

          if (requests.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.event_available_outlined,
                      size: 56,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'No collaboration requests yet.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'New proposals assigned to you will appear here.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final doc = requests[index];
              final data = doc.data();
              final isProcessing = _processingEventId == doc.id;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CircleAvatar(
                            child: Icon(Icons.event_note),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _text(data['title'], 'Untitled event'),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(_text(data['description'])),
                      const SizedBox(height: 14),
                      _detail(
                        Icons.person_outline,
                        'Proposed by',
                        _text(data['collaboratorName']),
                      ),
                      _detail(
                        Icons.calendar_today_outlined,
                        'Date',
                        _formatDate(data['date'] ?? data['eventDate']),
                      ),
                      _detail(
                        Icons.access_time,
                        'Time',
                        _text(data['time']),
                      ),
                      _detail(
                        Icons.location_on_outlined,
                        'Mode / Venue',
                        '${_text(data['mode'])} / '
                            '${_text(data['venue'] ?? data['location'])}',
                      ),
                      const SizedBox(height: 18),
                      if (isProcessing)
                        const Center(child: CircularProgressIndicator())
                      else
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _updateRequest(
                                  doc.id,
                                  accept: false,
                                ),
                                icon: const Icon(Icons.close),
                                label: const Text('Decline'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => _updateRequest(
                                  doc.id,
                                  accept: true,
                                ),
                                icon: const Icon(Icons.check),
                                label: const Text('Accept'),
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

  Widget _detail(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: Colors.grey.shade700),
          const SizedBox(width: 9),
          SizedBox(
            width: 95,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
