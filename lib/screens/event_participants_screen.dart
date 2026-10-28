import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/event_model.dart';
import '../theme/app_theme.dart';

class EventParticipantsScreen extends StatelessWidget {
  final Event event;

  const EventParticipantsScreen({
    super.key,
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    final registrationsStream = FirebaseFirestore.instance
        .collection('events')
        .doc(event.id)
        .collection('registrations')
        .orderBy('registeredAt', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registered Participants'),
      ),
      body: Column(
        children: [
          _buildEventHeader(),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: registrationsStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Unable to load participants.',
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

                final registrations =
                    snapshot.data?.docs ?? [];

                if (registrations.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    24,
                  ),
                  itemCount: registrations.length,
                  itemBuilder: (context, index) {
                    final registration =
                        registrations[index];

                    final data = registration.data()
                        as Map<String, dynamic>;

                    return _buildParticipantCard(
                      context,
                      data,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // EVENT HEADER
  // ------------------------------------------------------------

  Widget _buildEventHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        8,
      ),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.pastelGreen,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: Icon(
                  event.icon,
                  color: AppTheme.primaryDark,
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  event.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: AppTheme.textDark,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  event.date,
                  style: TextStyle(
                    color: AppTheme.textDark,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Icon(
                Icons.access_time_outlined,
                size: 17,
                color: AppTheme.textDark,
              ),
              const SizedBox(width: 7),
              Text(
                event.time,
                style: TextStyle(
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Icon(
                Icons.people_outline,
                size: 18,
                color: AppTheme.textDark,
              ),
              const SizedBox(width: 7),
              Text(
                '${event.participants} registered',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // PARTICIPANT CARD
  // ------------------------------------------------------------

  Widget _buildParticipantCard(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final name =
        (data['name'] ?? 'Unknown User').toString();

    final email =
        (data['email'] ?? '').toString();

    final phone =
        (data['phone'] ?? '').toString();

    final age = data['age'] != null
        ? data['age'].toString()
        : '';

    final message =
        (data['message'] ?? '').toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // --------------------------------------------------
            // NAME + AGE
            // --------------------------------------------------

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor:
                      AppTheme.pastelGreen,
                  child: Icon(
                    Icons.person_outline,
                    color: AppTheme.primaryDark,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),

                      if (age.isNotEmpty)
                        Padding(
                          padding:
                              const EdgeInsets.only(
                            top: 4,
                          ),
                          child: Text(
                            'Age: $age',
                            style: TextStyle(
                              color: AppTheme.textGrey,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            // --------------------------------------------------
            // EMAIL
            // --------------------------------------------------

            if (email.isNotEmpty) ...[
              const SizedBox(height: 16),

              _buildInfoRow(
                Icons.email_outlined,
                email,
              ),
            ],

            // --------------------------------------------------
            // PHONE
            // --------------------------------------------------

            if (phone.isNotEmpty) ...[
              const SizedBox(height: 10),

              _buildInfoRow(
                Icons.phone_outlined,
                phone,
              ),
            ],

            // --------------------------------------------------
            // MESSAGE
            // --------------------------------------------------

            if (message.isNotEmpty) ...[
              const SizedBox(height: 14),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                 color: Colors.grey.shade50,
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Message',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textGrey,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      message,
                      style: TextStyle(
                        color: AppTheme.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // INFORMATION ROW
  // ------------------------------------------------------------

  Widget _buildInfoRow(
    IconData icon,
    String text,
  ) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 19,
          color: AppTheme.primaryDark,
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textDark,
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // EMPTY STATE
  // ------------------------------------------------------------

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 70,
              color: AppTheme.textGrey,
            ),

            const SizedBox(height: 16),

            Text(
              'No registrations yet',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'People who register for this event '
              'will appear here.',
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
}