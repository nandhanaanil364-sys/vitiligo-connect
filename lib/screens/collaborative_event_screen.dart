import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class CollaborativeEventScreen extends StatefulWidget {
  const CollaborativeEventScreen({super.key});

  @override
  State<CollaborativeEventScreen> createState() =>
      _CollaborativeEventScreenState();
}

class _CollaborativeEventScreenState
    extends State<CollaborativeEventScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final _formKey = GlobalKey<FormState>();

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final venueController = TextEditingController();
  final meetingLinkController = TextEditingController();
  final maxSeatsController = TextEditingController();
  final contactController = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  String selectedEventType = 'Awareness';
  String selectedMode = 'Online';

  String? selectedExpertId;
  String? selectedExpertName;

  bool isSubmitting = false;

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    venueController.dispose();
    meetingLinkController.dispose();
    maxSeatsController.dispose();
    contactController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  Future<void> _submitEvent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedExpertId == null) {
      _showMessage('Please select an approved expert.');
      return;
    }

    if (selectedDate == null) {
      _showMessage('Please select an event date.');
      return;
    }

    if (selectedTime == null) {
      _showMessage('Please select an event time.');
      return;
    }

    if (selectedMode == 'Offline' &&
        venueController.text.trim().isEmpty) {
      _showMessage('Please enter the venue.');
      return;
    }

    if (selectedMode == 'Online' &&
        meetingLinkController.text.trim().isEmpty) {
      _showMessage('Please enter the meeting link.');
      return;
    }

    final user = _auth.currentUser;

    if (user == null) {
      _showMessage('Please login again.');
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final collaboratorDoc = await _firestore
          .collection('collaboratorApplications')
          .doc(user.uid)
          .get();

      if (!collaboratorDoc.exists ||
          collaboratorDoc.data()?['status'] != 'approved') {
        _showMessage(
          'You are not an approved Community Collaborator.',
        );

        setState(() {
          isSubmitting = false;
        });

        return;
      }

      final collaboratorData = collaboratorDoc.data() ?? {};

      final eventRef = _firestore.collection('events').doc();

      await eventRef.set({
        'id': eventRef.id,
        'title': titleController.text.trim(),
        'description': descriptionController.text.trim(),
        'eventType': selectedEventType,
        'mode': selectedMode,
        'date': Timestamp.fromDate(selectedDate!),
        'time': selectedTime!.format(context),
        'venue': venueController.text.trim(),
        'meetingLink': meetingLinkController.text.trim(),
        'maxSeats':
            int.tryParse(maxSeatsController.text.trim()) ?? 0,
        'participants': 0,
        'targetAgeGroup': 'All Ages',
        'minAge': 0,
        'maxAge': 100,
        'contact': contactController.text.trim(),

        // Expert selected by collaborator.
        'expertId': selectedExpertId,
        'expertName': selectedExpertName,

        // Community Collaborator details.
        'collaboratorId': user.uid,
        'collaboratorName':
            collaboratorData['name'] ?? 'Community Collaborator',
        'collaboratorEmail': user.email ?? '',

        // Collaboration workflow.
        'eventCreatorType': 'communityCollaborator',
        'collaborationStatus': 'pendingExpert',
        'status': 'pending',

        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Event proposal submitted to the selected expert.',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      _showMessage('Could not submit event: $e');
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Select date';
    }

    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Collaborative Event'),
        backgroundColor: AppTheme.pastelGreen,
        foregroundColor: AppTheme.textDark,
      ),
      body: currentUser == null
          ? const Center(
              child: Text('Please login to continue.'),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('experts')
                  .where('status', isEqualTo: 'approved')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Unable to load approved experts.',
                    ),
                  );
                }

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final experts = snapshot.data?.docs ?? [];

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Community Collaborator Event',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          'Create an event together with an approved expert. '
                          'Your proposal will first be reviewed by the selected expert.',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey,
                          ),
                        ),

                        const SizedBox(height: 24),

                        _buildTextField(
                          controller: titleController,
                          label: 'Event Title',
                          hint:
                              'Example: Living Confidently with Vitiligo',
                          icon: Icons.event_outlined,
                        ),

                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: descriptionController,
                          label: 'Event Description',
                          hint:
                              'Describe what participants can expect',
                          icon: Icons.description_outlined,
                          maxLines: 5,
                        ),

                        const SizedBox(height: 16),

                        DropdownButtonFormField<String>(
                          value: selectedEventType,
                          decoration: _inputDecoration(
                            'Event Type',
                            Icons.category_outlined,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Awareness',
                              child: Text('Awareness'),
                            ),
                            DropdownMenuItem(
                              value: 'Support',
                              child: Text('Support'),
                            ),
                            DropdownMenuItem(
                              value: 'Discussion',
                              child: Text('Discussion'),
                            ),
                            DropdownMenuItem(
                              value: 'Workshop',
                              child: Text('Workshop'),
                            ),
                            DropdownMenuItem(
                              value: 'Community Meet',
                              child: Text('Community Meet'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                selectedEventType = value;
                              });
                            }
                          },
                        ),

                        const SizedBox(height: 16),

                        DropdownButtonFormField<String>(
                          value: selectedMode,
                          decoration: _inputDecoration(
                            'Event Mode',
                            Icons.location_on_outlined,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Online',
                              child: Text('Online'),
                            ),
                            DropdownMenuItem(
                              value: 'Offline',
                              child: Text('Offline'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                selectedMode = value;
                              });
                            }
                          },
                        ),

                        const SizedBox(height: 16),

                        if (selectedMode == 'Offline')
                          _buildTextField(
                            controller: venueController,
                            label: 'Venue',
                            hint: 'Enter event venue',
                            icon: Icons.place_outlined,
                            requiredField: false,
                          ),

                        if (selectedMode == 'Offline')
                          const SizedBox(height: 16),

                        if (selectedMode == 'Online')
                          _buildTextField(
                            controller: meetingLinkController,
                            label: 'Meeting Link',
                            hint:
                                'Enter Google Meet / Zoom link',
                            icon: Icons.video_call_outlined,
                            requiredField: false,
                          ),

                        if (selectedMode == 'Online')
                          const SizedBox(height: 16),

                        const Text(
                          'Date',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark,
                          ),
                        ),

                        const SizedBox(height: 8),

                        InkWell(
                          onTap: _selectDate,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: double.infinity,
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppTheme.pastelGreen,
                              ),
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  color: AppTheme.pastelGreen,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _formatDate(selectedDate),
                                  style: const TextStyle(
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        const Text(
                          'Time',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark,
                          ),
                        ),

                        const SizedBox(height: 8),

                        InkWell(
                          onTap: _selectTime,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: double.infinity,
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppTheme.pastelGreen,
                              ),
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.access_time_outlined,
                                  color: AppTheme.pastelGreen,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  selectedTime == null
                                      ? 'Select time'
                                      : selectedTime!
                                          .format(context),
                                  style: const TextStyle(
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: maxSeatsController,
                          label: 'Maximum Participants',
                          hint: 'Example: 50',
                          icon: Icons.people_outline,
                          keyboardType: TextInputType.number,
                        ),

                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: contactController,
                          label: 'Contact Information',
                          hint:
                              'Email or phone for event queries',
                          icon: Icons.contact_mail_outlined,
                        ),

                        const SizedBox(height: 24),

                        const Text(
                          'Select an Approved Expert',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          'The selected expert will receive this event proposal and can accept or decline the collaboration.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),

                        const SizedBox(height: 14),

                        if (experts.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.pastelYellow
                                  .withValues(alpha: 0.3),
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'No approved experts are currently available.',
                              style: TextStyle(
                                color: AppTheme.textDark,
                              ),
                            ),
                          )
                        else
                          DropdownButtonFormField<String>(
                            value: selectedExpertId,
                            decoration: _inputDecoration(
                              'Choose Expert',
                              Icons.verified_user_outlined,
                            ),
                            validator: (value) {
                              if (value == null ||
                                  value.isEmpty) {
                                return 'Please select an expert';
                              }
                              return null;
                            },
                            items: experts.map((doc) {
                              final data =
                                  doc.data()
                                      as Map<String, dynamic>;

                              final name =
                                  data['name']?.toString() ??
                                      'Expert';

                              return DropdownMenuItem<String>(
                                value: doc.id,
                                child: Text(name),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value == null) return;

                              final selectedDoc = experts.firstWhere(
                                (doc) => doc.id == value,
                              );

                              final data =
                                  selectedDoc.data()
                                      as Map<String, dynamic>;

                              setState(() {
                                selectedExpertId = value;
                                selectedExpertName =
                                    data['name']?.toString() ??
                                        'Expert';
                              });
                            },
                          ),

                        const SizedBox(height: 24),

                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.pastelBlue
                                .withValues(alpha: 0.35),
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                          child: const Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: AppTheme.textDark,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'As a Community Collaborator, you share your lived experience and community perspective. '
                                  'The selected expert provides professional guidance. '
                                  'Collaborators should not diagnose, prescribe, or present themselves as healthcare professionals.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textDark,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed:
                                isSubmitting ? null : _submitEvent,
                            icon: isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.send_outlined,
                                  ),
                            label: Text(
                              isSubmitting
                                  ? 'Submitting...'
                                  : 'Submit Event Proposal',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  AppTheme.pastelGreen,
                              foregroundColor:
                                  AppTheme.textDark,
                              padding:
                                  const EdgeInsets.symmetric(
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  InputDecoration _inputDecoration(
    String label,
    IconData icon,
  ) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppTheme.pastelGreen.withValues(alpha: 0.7),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppTheme.pastelGreen,
          width: 2,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    bool requiredField = true,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: _inputDecoration(label, icon).copyWith(
        hintText: hint,
      ),
      validator: requiredField
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter $label';
              }
              return null;
            }
          : null,
    );
  }
}